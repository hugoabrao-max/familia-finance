# Edge Functions (Supabase, projeto `hrsinekxrfiphlhpoewp`)

Exportado em 12/11/2026 via `get_edge_function` (somente leitura). Ao republicar com `deploy_edge_function`, manter o `verify_jwt` abaixo.

| slug | versão | verify_jwt | status | entrypoint | finalidade |
|---|---|---|---|---|---|
| `pluggy-sync` | 6 | false | ACTIVE | `index.ts` | Ingestão Pluggy (contas, `/v2/transactions`, faturas, investimentos); protegida por `x-sync-token` = `app_settings.sync_token` (ou Bearer service role) |
| `backup-export` | 2 | false | ACTIVE | `index.ts` | Exportação JSON (GET), `/report` e `/restore` (POST); protegida por `x-backup-token` = `app_settings.backup_token` |
| `member-invite` | 1 | true | ACTIVE | `index.ts` | Responsável (owner/admin) gera link de acesso/redefinição de senha para um membro |
| `owner-recovery` | 2 | true | ACTIVE | `index.ts` | Redefinição de senha avulsa (usada uma vez em 06/11/2026); hoje responde 410 — candidata a remoção |
| `pluggy-diag` | 5 | false | ACTIVE | `index.ts` | Diagnóstico temporário (GET `/items/{id}`, sem refresh) — candidata a remoção, aguardando OK do responsável |
| `app` | 1 | false | ACTIVE | `index.ts` | Tentativa fracassada de servir o HTML pelo Supabase (frontend real está no Railway) — candidata a remoção |
