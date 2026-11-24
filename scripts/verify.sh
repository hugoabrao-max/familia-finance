#!/usr/bin/env bash
# Lado local da conferência: imprime "arquivo md5" no mesmo formato de scripts/verify-export.sql.
# Uso: bash scripts/verify.sh > local.txt; rode verify-export.sql no Supabase; compare as duas listas (diff).
set -euo pipefail
cd "$(dirname "$0")/.."
L=supabase/schema/live
{
  for f in $L/views/*.sql; do echo "views/$(basename "$f") $(md5sum < "$f" | cut -c1-32)"; done
  for f in $L/functions/*.sql; do n=$(basename "$f"); [ "$n" = fmt_br.sql ] && continue; echo "functions/$n $(md5sum < "$f" | cut -c1-32)"; done
  echo "policies.sql $(md5sum < $L/policies.sql | cut -c1-32)"
  for f in docs/*.md; do echo "docs/$(basename "$f") $(md5sum < "$f" | cut -c1-32)"; done
} | sort
