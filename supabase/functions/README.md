# Edge Functions (Supabase, projeto `hrsinekxrfiphlhpoewp`)

Código publicado = esta pasta (conferido em 24/11/2026). Ao republicar com `deploy_edge_function`, manter o `verify_jwt` abaixo.

| slug | versão | verify_jwt | entrypoint | finalidade |
|---|---|---|---|---|
| `pluggy-sync` | 9 (código v1.3.5, 24/11/2026) | false | `index.ts` | Ingestão Pluggy (contas, `/v2/transactions`, faturas, investimentos); protegida por header `x-sync-token` = `app_settings.sync_token` (ou Bearer service role); comparação em tempo constante; não força atualização na Pluggy; tempo limite de 30 s por chamada; job preso em RUNNING além de 20 min vira FAILED |
| `push` | 2 (código v1.1, 24/11/2026) | false | `index.ts` | Notificações no celular (Web Push, VAPID + RFC 8291); `subscribe`/`test`/`unsubscribe` exigem login; `digest` exige `x-sync-token`; só aceita endereços dos serviços de push (Apple, Google, Mozilla, Microsoft) |
| `backup-export` | 3 (código v1.2, 12/11/2026) | false | `index.ts` | Exportação JSON (GET), `/report` e `/restore` (POST); protegida por `x-backup-token` = `app_settings.backup_token`; comparação em tempo constante |
| `member-invite` | 2 (código v2, 24/11/2026) | true | `index.ts` | Responsável (owner/admin) gera link de acesso/redefinição de senha para um membro; admin não gera link para o dono nem para outro admin |

Apagadas pelo Hugo no painel do Supabase em 12/11/2026: `app`, `pluggy-diag`, `owner-recovery` (código no histórico do git).
