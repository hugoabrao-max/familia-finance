-- exportação completa (dados + configuração) em JSON, para backup externo
create or replace function export_backup() returns jsonb language plpgsql security definer set search_path = public as $$
declare t text; out jsonb := '{}'::jsonb; part jsonb;
begin
  foreach t in array array['households','household_members','financial_institutions','connections','connection_consents','accounts',
    'account_balance_history','card_statements','raw_transactions','transactions','investment_positions','sync_jobs','sync_errors',
    'categories','classification_rules','classification_feedback','audit_logs','import_jobs','transaction_links','data_quality_issues','project_docs']
  loop
    execute format('select coalesce(jsonb_agg(to_jsonb(x)), ''[]''::jsonb) from %I x', t) into part;
    out := out || jsonb_build_object(t, part);
  end loop;
  -- app_settings sem segredos
  select coalesce(jsonb_agg(to_jsonb(s)), '[]'::jsonb) into part from app_settings s where key not in ('sync_token','backup_token');
  out := out || jsonb_build_object('app_settings', part);
  return jsonb_build_object('schema_version', 8, 'exported_at', now(), 'tables', out);
end $$;
revoke execute on function export_backup() from anon, authenticated;

create table backup_runs (
  id bigserial primary key,
  started_at timestamptz not null default now(),
  status text not null,
  object_key text,
  bytes bigint,
  sha256 text,
  tables jsonb,
  note text
);
alter table backup_runs enable row level security;
create policy br_select on backup_runs for select using (auth.uid() is not null);

insert into app_settings (key, value) values ('backup_token', encode(gen_random_bytes(32), 'hex')) on conflict (key) do nothing;
