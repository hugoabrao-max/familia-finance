
-- Itens do gasto do dia a dia (sem despesas fixas cadastradas e sem parcelas de compras anteriores), por recebedor
create or replace view public.v_meta_items with (security_invoker=on) as
with per as (
  select (date_trunc('month',current_date)-interval '6 months')::date as ini, date_trunc('month',current_date)::date as atual
), fe as materialized (select category_id, payee_key, match_pattern from fixed_expenses where is_active),
tx as materialized (
  select t.month, t.group_id, t.category_name, a.type as acc_type, -t.amount as v,
    (t.account_subtype='CREDIT_CARD' and coalesce(t.installment_number,1)>=2) as parc,
    coalesce(t.installment_total,1)>1 as parcelado,
    payee_key_of(t.counterpart_name,t.description) as pk,
    norm_text(coalesce(t.counterpart_name,'')||' '||t.description) as nt,
    initcap(trim(regexp_replace(regexp_replace(coalesce(nullif(t.counterpart_name,''), left(t.description,30)),'(parc\s*)?[0-9/*]+',' ','gi'),'\s+',' ','g'))) as payee
  from v_tx t join accounts a on a.id=t.account_id, per
  where t.amount<0 and t.category_kind='despesa' and t.month between per.ini and per.atual
), cls as materialized (
  select tx.* from tx where not tx.parc and not exists (select 1 from fe where (fe.payee_key is not null and fe.payee_key=tx.pk)
      or (fe.match_pattern is not null and tx.nt like '%'||fe.match_pattern||'%')
      or (fe.payee_key is null and fe.match_pattern is null and fe.category_id=(select category_id from v_tx where false)))
)
select c.group_id, c.pk as payee_key, max(c.payee) as payee, max(c.category_name) as category_name,
  case when bool_and(c.acc_type='CREDIT') then 'cartao' when bool_and(c.acc_type='BANK') then 'conta' else 'ambos' end as canal,
  count(distinct c.month) filter (where c.month<per.atual) as meses,
  count(*) filter (where c.month<per.atual) as n,
  round(coalesce(sum(c.v) filter (where c.month<per.atual),0),2) as total_6m,
  round(coalesce(sum(c.v) filter (where c.month<per.atual),0)/6,2) as media_6m,
  round(coalesce(sum(c.v) filter (where c.month=per.atual),0),2) as mes_atual,
  bool_or(c.parcelado) as tem_parcelado
from cls c, per
group by c.group_id, c.pk;

