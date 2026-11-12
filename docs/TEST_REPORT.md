07/11/2026 backup — backup completo familia-finance/2026-11-07T13-11-24-964Z.json.gz (1,38 MB, 42 tabelas, hash conferido por releitura). restore-check restaurou em esquema isolado e comparou com a produção: ok=true, todas as contagens iguais (exceto backup_runs, que muda por definição), soma das transações -505.185,43 = produção. Serviço restore-check agora SUCCESS.
07/11/2026 v0.14 — node --check ok; Playwright 390×844 sem erros de JS: barras gasto÷orçado, cores, traço do ritmo, "sem orçamento" e pílula "proposta" visíveis na captura. Deploy no Railway conferido idêntico ao arquivo local (diff vazio, APP_VERSION 0.14.0). Implementado/testado/publicado; validação visual pelo Hugo pendente.
07/11/2026 v0.10 — Playwright: Meta mensal nov/26 e dez/26 (parcela da pousada 4.357,50 aparece como parcela de Lazer em dez, não diluída), troca de mês pela tabela, meta 16 mil, adoção de dez/26 a nov/27 grava 60 linhas de budgets por mês com basis (fixas, parcelas, dia a dia). Deploy conferido idêntico. Dados reais (meta 10 mil, cortes padrão): nov/26 margem 27,3 mil → sobra −4,3 mil (inalcançável); dez/26 margem 36,8 mil → sobra 5,2 mil; jan–mai/27 margem ~43,6 mil → meta atingida; jun/27+ margem ~46 mil.
06/11/2026 v0.9 — Playwright 1366×820: Início, Plano, Despesas fixas, Lançamentos, Cartão, Simulações, Mais e janela de edição conferidos visualmente; 390×844 sem regressão (abas inferiores, fluxos de gravação, convite, simulação). Deploy conferido idêntico.
06/11/2026 desempenho (papel authenticated, usuário Hugo): v_month_commitments 20.545 ms → 99 ms; v_fixed_expenses 3.681 → 83 ms; v_tx mês 72 → 15; v_category_month 67 → 13; v_alerts 95 → 56; v_budget_month 38 → 13; v_sim_base 102 → 45; demais < 45 ms. Totais conferidos iguais antes/depois.
06/11/2026 v0.8
- Playwright: #fixas lista ativas por grupo, total/pago/a pagar, aviso "último pago" (>5%), próximo valor programado, encerradas separadas; sheet com histórico; novo valor grava upsert (fixed_expense_id, valid_from); nova despesa grava cadastro + valor; Plano dez/26 com rótulo "Despesas fixas previstas"; demais telas sem regressão.
- Banco: v_month_commitments real — despesas fixas comprometidas nov/26 R$41,0 mil (a pagar), dez R$38,5 mil, a partir de jan/27 R$38,0 mil/mês; parcelas do cartão inalteradas.
- Deploy Railway conferido idêntico ao testado.
- Conhecido: "Seguro (parcelado)" (padrão "mensalidade de seguro") também casa com o seguro incêndio — conferir.
06/11/2026 v0.7
- Playwright (390px, mocks): Plano nov/26 mostra "Comprometido no mês" (parcelas já lançadas + compromissos não pagos) e linha por categoria; dez/26 mostra "Já comprometido para este mês", parcelas "a lançar" e Livre = orçado − gasto − pendentes − parcelas; edição de orçamento, compromisso e meta seguem OK; Simulações, Meta de sobra, convite de membro e primeiro acesso sem regressão. Sem erros de JS (só aviso do service worker no ambiente de teste).
- Deploy Railway: código publicado conferido idêntico ao testado (diff).
- Dados reais v_month_commitments: nov/26 parcelas 14.275 (12) + compromissos 14.542; dez 8.800 + 10.513; jan–mar/27 2.502 + 9.976; abr–mai 2.443; jun–ago 98; set 78.
05/11/2026
- pluggy-sync: FAILED (sem item id) → PARTIAL (410 endpoint legado) → SUCCESS v2 (1.011/0 erros). Cron 10:00 UTC: 28 relidos, 0 novos, 0 alterados (idempotência OK).
- Conciliação CC jan–set/2026 vs 9 PDFs: só diferenças de virada de mês (±50, ±475) e arredondamento ≤ R$0,04.
- Classificação: 913/1.011 automático.
- reconcile_all + detect_duplicates com dados sintéticos (rollback): transferência CC→poupança OK; fatura×pagamento OK; estorno cartão OK; duplicidade entre origens OK (sinalizada, oculta dos totais, não apagada); dados reais: 0 issues.
- Auth: usuário real criado via dashboard, vinculado ao owner pelo trigger, login registrado 03:27 UTC.
- Frontend: /health 200; HTML text/html; CSP própria. Navegador real: NÃO testado. RLS cruzada: NÃO testada (1 usuário).
- Backup: SUCCESS 13:37 UTC, 372.553 bytes, sha256 caa54106…, releitura conferida. Restore: 21 tabelas iguais, soma transações −38.135,14 = produção. Comparador corrigido (app_settings sem tokens).

