create or replace function detect_duplicates() returns int language plpgsql security definer set search_path = public as $$
declare n int;
begin
  with dup as (
    select b.id
    from transactions a join transactions b
      on b.account_id = a.account_id and b.event_date = a.event_date and b.amount = a.amount
     and norm_text(b.description) = norm_text(a.description) and b.id <> a.id
     and (a.source <> b.source or a.provider_code is distinct from b.provider_code)
     and (a.created_at, a.id) < (b.created_at, b.id)
  ), ins as (
    insert into data_quality_issues (kind, severity, transaction_id, detail)
    select 'duplicate_suspect', 'high', id, jsonb_build_object('rule','same_account_date_amount_desc') from dup
    on conflict do nothing returning 1
  ) select count(*) into n from ins;
  update transactions t set reconciliation = 'duplicate_suspect' from data_quality_issues q where q.transaction_id = t.id and q.kind = 'duplicate_suspect' and q.status = 'open' and t.reconciliation is distinct from 'duplicate_suspect';
  return n;
end $$;
revoke execute on function detect_duplicates() from anon, authenticated;

create or replace function post_sync() returns void language plpgsql security definer set search_path = public as $$
begin perform classify_transactions(true); perform reconcile_all(); perform detect_duplicates(); end $$;

drop view v_month_summary; drop view v_category_month; drop view v_daily_flow; drop view v_tx;
create view v_tx with (security_invoker = on) as
  select t.*, a.subtype as account_subtype, a.name as account_name, c.name as category_name, c.kind as category_kind,
         coalesce(p.id, c.id) as group_id, coalesce(p.name, c.name) as group_name,
         coalesce(t.competence_month, date_trunc('month', t.event_date)::date) as month
  from transactions t
  join accounts a on a.id = t.account_id
  left join categories c on c.id = t.category_id
  left join categories p on p.id = c.parent_id
  where not t.is_deleted_at_source and t.reconciliation is distinct from 'duplicate_suspect';
create view v_month_summary with (security_invoker = on) as
  select month,
    sum(amount) filter (where category_kind = 'receita') as receitas,
    sum(amount) filter (where category_kind = 'despesa' or category_kind is null) as despesas,
    sum(amount) filter (where category_kind = 'investimento') as investimentos,
    sum(amount) filter (where category_kind = 'receita') + sum(amount) filter (where category_kind = 'despesa' or category_kind is null) as resultado,
    count(*) filter (where review_status = 'pending') as pendentes,
    sum(abs(amount)) filter (where review_status = 'pending') as valor_pendente
  from v_tx where category_kind is distinct from 'transferencia' group by month;
create view v_category_month with (security_invoker = on) as
  select month, group_id, group_name, category_id, category_name, category_kind, count(*) as n, sum(amount) as total
  from v_tx where category_kind is distinct from 'transferencia' group by 1,2,3,4,5,6;
create view v_daily_flow with (security_invoker = on) as
  select event_date, account_subtype,
    sum(amount) filter (where amount > 0 and category_kind is distinct from 'transferencia') as entradas,
    sum(amount) filter (where amount < 0 and category_kind is distinct from 'transferencia') as saidas,
    count(*) as n
  from v_tx group by 1,2;
