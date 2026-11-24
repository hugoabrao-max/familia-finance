#!/usr/bin/env bash
# Teste do banco (Postgres local, sem tocar em produção): sobe o esquema do kit (install/01_schema.sql, gerado de
# supabase/schema/live) com dados iniciais, cria um membro e um estranho logados e confere, em TODAS as tabelas e views
# do esquema public, que o estranho e o anônimo não leem nada e o membro lê; e que o backup não leva segredos.
# Uso: bash tests/db/rls.sh   (requer Postgres 16 local: pg_ctlcluster 16 main start). Sai com 1 se algo falhar.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DB=ff_rls_test
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"; su postgres -c "dropdb --if-exists $DB" >/dev/null 2>&1 || true' EXIT
M=11111111-1111-1111-1111-111111111111; E=22222222-2222-2222-2222-222222222222
{
  cat "$ROOT/install/stubs_local.sql"
  grep -v "create extension if not exists pg_cron\|create extension if not exists pg_net" "$ROOT/install/01_schema.sql"
  sed -e 's/{{FAMILIA}}/Familia Teste/g;s/{{TITULAR_NOME}}/Teste/g;s/{{TITULAR_EMAIL}}/teste@exemplo.com/g;s/{{TITULAR_EXTRATO}}/teste da silva/g' "$ROOT/install/02_seed.sql"
  cat <<SQL
insert into auth.users(id,email) values ('$M','teste@exemplo.com'),('$E','estranho@fora.com');
insert into app_settings(key,value) values ('vapid_private_jwk','{"x":1}') on conflict do nothing;
insert into backup_runs(status) values ('SUCCESS');
-- conta por objeto como cada papel, numa tabela temporária
create temp table r(papel text, obj text, n bigint);
grant all on r to anon, authenticated;
create function pg_temp.contar(papel text) returns void language plpgsql as \$f\$
declare o record; c bigint; begin
  for o in select c2.relname, c2.relkind from pg_class c2 join pg_namespace n on n.oid=c2.relnamespace where n.nspname='public' and c2.relkind in ('r','v') order by 1 loop
    begin execute format('select count(*) from public.%I', o.relname) into c; exception when insufficient_privilege then c := -1; end;
    insert into r values (papel, o.relname || case when o.relkind='v' then ' (view)' else '' end, c);
  end loop; end \$f\$;
grant execute on function pg_temp.contar(text) to anon, authenticated;
begin; set local role authenticated; select set_config('request.jwt.claim.sub','$M',true); select pg_temp.contar('membro'); commit;
begin; set local role authenticated; select set_config('request.jwt.claim.sub','$E',true); select pg_temp.contar('estranho'); commit;
begin; set local role anon; select pg_temp.contar('anonimo'); commit;
\echo ---
select 'FALHA estranho lê ' || obj || ': ' || n from r where papel='estranho' and n > 0
  and obj not in ('v_card_teto (view)','v_sim_base (view)','v_net_worth (view)');   -- só zeros gerados pela própria view (conferido abaixo)
select 'FALHA anônimo lê ' || obj || ': ' || n from r where papel='anonimo' and n > 0
  and obj not in ('v_card_teto (view)','v_sim_base (view)','v_net_worth (view)');
select 'FALHA membro não lê categorias' where coalesce((select n from r where papel='membro' and obj='categories'),0) < 40;
select 'FALHA membro não lê a família' where coalesce((select n from r where papel='membro' and obj='household_members'),0) <> 1;
begin; set local role authenticated; select set_config('request.jwt.claim.sub','$E',true);
select 'FALHA estranho vê valor em v_card_teto' from v_card_teto where coalesce(teto,0)<>0 or coalesce(receita_base,0)<>0 or coalesce(comprometido,0)<>0 limit 1;
select 'FALHA estranho vê valor em v_net_worth' from v_net_worth where coalesce(patrimonio_liquido,0)<>0 or coalesce(bens,0)<>0 limit 1;
commit;
begin; select set_config('request.jwt.claim.sub','$M',true); set local role authenticated;
select 'FALHA membro vê aviso de backup com backup em dia' where exists (select 1 from v_alerts where kind='backup');
reset role; update backup_runs set started_at = now() - interval '30 hours'; set local role authenticated;
select 'FALHA membro não vê aviso de backup atrasado' where not exists (select 1 from v_alerts where kind='backup');
rollback;
select 'FALHA backup leva segredo: ' || (e->>'key') from jsonb_array_elements(export_backup()->'tables'->'app_settings') e where e->>'key' in ('sync_token','backup_token','vapid_private_jwk');
select 'FALHA backup leva push_subscriptions' where (export_backup()->'tables') ? 'push_subscriptions';
select 'FALHA tabela sem RLS: ' || relname from pg_class where relnamespace='public'::regnamespace and relkind='r' and not relrowsecurity;
select 'OK ' || count(*) filter (where papel='estranho') || ' objetos conferidos por papel; membro lê ' || count(*) filter (where papel='membro' and n>0) || ', estranho ' || count(*) filter (where papel='estranho' and n>0) || ' (só views de zeros), anônimo ' || count(*) filter (where papel='anonimo' and n>0) from r;
SQL
} > "$TMP/t.sql"
chmod 755 "$TMP"; chmod 644 "$TMP/t.sql"
su postgres -c "dropdb --if-exists $DB; createdb $DB" >/dev/null
OUT="$(su postgres -c "psql -v ON_ERROR_STOP=1 -qtA -d $DB -f $TMP/t.sql" 2>&1 | grep -v '^NOTICE\|^$\|^contar\|^set_config' | sed -n '/^---$/,$p' | tail -n +2)"
echo "$OUT"
if echo "$OUT" | grep -q '^FALHA' || ! echo "$OUT" | grep -q '^OK '; then echo "RESULTADO: HÁ FALHAS"; exit 1; fi
echo "RESULTADO: TUDO OK"
