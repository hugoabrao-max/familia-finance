
-- Base da meta mensal: gasto histórico por grupo separado em fixo (cadastro), parcelas de compras anteriores (n>=2) e variável (resto)
create or replace view public.v_meta_base with (security_invoker=on) as
with per as (
  select (date_trunc('month',current_date)-interval '6 months')::date as ini, (date_trunc('month',current_date)-interval '1 month')::date as fim
), meses as (
  select generate_series(per.ini, per.fim, interval '1 month')::date as mes from per
), fe as materialized (
  select id, category_id, payee_key, match_pattern from fixed_expenses where is_active
), tx as materialized (
  select t.month, t.group_id, t.category_id, -t.amount as v,
    (t.account_subtype='CREDIT_CARD' and coalesce(t.installment_number,1)>=2) as parc,
    payee_key_of(t.counterpart_name,t.description) as pk,
    norm_text(coalesce(t.counterpart_name,'')||' '||t.description) as nt
  from v_tx t, per where t.amount<0 and t.category_kind='despesa' and t.month between per.ini and per.fim
), cls as materialized (
  select tx.*, exists (select 1 from fe where (fe.payee_key is not null and fe.payee_key=tx.pk)
      or (fe.match_pattern is not null and tx.nt like '%'||fe.match_pattern||'%')
      or (fe.payee_key is null and fe.match_pattern is null and fe.category_id=tx.category_id)) as fixo
  from tx
), grupos as (select distinct group_id from cls),
mm as (
  select m.mes, g.group_id,
    coalesce(sum(c.v) filter (where not c.fixo and not c.parc),0) as variavel,
    coalesce(sum(c.v) filter (where c.fixo),0) as fixo,
    coalesce(sum(c.v) filter (where c.parc and not c.fixo),0) as parcelas
  from meses m cross join grupos g left join cls c on c.month=m.mes and c.group_id=g.group_id
  group by m.mes, g.group_id
)
select mm.group_id, cat.name as nome,
  round(percentile_cont(0.5) within group (order by mm.variavel)::numeric,2) as variavel_mediana,
  round(avg(mm.variavel),2) as variavel_media,
  round(avg(mm.fixo),2) as fixo_media, round(avg(mm.parcelas),2) as parcelas_media,
  jsonb_object_agg(to_char(mm.mes,'YYYY-MM'), round(mm.variavel)) as variavel_por_mes
from mm left join categories cat on cat.id=mm.group_id
group by mm.group_id, cat.name;

