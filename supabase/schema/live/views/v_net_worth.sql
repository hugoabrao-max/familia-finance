create or replace view public.v_net_worth with (security_invoker = on) as
 WITH contas AS (
         SELECT COALESCE(sum(accounts.balance) FILTER (WHERE (accounts.subtype = 'CHECKING_ACCOUNT'::text)), (0)::numeric) AS cc,
            COALESCE(sum(accounts.balance) FILTER (WHERE (accounts.subtype = 'SAVINGS_ACCOUNT'::text)), (0)::numeric) AS poup
           FROM accounts
          WHERE (accounts.is_active AND (accounts.type = 'BANK'::text))
        ), inv AS (
         SELECT COALESCE(sum(v_investments_latest.balance), (0)::numeric) AS v
           FROM v_investments_latest
        ), cartao AS (
         SELECT COALESCE(sum(accounts.balance), (0)::numeric) AS v
           FROM accounts
          WHERE (accounts.is_active AND (accounts.type = 'CREDIT'::text))
        ), div AS (
         SELECT COALESCE(sum(commitments.outstanding_balance), (0)::numeric) AS v,
            count(*) FILTER (WHERE ((commitments.kind = 'financiamento'::text) AND (commitments.outstanding_balance IS NULL))) AS sem_saldo
           FROM commitments
          WHERE commitments.is_active
        ), bens AS (
         SELECT COALESCE(sum(assets.valor), (0)::numeric) AS v
           FROM assets
          WHERE assets.is_active
        )
 SELECT contas.cc AS conta_corrente,
    contas.poup AS poupanca,
    inv.v AS investimentos,
    ((contas.cc + contas.poup) + inv.v) AS ativos_financeiros,
    cartao.v AS cartao_utilizado,
    div.v AS financiamentos_saldo,
    div.sem_saldo AS financiamentos_sem_saldo,
    ((((contas.cc + contas.poup) + inv.v) - cartao.v) - div.v) AS patrimonio_financeiro_liquido,
    ( SELECT max(accounts.balance_observed_at) AS max
           FROM accounts) AS atualizado_em,
    bens.v AS bens,
    (((((contas.cc + contas.poup) + inv.v) + bens.v) - cartao.v) - div.v) AS patrimonio_liquido
   FROM contas,
    inv,
    cartao,
    div,
    bens;
