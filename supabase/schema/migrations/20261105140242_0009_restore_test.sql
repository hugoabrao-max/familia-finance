-- restauração de um backup num esquema isolado (restore_test) e comparação com a produção
create or replace function restore_backup_to_test(p jsonb) returns jsonb language plpgsql security definer set search_path = public as $$
declare t text; tables jsonb := p->'tables'; n_rest bigint; n_prod bigint; rep jsonb := '{}'::jsonb; ok boolean := true;
        sum_rest numeric; sum_prod numeric;
begin
  execute 'drop schema if exists restore_test cascade';
  execute 'create schema restore_test';
  for t in select jsonb_object_keys(tables) loop
    execute format('create table restore_test.%I (like public.%I including defaults)', t, t);
    execute format('insert into restore_test.%I select * from jsonb_populate_recordset(null::public.%I, $1)', t, t) using tables->t;
    execute format('select count(*) from restore_test.%I', t) into n_rest;
    execute format('select count(*) from public.%I', t) into n_prod;
    rep := rep || jsonb_build_object(t, jsonb_build_object('backup', n_rest, 'producao', n_prod));
    if t not in ('sync_jobs','sync_errors','backup_runs','audit_logs') and n_rest <> n_prod then ok := false; end if;
  end loop;
  select coalesce(sum(amount),0) into sum_rest from restore_test.transactions;
  select coalesce(sum(amount),0) into sum_prod from public.transactions;
  rep := rep || jsonb_build_object('soma_transacoes', jsonb_build_object('backup', sum_rest, 'producao', sum_prod));
  if sum_rest <> sum_prod then ok := false; end if;
  insert into backup_runs (status, note, tables) values (case when ok then 'RESTORE_TEST_OK' else 'RESTORE_TEST_DIVERGENT' end, 'restauração em restore_test', rep);
  return jsonb_build_object('ok', ok, 'exported_at', p->>'exported_at', 'detail', rep);
end $$;
revoke execute on function restore_backup_to_test(jsonb) from anon, authenticated;
