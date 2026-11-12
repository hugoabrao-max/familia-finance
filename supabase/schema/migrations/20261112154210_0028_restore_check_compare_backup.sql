-- 0028 (12/11/2026): restore_backup_to_test compara o restaurado com o PRÓPRIO backup (linhas por tabela e
-- soma das transações), em vez da produção ao vivo (que muda a cada sync e gerava falso alarme).
-- Produção segue no relatório só como informação, com um alarme real: produção com MENOS lançamentos que o
-- backup (transactions/raw_transactions) = possível perda de dados (regra 8: nenhum lançamento é apagado).
CREATE OR REPLACE FUNCTION public.restore_backup_to_test(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare t text; tables jsonb := p->'tables'; n_json bigint; n_rest bigint; n_prod bigint; rep jsonb := '{}'::jsonb; ok boolean := true;
        sum_json numeric; sum_rest numeric; sum_prod numeric; falhas text[] := '{}';
begin
  execute 'drop schema if exists restore_test cascade';
  execute 'create schema restore_test';
  for t in select jsonb_object_keys(tables) loop
    execute format('create table restore_test.%I (like public.%I including defaults)', t, t);
    execute format('insert into restore_test.%I select * from jsonb_populate_recordset(null::public.%I, $1)', t, t) using tables->t;
    execute format('select count(*) from restore_test.%I', t) into n_rest;
    n_json := jsonb_array_length(tables->t);
    if t = 'app_settings' then
      select count(*) into n_prod from public.app_settings where key not in ('sync_token','backup_token');
    else
      execute format('select count(*) from public.%I', t) into n_prod;
    end if;
    rep := rep || jsonb_build_object(t, jsonb_build_object('backup', n_json, 'restaurado', n_rest, 'producao', n_prod));
    if n_rest <> n_json then ok := false; falhas := falhas || (t || ': restaurado difere do backup'); end if;
    if t in ('transactions','raw_transactions') and n_prod < n_json then
      ok := false; falhas := falhas || (t || ': produção com menos linhas que o backup');
    end if;
  end loop;
  select coalesce(sum((e->>'amount')::numeric),0) into sum_json from jsonb_array_elements(tables->'transactions') e;
  select coalesce(sum(amount),0) into sum_rest from restore_test.transactions;
  select coalesce(sum(amount),0) into sum_prod from public.transactions;
  rep := rep || jsonb_build_object('soma_transacoes', jsonb_build_object('backup', sum_json, 'restaurado', sum_rest, 'producao', sum_prod));
  if sum_rest <> sum_json then ok := false; falhas := falhas || 'soma das transações restauradas difere do backup'::text; end if;
  insert into backup_runs (status, note, tables)
  values (case when ok then 'RESTORE_TEST_OK' else 'RESTORE_TEST_DIVERGENT' end,
          'v2: restaurado × próprio backup; produção só informativa (alarme se perder lançamentos)'
            || case when ok then '' else ' | ' || array_to_string(falhas, '; ') end, rep);
  execute 'drop schema if exists restore_test cascade';
  return jsonb_build_object('ok', ok, 'exported_at', p->>'exported_at', 'falhas', to_jsonb(falhas), 'detail', rep);
end $function$;

revoke all on function public.restore_backup_to_test(jsonb) from public, anon, authenticated;
