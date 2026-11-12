
create table if not exists public.commitments (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category_id text references categories(id),
  kind text not null check (kind in ('financiamento','parcelamento','fixo')),
  match_pattern text,
  monthly_amount numeric,
  installments_paid int, installments_total int,
  end_date date,
  outstanding_balance numeric,
  outstanding_at date,
  source text not null default 'detectado' check (source in ('detectado','manual','hugo')),
  notes text, is_active boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.commitments enable row level security;
create policy cm_read on public.commitments for select to authenticated using (true);
create policy cm_write on public.commitments for all to authenticated using (can_edit()) with check (can_edit());

insert into public.commitments (name, category_id, kind, match_pattern, monthly_amount, installments_paid, installments_total, end_date, source, notes) values
 ('Financiamento imobiliário (Santander)','financiamento_imobiliario','financiamento','operacoes credito imobiliario',7383.49,null,null,null,'detectado','Saldo devedor e prazo: informar pelo contrato'),
 ('Financiamento do carro (Bradesco)','financiamento_bradesco','financiamento',null,4028.99,null,null,'2026-11-30','detectado','Término em 11/2026 (premissa confirmada na v18)'),
 ('Seguro (parcelado)','seguros','parcelamento','mensalidade de seguro',536.19,34,36,'2026-12-31','detectado','Parcela 34/36 em 10/2026'),
 ('Condomínios (PartnerBank)','condominio','fixo','partnerbank',1115.25,null,null,null,'detectado','Apto Cuiabá e casa Chapada');

create or replace view public.v_card_future_installments with (security_invoker = true) as
with last as (
  select distinct on (t.account_id, norm_text(t.description), t.installment_total, abs(t.amount))
    t.account_id, t.description, t.holder_name, t.installment_number as n, t.installment_total as tt, -t.amount as valor, t.bill_closing_date
  from transactions t join accounts a on a.id=t.account_id and a.type='CREDIT'
  where t.installment_total > 1 and not t.is_deleted_at_source
  order by t.account_id, norm_text(t.description), t.installment_total, abs(t.amount), t.installment_number desc)
select l.description, l.holder_name, l.n as parcela_atual, l.tt as total_parcelas, l.valor,
  (date_trunc('month', coalesce(l.bill_closing_date, current_date)) + (k || ' month')::interval)::date as competence_month
from last l, generate_series(1, 36) as k
where l.n < l.tt and k <= l.tt - l.n;

create or replace view public.v_investments_latest with (security_invoker = true) as
select distinct on (provider_investment_id) provider_investment_id, name, type, subtype, balance, amount_invested, due_date, rate, rate_type, observed_at
from investment_positions
where observed_at >= (select max(observed_at) from investment_positions) - interval '1 hour'
order by provider_investment_id, observed_at desc;

create or replace view public.v_net_worth with (security_invoker = true) as
with contas as (select coalesce(sum(balance) filter (where subtype='CHECKING_ACCOUNT'),0) as cc, coalesce(sum(balance) filter (where subtype='SAVINGS_ACCOUNT'),0) as poup from accounts where is_active and type='BANK'),
inv as (select coalesce(sum(balance),0) as v from v_investments_latest),
cartao as (select coalesce(sum(balance),0) as v from accounts where is_active and type='CREDIT'),
div as (select coalesce(sum(outstanding_balance),0) as v, count(*) filter (where kind='financiamento' and outstanding_balance is null) as sem_saldo from commitments where is_active)
select contas.cc as conta_corrente, contas.poup as poupanca, inv.v as investimentos,
  contas.cc + contas.poup + inv.v as ativos_financeiros,
  cartao.v as cartao_utilizado, div.v as financiamentos_saldo, div.sem_saldo as financiamentos_sem_saldo,
  contas.cc + contas.poup + inv.v - cartao.v - div.v as patrimonio_financeiro_liquido,
  (select max(balance_observed_at) from accounts) as atualizado_em
from contas, inv, cartao, div;

create table if not exists public.budgets (
  group_id text not null references categories(id),
  month date not null default '1900-01-01',
  amount numeric not null check (amount >= 0),
  source text not null default 'proposta' check (source in ('proposta','hugo')),
  basis jsonb, updated_at timestamptz not null default now(),
  primary key (group_id, month)
);
alter table public.budgets enable row level security;
create policy bg_read on public.budgets for select to authenticated using (true);
create policy bg_write on public.budgets for all to authenticated using (can_edit()) with check (can_edit());

insert into public.budgets (group_id, amount, source, basis)
select group_id, round(percentile_cont(0.5) within group (order by gasto))::numeric, 'proposta',
  jsonb_build_object('metodo','mediana 6 meses', 'meses', jsonb_agg(jsonb_build_object('mes', mes, 'gasto', round(gasto))))
from (select m.mes, g.group_id, coalesce(-sum(c.total) filter (where c.total<0),0) as gasto
      from (select generate_series('2026-05-01'::date,'2026-10-01','1 month')::date as mes) m
      cross join (select distinct group_id from v_category_month where category_kind='despesa') g
      left join v_category_month c on c.month=m.mes and c.group_id=g.group_id and c.category_kind='despesa'
      group by 1,2) x
group by group_id
on conflict (group_id, month) do nothing;

create or replace view public.v_budget_month with (security_invoker = true) as
with m as (select generate_series('2025-11-01'::date, date_trunc('month', current_date)::date, '1 month')::date as mes),
b as (select distinct on (bm.mes, bu.group_id) bm.mes, bu.group_id, bu.amount, bu.source
      from m bm join budgets bu on bu.month in (bm.mes, '1900-01-01') order by bm.mes, bu.group_id, bu.month desc),
r as (select month as mes, group_id, group_name, -sum(total) as gasto from v_category_month where category_kind='despesa' group by 1,2,3)
select coalesce(b.mes, r.mes) as month, coalesce(b.group_id, r.group_id) as group_id,
  coalesce(r.group_name, c.name) as group_name, coalesce(b.amount,0) as orcado, b.source, coalesce(r.gasto,0) as gasto,
  coalesce(b.amount,0) - coalesce(r.gasto,0) as saldo,
  case when coalesce(b.amount,0) > 0 then round(100*coalesce(r.gasto,0)/b.amount) end as pct
from b full join r on r.mes=b.mes and r.group_id=b.group_id
left join categories c on c.id = coalesce(b.group_id, r.group_id);

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  target_amount numeric not null,
  target_date date,
  progress_source text not null default 'manual' check (progress_source in ('manual','investimentos','poupanca_investimentos')),
  current_amount numeric default 0,
  monthly_contribution numeric,
  status text not null default 'proposta' check (status in ('proposta','ativa','concluida','cancelada')),
  notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.goals enable row level security;
create policy gl_read on public.goals for select to authenticated using (true);
create policy gl_write on public.goals for all to authenticated using (can_edit()) with check (can_edit());

insert into public.goals (name, target_amount, progress_source, status, notes)
select 'Reserva de emergência (6 meses de despesas)', round(6 * percentile_cont(0.5) within group (order by -despesas))::numeric,
  'poupanca_investimentos', 'proposta', 'Proposta: 6× a mediana das despesas mensais mai–out/26. Hugo decide valor e prazo.'
from v_month_summary where month between '2026-05-01' and '2026-10-01';

create or replace view public.v_goals with (security_invoker = true) as
select g.*,
  case g.progress_source when 'manual' then coalesce(g.current_amount,0)
    when 'investimentos' then (select investimentos from v_net_worth)
    else (select poupanca + investimentos from v_net_worth) end as progresso,
  round(100 * case g.progress_source when 'manual' then coalesce(g.current_amount,0)
    when 'investimentos' then (select investimentos from v_net_worth)
    else (select poupanca + investimentos from v_net_worth) end / nullif(g.target_amount,0)) as pct
from goals g where g.status <> 'cancelada';

grant select on public.v_card_future_installments, public.v_investments_latest, public.v_net_worth, public.v_budget_month, public.v_goals to authenticated;

