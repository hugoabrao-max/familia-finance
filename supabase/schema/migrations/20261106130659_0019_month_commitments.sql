
create or replace view public.v_card_future_installments with (security_invoker = true) as
with s as (
  select t.account_id, norm_text(t.description) as chave, t.installment_total as tt,
    max(t.installment_number) as n,
    (array_agg(t.description order by t.installment_number desc))[1] as description,
    (array_agg(t.holder_name order by t.installment_number desc))[1] as holder_name,
    (array_agg(-t.amount order by t.installment_number desc))[1] as valor,
    (array_agg(t.category_id order by t.installment_number desc))[1] as category_id,
    max(t.bill_closing_date) as ult_fechamento
  from transactions t join accounts a on a.id=t.account_id and a.type='CREDIT'
  where t.installment_total > 1 and not t.is_deleted_at_source
  group by 1,2,3)
select s.description, s.holder_name, s.n as parcela_atual, s.tt as total_parcelas, s.valor,
  (date_trunc('month', coalesce(s.ult_fechamento, current_date)) + (g.i || ' month')::interval)::date as competence_month,
  s.category_id, coalesce(c.parent_id, c.id, 'outros') as group_id, s.n + g.i as parcela_no_mes
from s left join categories c on c.id = s.category_id, generate_series(1, 36) as g(i)
where s.n < s.tt and g.i <= s.tt - s.n
  and (date_trunc('month', coalesce(s.ult_fechamento, current_date)) + (g.i || ' month')::interval)::date >= date_trunc('month', current_date)::date;

create or replace view public.v_month_commitments with (security_invoker = true) as
with meses as (select generate_series(date_trunc('month', current_date) - interval '6 month', date_trunc('month', current_date) + interval '12 month', '1 month')::date as mes),
parc_lancadas as (
  select v.month as mes, v.group_id, -sum(v.amount) as v, count(*) as n
  from v_tx v where v.account_subtype='CREDIT_CARD' and coalesce(v.installment_number,1) >= 2 group by 1,2),
parc_futuras as (
  select competence_month as mes, group_id, sum(valor) as v, count(*) as n
  from v_card_future_installments f
  where not exists (select 1 from parc_lancadas p where p.mes = f.competence_month)
  group by 1,2),
parc as (select * from parc_lancadas union all select * from parc_futuras),
comp as (
  select m.mes, coalesce(cat.parent_id, cat.id) as group_id, c.name, c.monthly_amount,
    coalesce((select -sum(t.amount) from v_tx t where t.month = m.mes and t.category_id = c.category_id and t.amount < 0), 0) as pago
  from meses m join commitments c on c.is_active and c.monthly_amount > 0
    and (c.end_date is null or date_trunc('month', c.end_date) >= m.mes)
  left join categories cat on cat.id = c.category_id
  where m.mes >= date_trunc('month', current_date)::date)
select coalesce(p.mes, k.mes) as month, coalesce(p.group_id, k.group_id) as group_id,
  coalesce(p.v, 0) as parcelas_cartao, coalesce(p.n, 0) as n_parcelas,
  coalesce(k.pendente, 0) as compromissos_pendentes, k.nomes
from (select mes, group_id, sum(v) as v, sum(n) as n from parc group by 1,2) p
full join (select mes, group_id, sum(greatest(monthly_amount - pago, 0)) as pendente, string_agg(name, ', ') as nomes from comp group by 1,2) k
  on k.mes = p.mes and k.group_id = p.group_id;

create or replace view public.v_budget_month with (security_invoker = true) as
with m as (select generate_series('2025-11-01'::date, (date_trunc('month', current_date) + interval '12 month')::date, '1 month')::date as mes),
b as (select distinct on (bm.mes, bu.group_id) bm.mes, bu.group_id, bu.amount, bu.source
      from m bm join budgets bu on bu.month in (bm.mes, '1900-01-01') order by bm.mes, bu.group_id, bu.month desc),
r as (select month as mes, group_id, group_name, -sum(total) as gasto from v_category_month where category_kind='despesa' group by 1,2,3)
select coalesce(b.mes, r.mes) as month, coalesce(b.group_id, r.group_id) as group_id,
  coalesce(r.group_name, c.name) as group_name, coalesce(b.amount,0) as orcado, b.source, coalesce(r.gasto,0) as gasto,
  coalesce(b.amount,0) - coalesce(r.gasto,0) as saldo,
  case when coalesce(b.amount,0) > 0 then round(100*coalesce(r.gasto,0)/b.amount) end as pct
from b full join r on r.mes=b.mes and r.group_id=b.group_id
left join categories c on c.id = coalesce(b.group_id, r.group_id);

grant select on public.v_card_future_installments, public.v_month_commitments, public.v_budget_month to authenticated;

