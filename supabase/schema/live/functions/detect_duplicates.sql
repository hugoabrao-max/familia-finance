CREATE OR REPLACE FUNCTION public.detect_duplicates()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;
