# Família Finance AI — Relatório de handoff para o Claude Code

**Data do levantamento:** 12/11/2026 · **Responsável:** Hugo Veras Abrão (owner) · **Versão em produção:** frontend v0.14.0 / banco migração 0025
**Fonte deste relatório:** estado lido ao vivo no Supabase `familia-finance` e no Railway `familia-finance` em 12/11/2026, mais os 12 documentos de continuidade da tabela `project_docs` e o histórico do projeto.

> Convenção de status usada em todo o documento (exigência do Hugo): **implementado** (código existe) → **testado** (teste automatizado/simulado) → **validado** (conferido com documentos reais) → **publicado** (em produção). Nada é "resolvido" só porque compila.

---

## 1. Resumo executivo

| Item | Situação em 12/11/2026 |
|---|---|
| Objetivo | Gestor financeiro da família Abrão: acompanhar gastos **ao longo do mês** (dia/semana), não só após o fechamento; planejar meta de sobra mensal, orçamento, compromissos e simular cenários |
| Fonte de dados | Open Finance Santander via **Meu Pluggy** (conector MeuPluggy 200) — conta corrente, poupança, cartão Unique Visa Infinite 5430 (+ adicionais), 6 investimentos |
| Backend | Supabase `familia-finance` (ref `hrsinekxrfiphlhpoewp`, sa-east-1, free, Postgres 17) — 42 tabelas, 22 views, RLS em tudo |
| Frontend | Railway Function Bun, arquivo único (`src/app.ts`, 589 linhas / 92 KB) — https://familia-finance.up.railway.app — PWA instalável |
| Sincronização | pg_cron 4×/dia (01:15, 03:15, 10:15, 22:15 UTC) — últimas 5 execuções SUCCESS, 0 erros |
| Backup | Diário 09:00 UTC → bucket S3 Railway, hash conferido por releitura — último SUCCESS 12/11/2026 09:03 UTC (1,42 MB) |
| Dados | 3.550 lançamentos (05/11/2025 → 11/11/2026); 638 regras de classificação; 49 categorias; **11 pendentes de revisão** (7 out/26, 4 nov/26) |
| Usuários | Hugo (owner) e Juliana (member) — ambos vinculados ao Auth |
| Repositório Git | Criado em 12/11/2026 (este repositório) — ver seção 10 |
| Validação pelo Hugo | Pendente — Hugo ainda não confirmou visualmente v0.10–v0.14 |

---

## 2. Histórico do projeto (fases)

| Fase | Período | O que foi | Status |
|---|---|---|---|
| Relatório estático | ago–set/2026 | Análise financeira HTML/PDF a partir de PDFs Santander (wkhtmltopdf) | Encerrado |
| App v17/v18 (artifact claude.ai) | até 06/10/2026 | Importação de PDFs, um doc por PDF (`docs/<sha>`), regras/ajustes/premissas; 15/15 PDFs conciliados em centavos | **Congelado** — link `claude.ai/artifact/37SkCXP9Trf1WSPoHHryBN`; serve de referência de regras e conciliação |
| Família Finance AI | 04/11/2026 → hoje | Open Finance (Pluggy) + Supabase + frontend Railway | **Ativo** |

Decisão de 05/11: o plano original (Next.js no Claude Code + repositório) foi trocado por Railway Function Bun porque o Hugo não conseguia criar repositório/hospedagem sozinho. Edge Functions do Supabase **não servem HTML** (bloqueado no domínio supabase.co) — por isso a função `app` no Supabase é inútil.

---

## 3. Arquitetura

```
Santander ──Open Finance──► Meu Pluggy (item atualiza sozinho ~01:02 UTC)
                                   │  API Pluggy (/items /accounts /v2/transactions /bills /investments)
                                   ▼
pg_cron "pluggy-sync-diario" ──pg_net (x-sync-token)──► Edge Function pluggy-sync (Deno)
                                   │
                                   ▼
raw_transactions (payload + hash) ─► transactions (normalizado, assinado) ─► classify_transactions()
                                   │
pg_cron "pos-sync" (+10 min) ──► post_sync(): reconcile_all, detect_duplicates,
                                   refresh_card_cycles, assign_card_competence, classificação
                                   │
                                   ▼
Views v_* (security_invoker, RLS por household) ◄── navegador (supabase-js + publishable key)
                                   ▲
Railway "app" (Bun) serve SPA ─────┘   https://familia-finance.up.railway.app
Railway "backup" (cron 09:00 UTC) ─► Edge backup-export ─► bucket S3 Railway "backups"
Railway "restore-check" (on deploy) ─► restaura em esquema restore_test e compara
```

