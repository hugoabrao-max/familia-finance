create table if not exists backup_ids_20261106 as
select 'transactions'::text tbl, t.id, t.source_ref ref, t.account_id from transactions t
union all select 'raw_transactions', r.id, r.provider_tx_id, r.account_id from raw_transactions r
union all select 'accounts', a.id, a.provider_account_id, a.connection_id from accounts a;
alter table backup_ids_20261106 enable row level security;
