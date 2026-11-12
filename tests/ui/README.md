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

`fase1.test.js` cobre a Fase 1 do redesenho: voltar devolve o lugar (rolagem e tela
na hora), janela de categoria (diálogo, Esc, Voltar do Android, "criar regra"
desmarcado, Desfazer), confirmação de fechar o mês com ressalva obrigatória, aviso
de falha em vez de números incompletos, mês atual no fuso de Cuiabá e layout de
notebook. Reinicie o servidor depois de editar `app.ts` (ele carrega o arquivo ao iniciar).

`fase3.test.js` cobre a Fase 3: totais separados (entradas, saídas, líquido) sobre todo o filtro, lista agrupada por dia com subtotal, "carregar mais" de 100 em 100 com quantos faltam, voltar mantendo o que já foi carregado, busca ao digitar (descrição ou estabelecimento, com espera de 350 ms e sem empilhar histórico) e Revisão em lote por estabelecimento (regra criada só na primeira gravação, opcional, um a um continua possível).

`fase4.test.js` cobre a Fase 4: Plano como painel de 4 cards (Orçamento, Meta de sobra, Contas fixas, Simular) com valores e destinos, Reservas separadas, Patrimônio recolhido, tela de Orçamento com "restam/passou", edição "só neste mês" (1 linha, com Desfazer) e "deste mês em diante" (congela os meses anteriores com o valor antigo sem sobrescrever, grava do mês até +12 e o padrão), Contas fixas com financiamentos e parcelamentos, valores digitados no formato brasileiro (1.200 = mil e duzentos).

`fase5.test.js` cobre a Fase 5: tela Mais com palavras de casa (conexão "atualizada há 3 horas", sincronização "sem erros", "Hugo (dono)", horários no fuso de Cuiabá), possíveis duplicidades (vazia e com item, link do alerta rola até a seção), tema Automático/Claro/Escuro aplicado na hora e guardado no aparelho, itens de lista acionáveis por teclado (Enter abre, Esc fecha e devolve o foco), aba atual com aria-current, rótulos de campos, alvos de toque ≥ 44 px, vocabulário novo em Meta/Simular, financiamento reconhecido nas contas fixas pela categoria e grade de duas colunas no notebook lida da esquerda para a direita.