### 3.1 Supabase — Edge Functions

| Slug | Versão | verify_jwt | Função | Ação recomendada |
|---|---|---|---|---|
| `pluggy-sync` | v6 (código v1.3.2) | false (protegida por `x-sync-token` de `app_settings`) | Ingestão Pluggy por cursor; casamento de contas/transações em reautorização; moeda estrangeira em BRL | Manter |
| `backup-export` | v2 | false (protegida por `x-backup-token`) | `GET` exporta todas as tabelas `public` em JSON; `POST /report` grava `backup_runs`; `POST /restore` chama `restore_backup_to_test()` | Manter |
| `member-invite` | v1 | true | Owner/admin cria usuário no Auth e gera link `#acesso=<token_hash>` (1 h, uso único), auditado | Manter |
| `owner-recovery` | v2 | true | Redefinição pontual da senha do Hugo em 06/11 — **desativada (responde 410)** | Remover |
| `pluggy-diag` | v5 | false | Diagnóstico temporário (só `GET /items`, sem refresh) | Remover (aguardava ok do Hugo) |
| `app` | v1 | false | Tentativa de servir HTML pelo Supabase — inútil | Remover |

**Secrets (Edge Function Secrets):** `PLUGGY_CLIENT_ID`, `PLUGGY_CLIENT_SECRET`. Tokens internos (`sync_token`, `backup_token`) e `pluggy_item_ids` ficam em `app_settings` (sem política RLS → só service_role).

### 3.2 Railway — projeto `familia-finance` (id `9e62e7a6-4137-4a19-b6f6-8a0ab822dcc0`, env `production`)

| Serviço | Id | Tipo | Agendamento | Último deploy |
|---|---|---|---|---|
| `app` | `022db954-6ad0-4ac5-a8b2-a08946bc16da` | Function Bun 1.4.4, sem variáveis (URL e publishable key no código) | contínuo | 07/11/2026 01:57 UTC — SUCCESS (v0.14.0) |
| `backup` | `4d7ec7db-f037-4859-8af7-693de947c69c` | Function Bun (script) | `0 9 * * *` (05:00 Cuiabá) | 07/11/2026 — SUCCESS |
| `restore-check` | `6e7fa322-bc40-451b-9bdf-f4a49e9311c3` | Function Bun (script) | sem cron — roda ao redeployar | 07/11/2026 — SUCCESS |

