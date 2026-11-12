#!/usr/bin/env bash
# Lado local da conferência: imprime "arquivo md5" para comparar com scripts/verify-export.sql.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "== migrations"; (cd supabase/schema/migrations && md5sum *.sql | awk '{print $2, $1}')
echo "== docs";       (cd docs && md5sum *.md | awk '{print $2, $1}')
echo "== app";        sha256sum app/src/app.ts railway/*.ts
