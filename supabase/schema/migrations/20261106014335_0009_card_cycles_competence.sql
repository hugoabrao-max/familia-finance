
create table if not exists public.card_bill_cycles (
  account_id uuid not null references public.accounts(id),
  closing_date date not null,
  due_date date,
  source text not null check (source in ('pdf','pluggy_parcelas','estimado')),
  superseded boolean not null default false,
  pdf_total numeric,
  paid_amount numeric,
  paid_transaction_id uuid,
  updated_at timestamptz not null default now(),
  primary key (account_id, closing_date)
);
alter table public.card_bill_cycles enable row level security;
create policy cbc_read on public.card_bill_cycles for select to authenticated using (true);

create table if not exists public.card_holders (
  card_last4 text primary key,
  holder_name text not null,
  kind text
);
alter table public.card_holders enable row level security;
create policy ch_read on public.card_holders for select to authenticated using (true);
insert into public.card_holders values
 ('5430','Hugo','titular'),('8305','Hugo','adicional'),('7297','Juliana','adicional'),('3738','Juliana','adicional/virtual')
on conflict (card_last4) do nothing;

insert into public.card_bill_cycles (account_id, closing_date, due_date, source, pdf_total)
select a.id, v.c, v.d, 'pdf', v.t from accounts a,
 (values ('2025-12-29'::date,'2026-01-06'::date,28654.10),('2026-01-30','2026-02-06',32398.82),('2026-02-27','2026-03-06',26782.93),
         ('2026-03-27','2026-04-06',30316.46),('2026-04-28','2026-05-06',33184.82),('2026-05-29','2026-06-06',33195.55),
         ('2026-06-29','2026-07-06',31684.07),('2026-07-30','2026-08-06',34318.41),('2026-08-31','2026-09-06',45568.01),
         ('2026-09-29','2026-10-06',57920.91)) v(c,d,t)
where a.type='CREDIT' and a.number='5430'
on conflict (account_id, closing_date) do nothing;

create or replace function public.refresh_card_cycles() returns jsonb
language plpgsql security definer set search_path to 'public' as $$
declare n_new int := 0; n_paid int := 0; n_tmp int; r record; est date; c date;
begin
  for r in select id from accounts where type='CREDIT' and is_active loop
    with d as (
      select date_trunc('month', event_date)::date m, event_date, count(*) n,
             row_number() over (partition by date_trunc('month', event_date) order by count(*) desc, event_date desc) rn
      from transactions where account_id=r.id and coalesce(installment_number,1)>=2 and not is_deleted_at_source
      group by 1,2
    ), ins as (
      insert into card_bill_cycles (account_id, closing_date, source)
      select r.id, d.event_date, 'pluggy_parcelas' from d
      where rn=1 and n>=2
        and not exists (select 1 from card_bill_cycles x where x.account_id=r.id and date_trunc('month',x.closing_date)=d.m and x.source in ('pdf','pluggy_parcelas'))
      on conflict do nothing returning 1)
    select count(*) into n_tmp from ins;
    n_new := n_new + n_tmp;
    update card_bill_cycles e set superseded = true, updated_at = now()
      where e.account_id=r.id and e.source='estimado' and not e.superseded
      and exists (select 1 from card_bill_cycles x where x.account_id=r.id and x.source<>'estimado' and date_trunc('month',x.closing_date)=date_trunc('month',e.closing_date));
    for est in select (date_trunc('month', current_date) + (k||' month')::interval)::date from generate_series(0,1) k loop
      c := least(est + 28, (est + interval '1 month' - interval '1 day')::date);
      while extract(isodow from c) > 5 loop c := c - 1; end loop;
      insert into card_bill_cycles (account_id, closing_date, source)
      select r.id, c, 'estimado'
      where not exists (select 1 from card_bill_cycles x where x.account_id=r.id and date_trunc('month',x.closing_date)=est)
      on conflict do nothing;
    end loop;
    update card_bill_cycles set due_date = (date_trunc('month', closing_date) + interval '1 month')::date + 5
      where account_id=r.id and due_date is null;
    with p as (
      select x.closing_date, t.id tx, -t.amount v,
        row_number() over (partition by x.closing_date order by abs(t.event_date - x.due_date)) rn
      from card_bill_cycles x join transactions t on t.category_id='pagamento_cartao' and t.amount<0
       and t.event_date between x.closing_date + 3 and x.closing_date + 15
      join accounts a on a.id=t.account_id and a.type='BANK'
      where x.account_id=r.id and not x.superseded)
    update card_bill_cycles x set paid_amount=p.v, paid_transaction_id=p.tx, updated_at=now()
      from p where x.account_id=r.id and x.closing_date=p.closing_date and p.rn=1
       and x.paid_transaction_id is distinct from p.tx;
    get diagnostics n_tmp = row_count;
    n_paid := n_paid + n_tmp;
  end loop;
  return jsonb_build_object('novos_fechamentos', n_new, 'pagamentos_vinculados', n_paid);
