#!/usr/bin/env bash
# Monta uma cópia LIMPA do Family Finance para outra família, sem nenhum dado da família Abrão.
# Uso: bash install/export_kit.sh <pasta_destino>
# Leva só código e o kit de instalação. Ficam de fora: docs/, HANDOFF.md, migrações antigas (têm dados),
# testes (usam nomes da família), scripts de relatório e qualquer arquivo com dados.
set -euo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
DST="${1:?informe a pasta de destino}"
[ -e "$DST" ] && { echo "A pasta $DST já existe; escolha outra." >&2; exit 1; }
mkdir -p "$DST"/app/src "$DST"/app/assets "$DST"/install "$DST"/supabase/functions "$DST"/railway

cp "$SRC"/app/Dockerfile "$DST"/app/
cp "$SRC"/app/assets/icon.svg "$DST"/app/assets/
# app sem endereço/chave padrão: a instalação nova tem de informar SUPABASE_URL e SUPABASE_ANON_KEY
sed -e 's#Bun.env.SUPABASE_URL || "https://[a-z0-9]*\.supabase\.co"#Bun.env.SUPABASE_URL || ""#' \
    -e 's#Bun.env.SUPABASE_ANON_KEY || "sb_publishable_[A-Za-z0-9_-]*"#Bun.env.SUPABASE_ANON_KEY || ""#' \
    -e 's#o padrão é a instalação da família Abrão\.#sem elas o app não sobe.#' \
    "$SRC"/app/src/app.ts > "$DST"/app/src/app.ts
python3 - "$DST/app/src/app.ts" <<'PY'
import sys; p = sys.argv[1]; s = open(p, encoding='utf-8').read()
anchor = 'Bun.serve({'
guard = 'if (!SUPABASE_URL || !ANON_KEY) { console.error("Faltam as variáveis SUPABASE_URL e SUPABASE_ANON_KEY"); process.exit(1); }\n'
assert s.count(anchor) == 1; open(p, 'w', encoding='utf-8').write(s.replace(anchor, guard + anchor))
PY
cp "$SRC"/install/01_schema.sql "$SRC"/install/02_seed.sql "$SRC"/install/03_cron.sql "$SRC"/install/LEIA-ME.md "$DST"/install/
for f in pluggy-sync member-invite backup-export; do mkdir -p "$DST"/supabase/functions/$f; cp "$SRC"/supabase/functions/$f/index.ts "$DST"/supabase/functions/$f/; done
# member-invite: endereço do app vem do segredo APP_URL da nova instalação
sed -i 's#^const APP_URL = "https://[^"]*";#const APP_URL = (Deno.env.get("APP_URL") ?? "").replace(/\\/+$/, "");\nif (!APP_URL) console.error("Defina o segredo APP_URL com o endereço do app");#' "$DST"/supabase/functions/member-invite/index.ts
grep -q 'Deno.env.get("APP_URL")' "$DST"/supabase/functions/member-invite/index.ts || { echo "ERRO: APP_URL não foi trocado" >&2; exit 3; }
cp "$SRC"/install/CLAUDE-kit.md "$DST"/CLAUDE.md
# chave de serviço: aceita o formato novo (SUPABASE_SECRET_KEYS) quando a antiga (SERVICE_ROLE) não existir
python3 - "$DST"/supabase/functions <<'PY'
import sys, os
d = sys.argv[1]
helper = 'const SVC_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || (() => { try { const k = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") || "{}"); return k.default || Object.values(k)[0] || ""; } catch { return ""; } })();\n'
for f in ("pluggy-sync", "member-invite", "backup-export"):
    p = os.path.join(d, f, "index.ts"); s = open(p, encoding="utf-8").read()
    n = s.count('Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")')
    assert n >= 1, (f, n)
    s = s.replace('Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!', 'SVC_KEY').replace('Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")', 'SVC_KEY')
    i = s.index("\nimport "); j = s.index("\n", s.rindex("\nimport ") + 1) + 1
    s = s[:j] + helper + s[j:]
    open(p, "w", encoding="utf-8").write(s)
PY
cp "$SRC"/railway/backup.ts "$SRC"/railway/restore-check.ts "$DST"/railway/ 2>/dev/null || true
sed -i "s#familia-finance/#family-finance/#g" "$DST"/railway/backup.ts "$DST"/railway/restore-check.ts
cp "$SRC"/install/LEIA-ME.md "$DST"/README.md
printf 'node_modules/\n*.xlsx\n*.pdf\n.env\n' > "$DST"/.gitignore

# conferência: nada pessoal pode sobrar
# 'hugo' é só um rótulo interno de origem (ex.: budgets.source='hugo') e é aceito; qualquer outra ocorrência barra a entrega
if grep -rniE "hrsinek|hugo|juliana|abr[aã]o|edneusa|atmo engenharia|5430|8305|7297|sb_publishable_[A-Za-z0-9]|familia-finance|up\\.railway\\.app|3b1fad88|22255fcb" "$DST" | grep -viE "'hugo'|\"hugo\"|source *= *'hugo'|hugo::text" ; then
  echo "ERRO: sobrou dado pessoal acima. Nada foi entregue." >&2; exit 2
fi
echo "Kit limpo em $DST ($(find "$DST" -type f | wc -l) arquivos)."
