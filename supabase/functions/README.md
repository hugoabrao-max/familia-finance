# Edge Functions (Supabase, projeto `hrsinekxrfiphlhpoewp`)

Exportado em 12/11/2026 via `get_edge_function` (somente leitura). Ao republicar com `deploy_edge_function`, manter o `verify_jwt` abaixo.

| slug | versão | verify_jwt | status | entrypoint | finalidade |
|---|---|---|---|---|---|
| `pluggy-sync` | 8 (código v1.3.4, 12/11/2026) | false | ACTIVE | `index.ts` | Ingestão Pluggy (contas, `/v2/transactions`, faturas, investimentos); protegida por header `x-sync-token` = `app_settings.sync_token` (ou Bearer service role); sem `?token=` na URL; comparação em tempo constante; não grava `bill_closing_date` (calculado no pos-sync) |
| `backup-export` | 3 (código v1.2, 12/11/2026) | false | ACTIVE | `index.ts` | Exportação JSON (GET), `/report` e `/restore` (POST); protegida por `x-backup-token` = `app_settings.backup_token`; comparação em tempo constante |
| `member-invite` | 1 | true | ACTIVE | `index.ts` | Responsável (owner/admin) gera link de acesso/redefinição de senha para um membro |

Apagadas pelo Hugo no painel do Supabase em 12/11/2026: `app`, `pluggy-diag`, `owner-recovery` (código no histórico do git).