end $$;

create or replace function public.assign_card_competence() returns int
language plpgsql security definer set search_path to 'public' as $$
declare n int;
begin
  with x as (
    select t.id,
      coalesce(t.installment_number,1) inst,
      coalesce((r.payload->'creditCardMetadata'->>'billPostDate')::date, t.event_date) pd,
      r.payload->'creditCardMetadata'->>'cardNumber' card,
      nullif(r.payload->'creditCardMetadata'->>'billForecastDate','0001-01') bf,
      t.account_id
    from transactions t join accounts a on a.id=t.account_id and a.type='CREDIT'
    left join raw_transactions r on r.id=t.raw_transaction_id
  ), y as (
    select x.*, (select min(cc.closing_date) from card_bill_cycles cc where cc.account_id=x.account_id and not cc.superseded
                  and ((x.inst>=2 and cc.closing_date>x.pd) or (x.inst<2 and cc.closing_date>=x.pd))) fech,
           (select h.holder_name from card_holders h where h.card_last4=x.card) holder
    from x)
  update transactions t set
    bill_closing_date = y.fech,
    competence_month = date_trunc('month', coalesce(y.fech, y.pd))::date,
    bill_forecast_date = case when y.bf ~ '^\d{4}-\d{2}$' then (y.bf||'-01')::date else t.bill_forecast_date end,
    card_last4 = coalesce(y.card, t.card_last4),
    holder_name = coalesce(y.holder, t.holder_name)
  from y where t.id=y.id and (
    t.bill_closing_date is distinct from y.fech
    or t.competence_month is distinct from date_trunc('month', coalesce(y.fech, y.pd))::date
    or t.card_last4 is distinct from coalesce(y.card, t.card_last4)
    or t.holder_name is distinct from coalesce(y.holder, t.holder_name));
  get diagnostics n = row_count;
  return n;
end $$;

create or replace view public.v_card_bills with (security_invoker = true) as
select c.account_id, c.closing_date, c.due_date, c.source,
  date_trunc('month', c.closing_date)::date competence_month,
  coalesce((select -sum(t.amount) from transactions t where t.account_id=c.account_id and t.bill_closing_date=c.closing_date
            and not t.is_deleted_at_source and t.reconciliation is distinct from 'duplicate_suspect'),0) total_lancamentos,
  (select count(*) from transactions t where t.account_id=c.account_id and t.bill_closing_date=c.closing_date and not t.is_deleted_at_source) n_lancamentos,
  c.pdf_total, c.paid_amount, c.paid_transaction_id,
  case when c.paid_transaction_id is not null then 'paga'
       when c.closing_date < current_date then 'fechada'
       else 'aberta' end status
from card_bill_cycles c where not c.superseded;

create or replace function public.post_sync() returns void
language plpgsql security definer set search_path to 'public' as $$
begin
  perform refresh_card_cycles();
  perform assign_card_competence();
  perform classify_transactions(true);
  perform reconcile_all();
  perform detect_duplicates();
end $$;

