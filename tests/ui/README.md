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