06/11/2026
- Competência do cartão × 10 faturas PDF: diferenças jan +228/-0,7%, fev -251, mar +179, abr -408, mai +216, jun -236, jul -171, ago +628, set -720 (todas ≤1,4%); dez/25 +3.766 (13%) não explicada; 3738 exato em 7/7.
- Fechamentos inferidos pelas parcelas conferem com PDF (27/03, 28/04, 29/05, 29/09); out/26 = 29/10.
- Pagamentos de fatura: 11 vinculados ao débito "FATURA CARTAO VISA FINAL 5430" (1ª tentativa vinculou boletos Itaú por engano; corrigido filtrando pelo final do cartão).
- v_alerts com dados reais: 2 alertas (fatura 06/11 R$ 45.525,81 × saldo R$ 20.143,76; 109 pendentes).
- month_close_check set/out: funcionam; nenhum mês fechado.
- Frontend v0.2: Playwright 390×844, supabase-js real com API simulada, 5 rotas + troca de mês sem erro de página; código publicado = código testado (diff vazio).
- Segurança: has_function_privilege confirma anon=false em export_backup/post_sync/set_transaction_category; authenticated=true só nas funções do app.
06/11/2026 (v0.4)
- RLS: como usuário autenticado (Hugo) gravou orçamento e leu v_net_worth/v_budget_month/v_alerts; como anon, leitura bloqueada.
- Playwright 390×844: aba Plano renderiza sem rolagem horizontal; gravações enviadas corretamente (orçamento 15.000,50 → 15000.5; saldo devedor 412.345,67 → 412345.67; nova meta).
- Código publicado = código testado (diff vazio).
- Valores reais: ativos financeiros R$ 57.644,58 (CC 20.143,76 + poupança 1.235,36 + CDB 36.265,46); cartão utilizado R$ 91.563,37; parcelas futuras dez/26 R$ 8.799,62.
06/11/2026 (v0.5)
- Simulador: Playwright com base real (receita 84.680,50; despesas 84.485/mês); base mostra +R$ 195 em nov e +R$ 4.224 a partir de dez (fim do carro). Cenário veículo+corte lazer+quitação: impacto recorrente +R$ 5.253 conferido à mão (7.383 + 870 − 3.001). Remover ajuste e salvar cenário OK.
- Primeiro acesso: fluxo #acesso → verifyOtp(recovery) → updateUser(senha) testado com API simulada. member-invite publicado; teste real depende do clique do Hugo (Mais → Membros → Juliana).
- Código publicado = código testado (diff vazio).
06/11/2026 (v0.6)
- Meta de sobra com base real: sobra atual R$ 4.203; meta 10.000 → corte R$ 5.798 distribuído (Compras −2.156, Lazer −1.590, Outros −708, Alimentação −591, Saúde −450, Assinaturas −239, Transporte −64); sobra máxima R$ 14.776; meta 16.000 sinalizada como inalcançável. Adotar grava budgets (inclui veículos = 0 após fim do carro), category_flex, plan_settings e aporte da reserva. Código publicado = testado.