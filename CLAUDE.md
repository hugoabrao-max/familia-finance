# Família Finance AI — instruções para o Claude Code

Gestor financeiro da família Abrão. Leia `HANDOFF.md` para o contexto completo (arquitetura, regras de negócio, pendências).

## Regras de trabalho (obrigatórias)

1. **Ler `PROJECT_STATE` (tabela `project_docs` no Supabase) antes de agir** e atualizar `PROJECT_STATE`, `TEST_REPORT` e `CHANGELOG` a cada entrega — no banco **e** em `docs/` deste repositório.
2. **Nunca apagar dados financeiros reais.** Migrações só aditivas, salvo autorização do Hugo. Reclassificação em lote deve ser reversível e registrada em `audit_logs`.
3. Não colar segredos no chat nem no repositório. A publishable key do Supabase no frontend é permitida.
4. Usar `/v2/transactions` da Pluggy (o legado responde 410). **Não forçar refresh na Pluggy.**
5. Distinguir em toda comunicação: **implementado** (código existe) → **testado** (teste automatizado/simulado) → **validado** (conferido com documentos reais) → **publicado** (em produção). Nada é "resolvido" só porque compila.
6. Pedir intervenção do Hugo só para: informação indispensável, decisão financeira pessoal, alteração de acesso a dados ou ação irreversível.
7. Hugo se comunica por voz (mensagens curtas, às vezes fragmentadas) — abrir cada sessão com um resumo curto do estado.
8. Valores em BRL no formato brasileiro; datas no fuso America/Cuiaba (UTC−4).
9. Após deploy: `diff` do código publicado × testado e `/health` com a nova versão.

## Regras financeiras

O contrato de negócio está em `HANDOFF.md` §5 e `docs/FINANCIAL_RULES.md`. **Não alterar sem o Hugo.**

## Onde está cada coisa

| Caminho | Conteúdo | Fonte de verdade em produção |
|---|---|---|
| `app/src/app.ts` | Frontend (Bun, SPA em arquivo único) | Railway serviço `app` (`get-function-source-code`) |
| `railway/*.ts` | Scripts `backup` e `restore-check` | Railway serviços homônimos |
| `supabase/functions/<slug>/` | Edge Functions | Supabase (`get_edge_function`) |
| `supabase/schema/migrations/` | Migrações aplicadas, nomeadas por `version` (a numeração 0006–0010 se repete) | `supabase_migrations.schema_migrations` |
| `supabase/schema/live/` | Definições vivas (views, funções, políticas, triggers, cron, tabelas) | `pg_get_viewdef` / `pg_get_functiondef` etc. — **prevalece sobre as migrações** (ex.: `v_fixed_month` foi reescrita fora de migração) |
| `docs/` | Export dos `project_docs` | tabela `project_docs` |
| `scripts/verify-export.sql` | Consultas de md5 para conferir este repositório contra o banco | — |

## Deploy

- **Frontend:** `update-function-source-code` (MCP Railway) no serviço `app` substitui o arquivo inteiro. Subir `APP_VERSION`, publicar, ler de volta com `get-function-source-code`, `diff` vazio contra `app/src/app.ts`, e `curl https://familia-finance.up.railway.app/health`.
- **Banco:** `apply_migration` (MCP Supabase); depois re-exportar o objeto afetado para `supabase/schema/live/` e a migração para `supabase/schema/migrations/`.
- **Edge Functions:** `deploy_edge_function` mantendo o `verify_jwt` atual (ver `supabase/functions/README.md`).

## Não mexer

Outros projetos na mesma conta Supabase/Railway (`fratello-plataforma`, `fratello-frota`, `capable-*`) não pertencem a este projeto.