Variáveis de `backup` e `restore-check`: `BACKUP_URL`, `BACKUP_TOKEN`, `S3_ENDPOINT`, `S3_BUCKET`, `S3_REGION`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`.

> **Como o código está publicado:** Railway Functions guardam o arquivo-fonte em base64 dentro do `startCommand` (`./run.sh <base64>`). Use `get-function-source-code` / `update-function-source-code` do MCP Railway (substitui o arquivo inteiro).

### 3.3 pg_cron

| Job | Agenda (UTC) | Horário Cuiabá | Ação |
|---|---|---|---|
| `pluggy-sync-diario` | `15 1,3,10,22 * * *` | 21:15, 23:15, 06:15, 18:15 | chama `pluggy-sync` via pg_net |
| `pos-sync` | `25 1,3,10,22 * * *` | +10 min | `post_sync()` |

Motivo dos horários (07/11): o item MeuPluggy atualiza sozinho 1×/dia ≈ 01:02 UTC; a janela 01:15 pega a atualização do dia. **Não forçar refresh na Pluggy.**

---

## 4. Modelo de dados

### 4.1 Tabelas (contagens em 12/11/2026)

| Grupo | Tabelas |
|---|---|
| Família e acesso | `households` (1), `household_members` (2: Hugo owner, Juliana member) |
| Ingestão | `financial_institutions` (1), `connections` (2), `connection_consents` (34), `accounts` (3), `account_balance_history` (19), `card_statements` (3), `raw_transactions` (3.550), `transactions` (3.550), `investment_positions` (198 — uma linha por sync), `sync_jobs` (35), `sync_errors` (5, todos de 05–06/11, já resolvidos), `import_jobs` (0) |
| Classificação | `categories` (49), `classification_rules` (638), `classification_feedback` (26), `mcc_category_map` (81) |
| Cartão | `card_bill_cycles` (14), `card_holders` (4), `card_bill_reference_lines` (0 — referência PDF, não entra em totais) |
| Conciliação/qualidade | `transaction_links` (3), `data_quality_issues` (2.466) |
| Planejamento | `budgets` (30), `goals` (1), `commitments` (6), `category_flex` (15), `plan_settings` (1), `fixed_items` (64), `fixed_expenses` (29), `fixed_expense_values` (389), `financing_contracts` (2), `financing_installments` (689), `assets` (2), `sim_scenarios` (0) |
| Alertas/fechamento | `alert_settings` (7), `monthly_closings` (0 — nenhum mês fechado ainda) |
| Operação | `app_settings` (6), `audit_logs` (30), `backup_runs` (9), `backup_ids_20261106` (2.025 — backup de IDs da reautorização), `project_docs` (12) |

### 4.2 Colunas-chave de `transactions`
`amount` (numeric(14,2), **DEBIT negativo / CREDIT positivo**), `event_date` (aaaa-mm-dd como a Pluggy entrega), `competence_month`, `category_id`, `category_source`, `category_confidence`, `rule_id`, `review_status` (`pending`/…), `card_last4`, `holder_name`, `counterpart_name`, `installment_total`, `original_amount`, `original_currency`, `source` + `source_ref` (únicos).

### 4.3 Views (todas `security_invoker`)
`v_tx`, `v_month_summary`, `v_category_month`, `v_daily_flow`, `v_sync_status`, `v_alerts`, `v_alerts_base`, `v_card_bills`, `v_card_future_installments`, `v_budget_month`, `v_goals`, `v_net_worth`, `v_investments_latest`, `v_sim_base`, `v_group_channel`, `v_group_items`, `v_month_commitments`, `v_fixed_month`, `v_fixed_expenses`, `v_meta_base`, `v_meta_items`, `v_financing`.

> Atenção: `v_fixed_month` foi reescrita via `execute_sql` **depois** da migração 0021 (CTEs MATERIALIZED). A definição viva no banco é a verdade, não o arquivo de migração — por isso existe `supabase/schema/live/`.

### 4.4 Funções (schema `public`)

| Acessível ao app (authenticated) | Internas (só service_role — migração 0012) | Utilitárias |
|---|---|---|
| `set_transaction_category`, `month_close_check`, `close_month`, `reopen_month` | `export_backup`, `restore_backup_to_test`, `post_sync`, `reconcile_all`, `detect_duplicates`, `classify_transactions`, `refresh_card_cycles`, `assign_card_competence`, `handle_new_auth_user` | `my_household`, `current_member`, `can_edit`, `norm_text`, `derive_counterpart`, `payee_key_of`, `alert_param`, `fmt_br` (4 overloads), `set_updated_at` |

### 4.5 Migrações aplicadas (29)

| Lote | Migrações |
|---|---|
| 05/11 (v0.1–v0.2) | 0001 core ingestion · 0002 categorias + 587 regras v18 · 0003 motor de classificação · 0004 auth/RLS/views · 0005 security_invoker · 0006 conciliação · 0007 fix regra duplicada · 0008 backup export · 0009 restore test · 0010 restore compare fix |
| 06/11 (v0.3–v0.9) | 0006 backup IDs reautorização · 0007 moeda estrangeira · 0008 referência fatura PDF · 0009 ciclos/competência do cartão · 0011 alertas + fechamento · 0012 bloqueio de funções internas · 0013 Itaú/Mercado Livre/histórico · 0014 planejamento (patrimônio, orçamento, metas) · 0015 base de simulação · 0016 meta de sobra/flex/canal · 0017 piso por itens · 0018 reclassificações do Hugo · 0019 comprometido do mês · 0020 despesas fixas · 0021 performance |
| 07/11 (v0.10–v0.14) | 0022 meta mensal · 0023 contratos de financiamento · 0024 bens/patrimônio líquido · 0025 itens da meta |

⚠️ **A numeração repete** (0006–0009 existem duas vezes, com versões de timestamp diferentes). No repositório os arquivos são nomeados pelo `version` (timestamp) para não colidir.

---

## 5. Regras financeiras (contrato de negócio — não alterar sem o Hugo)

| # | Regra |
|---|---|
| 1 | Receita = ATMO Engenharia, Abrão Serviços Médicos, PIX recebidos da Juliana (confirmado 06/10/2026) |
| 2 | Transferências internas (pagamento de fatura, PIX entre contas do Hugo, transferência para familiar) não entram em receita/despesa gerencial |
| 3 | Cartão: competência = mês do **fechamento** da fatura; pagamento da fatura só aparece na visão de caixa |
| 4 | Cartão (Open Finance): competência pelo `billPostDate`; **parcela 2+ lançada pela Pluggy no dia do fechamento vai para a fatura seguinte** (com isso o 3738 bateu centavo a centavo com 7 PDFs). Total oficial = débito na conta; total por lançamentos é estimativa (±1%) |
| 5 | Titulares: cartões 5430 e 8305 = Hugo; 7297 e 3738 = Juliana. Todos na mesma fatura do Unique 5430 |
| 6 | Pessoas casadas por **nome completo normalizado**, nunca só primeiro nome |
| 7 | Precedência de classificação: ajuste do usuário > pessoa > regra do sistema > estabelecimento > tipo de operação > MCC (sugestão, confiança 0,70) > pendente |
| 8 | Nenhum lançamento é apagado; alterações da origem ficam em `raw_transactions.changed_count` / `missing_since` |
| 9 | PartnerBank = condomínios (apto Cuiabá e casa Chapada) → moradia. Bradesco boleto = financiamento do carro até 11/2026 |
| 10 | Boleto Itaú Unibanco = fatura do cartão Itaú extra (não conectado) → despesa `cartao_itau`, teto R$ 1.500 (alerta) |
| 11 | `MERCADOLIVRE*` = compras on-line. iFood (`IFD*`) = alimentação fora, exceto `IFD*DROGARIA` = saúde |
| 12 | Lançamentos antigos sem identificação → "Não identificado (histórico)" (`category_source='lote_historico'`), reversível |
| 13 | Meta de sobra **mensal** (R$ 10.000 proposta). Corte não linear: categorias fixas (moradia, educação, funcionários, apoio familiar, impostos, seguros) não cortam; essencial até 10%, ajustável até 30%, discricionária até 50% — tudo editável (`category_flex`) |
| 14 | Margem do mês = receita − fixas vigentes − parcelas do mês; parcelados entram **pelo valor real no mês em que caem**, nunca diluídos; saem por inteiro do "dia a dia habitual" |
| 15 | Fixas pagas pela conta (PIX/transferência/boleto/débito); variáveis em geral no cartão |
| 16 | Funcionários domésticos, pagos só pela conta: Juscelina (babá), Leila (doméstica seg–sex), Marilene (diarista fds), Ana Fátima (diarista Chapada), Elizeu (jardineiro Chapada) |
| 17 | Classificações confirmadas: Big Lar = supermercado; Condomínio Edifício America Tower = condomínio; Avante Assessoria = contabilidade; MEP Colégio Unicus = lanche da Alice (educação); Noelma = reforço escolar; Amelly Tallyta = personal da Juliana; Raul Jabras = personal do Hugo; Edneusa = mãe da Juliana (apoio familiar); Natália Neres de Almeida = maquiadora e Perezi Beleza = salão (Compras › Salão de beleza) |
| 18 | Patrimônio sem destaque; **dívida de financiamento só aparece junto com o bem** (imóveis pelo valor de garantia do banco: Cuiabá R$ 702.952,52; Chapada R$ 702.456,74) |
| 19 | Projeções e simulações nunca são apresentadas como resultado garantido; simulações não tocam dados reais |
| 20 | Valores `numeric(14,2)`; totais calculados em código/SQL; IA só sugere categorias e redige texto |

---

## 6. Frontend (`app/src/app.ts`, v0.14.0)

**Estrutura:** um único arquivo Bun com `Bun.serve` que entrega: `/` (SPA em template string `HTML`), `/manifest.json`, `/icon.png` (PNG 512 embutido), `/sw.js` (service worker mínimo), `/health` (`{ok, version}`). Qualquer outra rota → 302 para `/`. Headers: CSP restritiva, HSTS, nosniff, no-referrer.

**Stack no navegador:** JavaScript puro + `supabase-js` via cdn.jsdelivr.net; fonte IBM Plex Sans; tema claro/escuro por `prefers-color-scheme`; layout notebook (≥1000 px) com menu lateral e 2 colunas.

**Rotas (hash):**

| Rota | Tela | Dados principais |
|---|---|---|
| `#inicio` | Início: alertas, fluxo diário acumulado × mês anterior, despesas por categoria (gasto × orçado com traço do ritmo), bloco de fechamento do mês | `v_alerts`, `v_daily_flow`, `v_budget_month`, `v_month_summary`, rpc `month_close_check`/`close_month` |
| `#lancamentos` | Lista/filtro de lançamentos, edição de categoria com "aplicar no futuro" (cria regra) | `v_tx`, rpc `set_transaction_category` |
| `#cartao` | Faturas por ciclo e por titular | `v_card_bills`, `v_card_future_installments` |
| `#plano` | Orçamento do mês, comprometido (fixas + parcelas), compromissos, metas, patrimônio discreto; meses futuros (+12) | `v_budget_month`, `v_month_commitments`, `commitments`, `goals`, `v_net_worth`, `v_financing` |
| `#meta` | Meta de sobra mensal (13 meses), corte não linear, "ver gastos" por categoria, adoção grava `budgets` | `v_meta_base`, `v_meta_items`, `category_flex`, `plan_settings` |
| `#fixas` | Cadastro de despesas fixas com histórico de valores (vigência mensal) | `fixed_expenses`, `fixed_expense_values`, `v_fixed_expenses`, `v_fixed_month` |
| `#simular` | Simulações (9 tipos de ajuste combináveis), premissas, impacto imediato/mensal/anual, liquidez, riscos, tabela × base | `v_sim_base`, `sim_scenarios` |
| `#revisao` | Pendentes de classificação | `transactions` (`review_status='pending'`) |
| `#operacao` | Status de sincronização, membros (convite), documentos | `v_sync_status`, `sync_jobs`, `household_members`, `project_docs`, Edge `member-invite` |
| `#acesso=<token>` | Primeiro acesso do membro convidado (verifyOtp recovery → definir senha) | Supabase Auth |

