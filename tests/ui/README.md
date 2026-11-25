# Testes de interface (Playwright, Supabase simulado)

Rodam o app localmente com o próprio servidor Bun e respostas simuladas do banco
(nenhum dado real é lido ou gravado).

```bash
# 1) supabase-js na mesma versão de produção (o sandbox não alcança cdn.jsdelivr.net)
cd tests/ui && npm init -y >/dev/null && npm install @supabase/supabase-js@2.49.1 \
  && bun build node_modules/@supabase/supabase-js/dist/module/index.js --format esm --target browser --outfile sb.mjs
# 2) app local
PORT=3999 bun ../../app/src/app.ts &
# 3) testes (gera capturas de tela em ./out)
mkdir -p out && node fase1.test.js http://localhost:3999/ ./out
```

Capturas de revisão do redesenho (`out/redesenho-{inicio,extrato,plano}-{claro,escuro}.png`, 390×844, escala 2) saem de `fase2`, `fase3` e `fase4`. Com `FONTES_DIR=<pasta>` elas usam uma cópia local das fontes do Google (ver `fontes.js`); sem isso, as fontes ficam barradas como nos demais testes e aparecem as de reserva (Georgia).

`fase1.test.js` cobre a Fase 1 do redesenho: voltar devolve o lugar (rolagem e tela
na hora), janela de categoria (diálogo, Esc, Voltar do Android, "criar regra"
desmarcado, Desfazer), confirmação de fechar o mês com ressalva obrigatória, aviso
de falha em vez de números incompletos, mês atual no fuso de Cuiabá e layout de
notebook. Reinicie o servidor depois de editar `app.ts` (ele carrega o arquivo ao iniciar).

Desde a v0.26.0 (visual "caderno de contas") `fase2` cobre o Início em linhas: nome da família, mês com setas (‹ novembro ›; o `#mp` continua existindo como lista escondida sob o nome do mês), um só número grande, linhas Receitas/Gastos/Fatura que fecham com o Sobrou, "Precisa de você" com ação à direita, ritmo como barra única (gasto × esperado pelo orçamento proporcional aos dias) e explicações longas trocadas por "?".

`fase3.test.js` cobre a Fase 3 (tela agora chamada Extrato; rota `#lancamentos` igual): totais separados (entradas, saídas, líquido) sobre todo o filtro, lista agrupada por dia com subtotal, "carregar mais" de 100 em 100 com quantos faltam, voltar mantendo o que já foi carregado, busca ao digitar (descrição ou estabelecimento, com espera de 350 ms e sem empilhar histórico) e Revisão em lote por estabelecimento (regra criada só na primeira gravação, opcional, um a um continua possível). Desde a v0.26.0 também: totais "Entrou/Saiu/Ficou" em linha, valores sem "R$" nas linhas (entrada verde com "+"), cabeçalho "Hoje, 12 de novembro", bolinha com a inicial na cor do grupo, inicial de quem gastou, pendente em âmbar, filtros rápidos (Tudo/Gastos/Receitas/Cartão/Conta, parâmetros `kind`/`via`) e "+ filtro" abrindo categoria e conta.

`fase4.test.js` cobre a Fase 4: Plano em 4 linhas (Orçamento, Meta de sobra, Contas fixas, E se…; até a v0.25 eram cards) com ação à direita com valores e destinos, Reservas separadas, Patrimônio recolhido, tela de Orçamento com "restam/passou", edição "só neste mês" (1 linha, com Desfazer) e "deste mês em diante" (congela os meses anteriores com o valor antigo sem sobrescrever, grava do mês até +12 e o padrão), Contas fixas com financiamentos e parcelamentos, valores digitados no formato brasileiro (1.200 = mil e duzentos).

`fase5.test.js` cobre a Fase 5: tela Mais com palavras de casa (conexão "atualizada há 3 horas", sincronização "sem erros", "Hugo (dono)", horários no fuso de Cuiabá), possíveis duplicidades (vazia e com item, link do alerta rola até a seção), tema Automático/Claro/Escuro aplicado na hora e guardado no aparelho, itens de lista acionáveis por teclado (Enter abre, Esc fecha e devolve o foco), aba atual com aria-current, abas só com texto (sem ícones, desde a v0.26), rótulos de campos, alvos de toque ≥ 44 px (itens, abas, setas do mês e chips), vocabulário novo em Meta/Simular, financiamento reconhecido nas contas fixas pela categoria e grade de duas colunas no notebook lida da esquerda para a direita.

`teto.test.js` cobre o teto da fatura (v0.23): sem teto mostra o convite; a janela sugere a média das últimas faturas pagas; salva `teto_fatura` em plan_settings; livre = teto − parcelas comprometidas − gastos já lançados, com ritmo por dia até o fechamento; próximas faturas; aviso no Início quando passa do teto; remover teto.

`push.test.js` cobre as notificações no celular (v0.24): seção Notificações em Mais, ligar (pede a chave pública do servidor e grava o aparelho), enviar teste, desligar, orientação para iPhone fora da tela de início e uma mensagem de push real entregue ao service worker do app (via Chrome DevTools) virando notificação com o link da Revisão. Usa o Chromium completo (`channel: chromium`), porque o headless-shell nega notificações.

`seguranca.test.js` cobre a correção de segurança (v0.24.1): links com código no parâmetro `month` (Categoria, Lançamentos, Orçamento) não executam nada nem envenenam o mês guardado; nomes de membro e de documento com apóstrofo e código aparecem como texto e abrem pelo id/nome certo; toda chamada que não é simulada é barrada (nada vai para o Supabase real). Sai com código 1 se alguma verificação falhar.

Desde 24/11/2026 todos os scripts terminam com código 1 quando alguma verificação falha (antes só imprimiam "HÁ FALHAS") e barram qualquer chamada que não esteja simulada (nada chega ao Supabase real); essa barreira vira uma verificação a mais em cada script.

## Banco (`tests/db/rls.sh`)
Sobe o esquema do kit (`install/01_schema.sql`, gerado de `supabase/schema/live` por `install/build.py`) num Postgres 16 local com dados iniciais e confere, em todas as tabelas e views: quem não é da família e o anônimo não leem nada (exceto 3 views que só devolvem zeros), o membro lê; avisos de backup só para membros e aparecem quando o backup atrasa; o backup não leva segredos; toda tabela tem RLS. Rodar depois de cada migração: `python3 install/build.py && bash tests/db/rls.sh`.

## Cadeia pós-sincronização (`tests/db/calculo.sh`)
Monta contas e lançamentos de teste e roda `post_sync()` duas vezes: duas compras iguais no mesmo dia não viram duplicidade; a mesma compra vinda de outra origem vira; transferência entre contas próprias fica casada e continua transferência; lançamento de mês fechado não é reclassificado; toda mudança de categoria em lote fica em `audit_logs`; resultado do mês não fica vazio. Rodar com `python3 install/build.py && bash tests/db/calculo.sh`.

`manutencao.test.js` cobre a v0.25.0: Meta com uma consulta falhando mostra o aviso e não guarda números incompletos (ao tentar de novo, busca tudo outra vez — a v0.24.2 caía aqui); o total de Lançamentos com 2.500 lançamentos soma tudo (páginas buscadas em paralelo).
