# Family Finance — instalação para uma nova família

App de finanças da família: lê conta corrente, poupança, cartão e investimentos pelo Open Finance (Pluggy), classifica os lançamentos, mostra o mês, o orçamento, as contas fixas e a meta de sobra. Cada instalação é independente: banco de dados, app e conexão bancária próprios.

## Jeito mais fácil: com o Claude
Se você usa o Claude Code (ou o Claude no computador com os conectores do Supabase e do Railway), abra esta pasta nele e peça: **"instale o Family Finance seguindo o README"**. O arquivo `CLAUDE.md` explica a instalação para ele; o Claude vai pedir só o que precisar de você, um passo por vez. O passo a passo abaixo é o mesmo, para fazer à mão.

## O que você precisa criar (todas no seu nome)

| Conta | Para quê | Custo |
|---|---|---|
| GitHub (github.com) | guardar o código do seu app | grátis |
| Supabase (supabase.com) | banco de dados e login | plano gratuito atende |
| Railway (railway.com) | deixar o app no ar | cobrança por uso, poucos dólares por mês |
| Pluggy (pluggy.ai) | conexão com o banco (Open Finance) | confira o plano na Pluggy |

Nenhuma dessas contas precisa dos seus dados bancários para ser criada. A conexão com o banco é o último passo. Tudo fica só nas suas contas: ninguém mais tem acesso.

## Passo a passo

### 1. Banco de dados (Supabase)
1. Crie um projeto (região São Paulo, se houver). Guarde a senha do banco num lugar seguro.
2. No SQL Editor, rode `install/01_schema.sql` inteiro.
3. Em `install/02_seed.sql`, troque os 4 marcadores `{{...}}` (nome da família, seu nome, seu e-mail, seu nome como aparece no PIX) e rode.
4. Em Authentication → Providers, deixe só E-mail ligado. Em Authentication → Sign In / Providers, desligue "Allow new users to sign up" depois de criar o seu login.

### 2. Funções (Supabase → Edge Functions)
No painel: Edge Functions → Deploy a new function → Via Editor; dê o nome exato da pasta e cole o conteúdo do `index.ts`. Publique as três funções da pasta `supabase/functions/`:
- `pluggy-sync` (sincronização), com **Verify JWT desligado** (ela confere um token próprio);
- `member-invite` (link de acesso para membros), com **Verify JWT ligado**;
- `backup-export` (opcional), com **Verify JWT desligado**.

### 3. App (Railway)
1. No GitHub: New repository → nome `family-finance`, **Private** → Create. Na página do repositório, clique em "uploading an existing file" e arraste todo o conteúdo desta pasta (as pastas `app`, `install`, `supabase`, `railway` e os arquivos soltos) → Commit changes.
2. No Railway: New Project → Deploy from GitHub → escolha o repositório. Em Settings: Root Directory `/app`, Healthcheck `/health`.
3. Em Variables, crie `SUPABASE_URL` (ex.: `https://abcdefgh.supabase.co`) e `SUPABASE_ANON_KEY` (a "publishable key" do Supabase, em Project Settings → API Keys).
4. Em Settings → Networking, gere um domínio. Abra o endereço: deve aparecer a tela de login.
5. No Supabase, Edge Functions → Secrets: crie `APP_URL` com o endereço gerado no passo anterior (o que você abre no navegador, começando com `https://`). É para onde os links de acesso de membros apontam.

### 4. Seu login
No Supabase, Authentication → Users → Add user, com o mesmo e-mail que você pôs no `02_seed.sql`. Entre no app com ele. Para outra pessoa da família, cadastre o e-mail dela na tabela `household_members` e gere o link de acesso em Mais → Membros.

### 5. Conexão com o banco (faça você mesmo, por último)
1. Na Pluggy, crie a aplicação e conecte suas contas pelo Meu Pluggy. Anote o `CLIENT_ID`, o `CLIENT_SECRET` e o id do item conectado.
2. No Supabase, Edge Functions → Secrets: crie `PLUGGY_CLIENT_ID` e `PLUGGY_CLIENT_SECRET`.
3. No SQL Editor: `insert into app_settings(key,value) values ('pluggy_item_ids','<id do item>');`
4. Rode `install/03_cron.sql` trocando `{{PROJECT_REF}}` pelo código do projeto. A primeira sincronização acontece no próximo horário agendado (4 vezes por dia).

## Depois de instalado
- Revisão: classifique os lançamentos pendentes; marque "criar regra" para o app aprender.
- Plano → Contas fixas: cadastre aluguel, condomínio, escola, financiamentos.
- Plano → Orçamento: defina quanto quer gastar por grupo.
- Os nomes das categorias podem ser trocados no Supabase (tabela `categories`, coluna `name`).

## Limites conhecidos
- O cálculo de qual fatura do cartão cada compra pertence foi conferido com faturas de um cartão Santander. Em outro banco, confira as primeiras faturas com o PDF do banco.
- A Pluggy atualiza os dados do banco cerca de uma vez por dia; o app não força atualização.
- Valores e regras financeiras partem de padrões genéricos; ajuste às suas contas.