---

## 7. Testes e validação

| Área | Implementado | Testado | Validado (dados reais) | Publicado |
|---|---|---|---|---|
| Ingestão Pluggy v2 + idempotência | ✅ | ✅ | ✅ 12 meses, 0 duplicados | ✅ |
| Conta corrente × 9 extratos PDF jan–set/26 | ✅ | ✅ | ✅ só viradas de mês (±50, ±475) e arredondamento ≤ R$ 0,04 | ✅ |
| Competência do cartão × 10 faturas PDF | ✅ | ✅ | ⚠️ jan–set ≤ 1,4%; **dez/25 +R$ 3.766 (13%) sem explicação**; nov/25 parcial | ✅ |
| Classificação automática | ✅ | ✅ | ✅ 11 pendentes restantes | ✅ |
| Alertas (`v_alerts`) | ✅ | ✅ | ✅ | ✅ |
| Fechamento mensal | ✅ | ✅ só a checagem | ❌ nenhum mês fechado | ✅ |
| Planejamento / meta mensal / fixas / financiamentos | ✅ | ✅ Playwright 390×844 e 1366×820 | ⚠️ números conferidos no banco; **validação visual do Hugo pendente** | ✅ |
| Simulações | ✅ | ✅ (conferência manual de cenário) | ⚠️ aguarda Hugo | ✅ |
| Backup + restauração | ✅ | ✅ | ✅ restore 07/11 com contagens e soma (−505.185,43) iguais à produção | ✅ diário |
| RLS | ✅ | ✅ anon bloqueado; owner lê/grava; **12/11: Juliana × Hugo testado** (simulação no banco, rollback) | ⚠️ login real da Juliana no app não feito | ✅ |
| Navegador real / celular do Hugo | — | Playwright apenas | ❌ não confirmado | — |

