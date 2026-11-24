#!/usr/bin/env bash
# Teste da cadeia pós-sincronização (post_sync) num Postgres local, sem tocar em produção.
# Confere: duas compras iguais no mesmo dia NÃO viram duplicidade; transferência entre contas próprias é casada e
# continua transferência depois de nova classificação; lançamento de mês fechado não é reclassificado;
# toda mudança de categoria em lote fica em audit_logs; resultado do mês não fica vazio.
# Uso: bash tests/db/calculo.sh   (requer Postgres 16 local). Sai com 1 se algo falhar.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DB=ff_calc_test
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"; su postgres -c "dropdb --if-exists $DB" >/dev/null 2>&1 || true' EXIT
{
  cat "$ROOT/install/stubs_local.sql"
  grep -v "create extension if not exists pg_cron\|create extension if not exists pg_net" "$ROOT/install/01_schema.sql"
  sed -e 's/{{FAMILIA}}/Familia Teste/g;s/{{TITULAR_NOME}}/Teste/g;s/{{TITULAR_EMAIL}}/teste@exemplo.com/g;s/{{TITULAR_EXTRATO}}/teste da silva/g' "$ROOT/install/02_seed.sql"
  cat <<'SQL'
insert into connections(id, household_id, provider_item_id) select 'c0000000-0000-0000-0000-000000000001', id, 'item-teste' from households limit 1;
insert into accounts(id, connection_id, provider_account_id, type, subtype, name) values
 ('a0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','acc-cc','BANK','CHECKING_ACCOUNT','Conta'),
 ('a0000000-0000-0000-0000-000000000002','c0000000-0000-0000-0000-000000000001','acc-pp','BANK','SAVINGS_ACCOUNT','Poupança');
-- duas compras iguais no mesmo dia (cada uma com seu id na Pluggy)
insert into transactions(id, account_id, source, source_ref, provider_code, event_date, amount, description) values
 ('f0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','pluggy','p1','p1','2026-10-10',-50,'PADARIA DO ZE'),
 ('f0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000001','pluggy','p2','p2','2026-10-10',-50,'PADARIA DO ZE');
-- transferência entre contas próprias
insert into transactions(id, account_id, source, source_ref, provider_code, event_date, amount, description) values
 ('f0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000001','pluggy','p3','p3','2026-10-12',-1000,'PIX ENVIADO FULANO'),
 ('f0000000-0000-0000-0000-000000000004','a0000000-0000-0000-0000-000000000002','pluggy','p4','p4','2026-10-12',1000,'PIX RECEBIDO FULANO');
-- a mesma compra vinda de outra origem (PDF) = duplicidade de verdade
insert into transactions(id, account_id, source, source_ref, event_date, amount, description, created_at) values
 ('f0000000-0000-0000-0000-000000000005','a0000000-0000-0000-0000-000000000001','pdf','x5','2026-10-10',-50,'PADARIA DO ZE', now() + interval '1 minute');
-- mês fechado (setembro) com lançamento sem categoria
insert into transactions(id, account_id, source, source_ref, provider_code, event_date, amount, description) values
 ('f0000000-0000-0000-0000-000000000006','a0000000-0000-0000-0000-000000000001','pluggy','p6','p6','2026-09-05',-30,'TARIFA PACOTE');
insert into monthly_closings(month, status, snapshot, checklist) values ('2026-09-01','fechado','{}','{}');
select post_sync();
select post_sync();  -- segunda rodada: nada pode desfazer a transferência
\echo ---
select 'FALHA compras iguais viraram duplicidade' where exists (select 1 from transactions where id in ('f0000000-0000-0000-0000-000000000001','f0000000-0000-0000-0000-000000000002') and reconciliation = 'duplicate_suspect')
   or exists (select 1 from data_quality_issues where kind = 'duplicate_suspect' and transaction_id in ('f0000000-0000-0000-0000-000000000001','f0000000-0000-0000-0000-000000000002'));
select 'FALHA duplicidade entre origens não foi marcada' where not exists (select 1 from transactions where id = 'f0000000-0000-0000-0000-000000000005' and reconciliation = 'duplicate_suspect');
select 'FALHA transferência não ficou casada: ' || coalesce(category_id,'(vazio)') || ' / ' || coalesce(reconciliation,'-') from transactions where id in ('f0000000-0000-0000-0000-000000000003','f0000000-0000-0000-0000-000000000004') and (category_id is distinct from 'transferencia_entre_contas' or reconciliation is distinct from 'transfer_matched');
select 'FALHA lançamento de mês fechado foi reclassificado' from transactions where id = 'f0000000-0000-0000-0000-000000000006' and category_id is not null;
select 'FALHA mudança de categoria sem registro: ' || t.id from transactions t where t.category_id is not null and t.category_source <> 'ajuste_usuario'
  and not exists (select 1 from audit_logs a where a.row_id = t.id::text and a.table_name = 'transactions');
select 'FALHA resultado do mês vazio' from v_month_summary where resultado is null;
select 'OK ' || (select count(*) from audit_logs where table_name='transactions') || ' registros em audit_logs; compras iguais mantidas; transferência casada; mês fechado intacto';
SQL
} > "$TMP/t.sql"
chmod 755 "$TMP"; chmod 644 "$TMP/t.sql"
su postgres -c "dropdb --if-exists $DB; createdb $DB" >/dev/null 2>&1
OUT="$(su postgres -c "psql -v ON_ERROR_STOP=1 -qtA -d $DB -f $TMP/t.sql" 2>&1 | tee "$TMP/raw.txt" | grep -v '^NOTICE\|^$' | sed -n '/^---$/,$p' | tail -n +2)"
grep -m3 "ERROR\|ERRO" "$TMP/raw.txt" || true
echo "$OUT"
if echo "$OUT" | grep -q '^FALHA' || ! echo "$OUT" | grep -q '^OK '; then echo "RESULTADO: HÁ FALHAS"; exit 1; fi
echo "RESULTADO: TUDO OK"
