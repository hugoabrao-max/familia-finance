# Family Finance — instruções para o Claude (instalação nova)

Este repositório é o app de finanças da família de quem o abriu. Sua tarefa típica: **instalar e manter**, seguindo `README.md` (o passo a passo completo).

## Como conduzir a instalação
1. Pergunte, uma coisa por vez, o que falta: nome da família, nome e e-mail do administrador, nome completo como aparece no PIX (minúsculas, sem acento), se já criou as contas no GitHub, Supabase, Railway e Pluggy.
2. Se tiver os conectores do Supabase e do Railway, use-os (rodar SQL, publicar Edge Functions, criar o serviço). Sem eles, guie a pessoa no painel, tela por tela.
3. Ordem: `install/01_schema.sql` → `install/02_seed.sql` (troque os 4 marcadores `{{...}}`) → Edge Functions → app no Railway (variáveis `SUPABASE_URL`, `SUPABASE_ANON_KEY`) → segredo `APP_URL` → login do administrador → por último, a conexão com o banco (Pluggy) e `install/03_cron.sql`.
4. Depois de cada passo, confira (ex.: `select count(*) from categories` deve dar 48; `/health` do app deve responder `{"ok":true,...}`).

## Regras
- Nunca apagar dados financeiros. Mudanças no banco só aditivas.
- Não colar segredos (Pluggy, service role, senhas) no chat nem em arquivos do repositório; eles vão em Edge Functions → Secrets.
- A conexão com o banco é feita pela própria pessoa, na Pluggy. Não forçar atualização na Pluggy (ela atualiza ~1x/dia); usar `/v2/transactions`.
- Valores em reais no formato brasileiro.
- O cálculo de fatura do cartão foi conferido com um cartão Santander; em outro banco, sugira conferir as primeiras faturas com o PDF.