**Desempenho (06/11, papel authenticated):** `v_month_commitments` 20.545 → 99 ms; `v_fixed_expenses` 3.681 → 83 ms; demais < 60 ms.

**Prática de deploy adotada:** após publicar no Railway, ler o código de volta e conferir `diff` vazio contra o arquivo testado; checar `/health` com a versão.

---

## 8. Pendências

### 8.1 Dependem do Hugo
| # | Pendência |
|---|---|
| H1 | Abrir o app no celular e validar visualmente v0.10–v0.14 (Início, Plano, Meta, Fixas, Cartão) |
| H2 | Revisar 11 lançamentos pendentes (7 de out/26, 4 de nov/26) |
| H3 | Conferir despesas fixas "sugeridas" com valores irregulares: Personal Raul, Gil Lemes, SAAE Chapada, Seguro Allianz, Ana Fátima |
| H4 | Decidir adoção do orçamento/meta (nov/26 está inalcançável: margem 27,3 mil → sobra −4,3 mil) |
| H5 | Confirmar se o lanche da Alice é despesa fixa |
| H6 | Autorizar remoção de `pluggy-diag` e do item antigo Pluggy `22255fcb…` |
| H7 | Considerar conectar o cartão Itaú no Meu Pluggy |
| H8 | Aylton: pagamentos não localizados |
| H9 | Reautorizar o app na Pluggy antes de **05/11/2027** |

