CREATE OR REPLACE FUNCTION public.refresh_card_cycles()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n_new int := 0; n_paid int := 0; n_tmp int; r record; est date; c date;
begin
  for r in select id, number from accounts where type='CREDIT' and is_active loop
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
        row_number() over (partition by x.closing_date order by abs(t.event_date - x.due_date), t.amount) rn
      from card_bill_cycles x join transactions t on t.amount<0
       and t.event_date between x.closing_date + 3 and x.closing_date + 15
       and norm_text(t.description) like '%fatura%' and t.description like '%' || r.number || '%'
      join accounts a on a.id=t.account_id and a.type='BANK'
      where x.account_id=r.id and not x.superseded)
    update card_bill_cycles x set paid_amount=p.v, paid_transaction_id=p.tx, updated_at=now()
      from p where x.account_id=r.id and x.closing_date=p.closing_date and p.rn=1
       and x.paid_transaction_id is distinct from p.tx;
    get diagnostics n_tmp = row_count;
    n_paid := n_paid + n_tmp;
  end loop;
  return jsonb_build_object('novos_fechamentos', n_new, 'pagamentos_vinculados', n_paid);
end $function$
;
