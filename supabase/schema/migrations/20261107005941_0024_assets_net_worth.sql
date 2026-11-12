
create table if not exists public.assets(
  id text primary key, nome text not null, tipo text not null default 'imovel', valor numeric(14,2) not null,
  valor_fonte text, valor_em date, financing_id text references financing_contracts(id), is_active boolean not null default true,
  updated_at timestamptz not null default now());
alter table assets enable row level security;
create policy as_read on assets for select to authenticated using (true);
create policy as_write on assets for all to authenticated using (can_edit()) with check (can_edit());
insert into assets(id,nome,tipo,valor,valor_fonte,valor_em,financing_id) values
('imovel_cuiaba','Apartamento Cuiabá (Ed. American Tower, apto 403)','imovel',702952.52,'valor de garantia atual informado pelo banco (Santander)','2026-11-06','cuiaba'),
('imovel_chapada','Casa Chapada dos Guimarães (Residencial Villa Gramado)','imovel',702456.74,'valor de garantia atual informado pelo banco (Santander)','2026-11-06','chapada')
on conflict (id) do nothing;
create or replace view public.v_net_worth with (security_invoker=on) as
WITH contas AS (
  SELECT COALESCE(sum(balance) FILTER (WHERE subtype='CHECKING_ACCOUNT'),0) AS cc, COALESCE(sum(balance) FILTER (WHERE subtype='SAVINGS_ACCOUNT'),0) AS poup
  FROM accounts WHERE is_active AND type='BANK'
), inv AS (SELECT COALESCE(sum(balance),0) AS v FROM v_investments_latest),
cartao AS (SELECT COALESCE(sum(balance),0) AS v FROM accounts WHERE is_active AND type='CREDIT'),
div AS (SELECT COALESCE(sum(outstanding_balance),0) AS v, count(*) FILTER (WHERE kind='financiamento' AND outstanding_balance IS NULL) AS sem_saldo FROM commitments WHERE is_active),
bens AS (SELECT COALESCE(sum(valor),0) AS v FROM assets WHERE is_active)
SELECT contas.cc AS conta_corrente, contas.poup AS poupanca, inv.v AS investimentos, contas.cc+contas.poup+inv.v AS ativos_financeiros,
  cartao.v AS cartao_utilizado, div.v AS financiamentos_saldo, div.sem_saldo AS financiamentos_sem_saldo,
  contas.cc+contas.poup+inv.v-cartao.v-div.v AS patrimonio_financeiro_liquido,
  (SELECT max(balance_observed_at) FROM accounts) AS atualizado_em,
  bens.v AS bens, contas.cc+contas.poup+inv.v+bens.v-cartao.v-div.v AS patrimonio_liquido
FROM contas, inv, cartao, div, bens;