### 8.2 Técnicas (Claude Code pode executar)
| Prioridade | Pendência |
|---|---|
| P0 | ~~Criar repositório Git com todo o código e esquema~~ — feito 12/11/2026: github.com/hugoabrao-max/familia-finance (privado) |
| P0 | ~~Atualizar `project_docs` defasados (`PROJECT_STATE`, `DEPLOYMENT`, `ROADMAP`)~~ — feito 12/11/2026 (também `ARCHITECTURE`, `INTEGRATIONS`, `SECURITY`, `CHANGELOG`) |
| P1 | ~~Teste de RLS cruzada com o login da Juliana~~ — testado 12/11 por simulação no banco (ver TEST_REPORT) |
| P1 | Investigar diferença de dez/25 no cartão (+13%) |
| P1 | `restore-check` sem agendamento — criar rotina periódica (ex.: semanal) |
| P1 | Ativar proteção de senha vazada no Supabase Auth; avaliar MFA |
| P1 | "Esqueci a senha" no login (exige SMTP próprio) |
| P2 | Relatório mensal em PDF + planilha preservando conciliação (requisito das instruções do projeto) |
| P2 | Projeção de 6 meses; CFO AI com dados agregados (item 10 do Prompt Mestre) |
| P2 | Fixos recorrentes sem compromisso formal: conferir cobertura no comprometido do mês |
| P2 | "Seguro (parcelado)" também casa com seguro incêndio — conferir regra |
| P2 | `investment_positions` cresce 1 linha por sync — política de retenção |
| P2 | Remover Edge Functions `app`, `owner-recovery` (e `pluggy-diag` após ok) |
| P3 | Modularizar o frontend (hoje 92 KB em um template string) — só se não quebrar o fluxo de deploy |

---

## 9. Regras de trabalho para o Claude Code

Ver `CLAUDE.md`.

---

## 10. Repositório

```
familia-finance/
├── CLAUDE.md                     # regras de trabalho
├── HANDOFF.md                    # este relatório
├── docs/                         # export dos 12 project_docs
├── app/src/app.ts                # frontend (Railway serviço app)
├── railway/backup.ts             # Railway serviço backup
├── railway/restore-check.ts      # Railway serviço restore-check
├── supabase/functions/<slug>/    # Edge Functions
├── supabase/schema/
│   ├── migrations/<version>_<name>.sql   # de supabase_migrations.schema_migrations.statements
│   └── live/                              # definições vivas: views, funções, políticas, triggers, cron, tabelas
└── scripts/verify-export.sql     # consultas md5 para conferir o repositório contra o banco
```

**Recuperação total (desastre):** projeto Supabase novo → aplicar migrações na ordem de `version` → reaplicar definições vivas (`supabase/schema/live/`) → secrets Pluggy → restaurar o JSON mais recente do bucket com `jsonb_populate_recordset` (mesma lógica de `restore_backup_to_test`, sem o prefixo `restore_test`) → recriar tokens em `app_settings` → ajustar `SUPABASE_URL`/key no `app.ts` → rodar `pluggy-sync`.

---

## 11. Referências rápidas

| Recurso | Identificador |
|---|---|
| Supabase projeto | `familia-finance` · ref `hrsinekxrfiphlhpoewp` · https://hrsinekxrfiphlhpoewp.supabase.co |
| Railway projeto | `familia-finance` · `9e62e7a6-4137-4a19-b6f6-8a0ab822dcc0` · env production `f79eeeae-5238-4de5-a761-97746d6b3a13` |
| App | https://familia-finance.up.railway.app (`/health` → versão) |
| Pluggy item atual | `3b1fad88-40cc-4d56-8bd5-4c316243310d` (consentimento até 06/11/2027) |
| Pluggy item antigo | `22255fcb-4e82-42fe-b9d7-6e3f656df1ee` (em `app_settings.pluggy_item_ids_anterior`; remover após ok) |
| Contratos de financiamento | Apto Cuiabá 550900058734 (saldo R$ 327.923,03 em 22/10/26) · Casa Chapada 0010231243 (R$ 498.208,97 em 12/10/26) |
| App legado v18 | claude.ai/artifact/37SkCXP9Trf1WSPoHHryBN (somente referência) |
| Outros projetos Supabase/Railway na conta | `fratello-plataforma`, `fratello-frota`, `capable-*` — **não pertencem a este projeto, não mexer** |
