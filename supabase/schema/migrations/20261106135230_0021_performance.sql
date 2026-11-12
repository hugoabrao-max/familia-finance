
alter policy tx_select on transactions using (exists (select 1 from accounts a join connections c on c.id=a.connection_id where a.id=transactions.account_id and c.household_id=(select my_household())));
alter policy acc_select on accounts using (exists (select 1 from connections c where c.id=accounts.connection_id and c.household_id=(select my_household())));
alter policy conn_select on connections using (household_id=(select my_household()));
alter policy abh_select on account_balance_history using (exists (select 1 from accounts a join connections c on c.id=a.connection_id where a.id=account_balance_history.account_id and c.household_id=(select my_household())));
alter policy cs_select on card_statements using (exists (select 1 from accounts a join connections c on c.id=a.connection_id where a.id=card_statements.account_id and c.household_id=(select my_household())));
alter policy cc_select on connection_consents using (exists (select 1 from connections c where c.id=connection_consents.connection_id and c.household_id=(select my_household())));
alter policy ip_select on investment_positions using (exists (select 1 from connections c where c.id=investment_positions.connection_id and c.household_id=(select my_household())));
alter policy rt_select on raw_transactions using (exists (select 1 from accounts a join connections c on c.id=a.connection_id where a.id=raw_transactions.account_id and c.household_id=(select my_household())));
alter policy hm_select on household_members using (household_id=(select my_household()));
alter policy hh_select on households using (id=(select my_household()));
alter policy cat_select on categories using ((select auth.uid()) is not null);
alter policy cr_select on classification_rules using ((select auth.uid()) is not null);

create or replace view public.v_fixed_month with (security_invoker=on) as
with meses as (
  select generate_series(date_trunc('month',current_date)-interval '6 months', date_trunc('month',current_date)+interval '12 months', interval '1 month')::date as mes
), tx as (
  select t.month, t.category_id, payee_key_of(t.counterpart_name,t.description) as pk,
         norm_text(coalesce(t.counterpart_name,'')||' '||t.description) as nt, -t.amount as v
  from v_tx t
  where t.amount<0 and t.category_kind='despesa' and t.month>=(date_trunc('month',current_date)-interval '6 months')::date
), base as (
  select m.mes, f.id, f.name, f.category_id, f.channel, f.payee_key, f.match_pattern
  from meses m join fixed_expenses f on f.is_active and m.mes>=date_trunc('month',f.start_month) and (f.end_month is null or m.mes<=date_trunc('month',f.end_month))
), pagos as (
  select b.mes, b.id, sum(t.v) as pago
  from base b join tx t on t.month=b.mes and (
       (b.payee_key is not null and t.pk=b.payee_key)
    or (b.match_pattern is not null and t.nt like '%'||b.match_pattern||'%')
    or (b.payee_key is null and b.match_pattern is null and t.category_id=b.category_id))
  group by b.mes, b.id
)
select b.mes as month, b.id as fixed_expense_id, b.name, b.category_id, coalesce(c.parent_id,c.id) as group_id, b.channel,
  dv.amount as devido, coalesce(p.pago,0) as pago
from base b
left join categories c on c.id=b.category_id
left join pagos p on p.mes=b.mes and p.id=b.id
left join lateral (select v.amount from fixed_expense_values v where v.fixed_expense_id=b.id and v.valid_from<=b.mes order by v.valid_from desc limit 1) dv on true;

create or replace view public.v_fixed_expenses with (security_invoker=on) as
with fm as (
  select fixed_expense_id,
    max(pago) filter (where month=date_trunc('month',current_date)::date) as pago_mes,
    max(pago) filter (where month=(date_trunc('month',current_date)-interval '1 month')::date) as pago_mes_anterior
  from v_fixed_month where month between (date_trunc('month',current_date)-interval '1 month')::date and date_trunc('month',current_date)::date
  group by fixed_expense_id
), vals as (
  select fixed_expense_id,
    ((array_agg(amount order by valid_from desc) filter (where valid_from<=date_trunc('month',current_date)))[1])::numeric(14,2) as valor_atual,
    max(valid_from) filter (where valid_from<=date_trunc('month',current_date)) as valor_desde,
    ((array_agg(amount order by valid_from) filter (where valid_from>date_trunc('month',current_date)))[1])::numeric(14,2) as proximo_valor,
    min(valid_from) filter (where valid_from>date_trunc('month',current_date)) as proximo_desde,
    count(*) as n_valores
  from fixed_expense_values group by fixed_expense_id
)
select f.*, coalesce(c.parent_id,c.id) as group_id, c.name as category_name, g.name as group_name,
  vals.valor_atual, vals.valor_desde, vals.proximo_valor, vals.proximo_desde, coalesce(vals.n_valores,0) as n_valores,
  fm.pago_mes, fm.pago_mes_anterior
from fixed_expenses f
left join categories c on c.id=f.category_id left join categories g on g.id=coalesce(c.parent_id,c.id)
left join vals on vals.fixed_expense_id=f.id left join fm on fm.fixed_expense_id=f.id;

