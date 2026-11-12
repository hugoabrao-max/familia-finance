create or replace view public.v_financing with (security_invoker = on) as
 SELECT id,
    nome,
    banco,
    contrato,
    commitment_id,
    data_contrato,
    valor_financiado,
    sistema,
    indexador,
    taxa_efetiva_aa,
    taxa_nominal_aa,
    prazo_total,
    dia_vencimento,
    saldo_devedor,
    saldo_em,
    parcelas_pagas,
    parcelas_restantes,
    ultima_parcela,
    amortizacao_mensal,
    total_a_pagar,
    juros_a_pagar,
    seguros_tarifas_a_pagar,
    participacao,
    fonte,
    updated_at,
    ( SELECT i.valor
           FROM financing_installments i
          WHERE ((i.contract_id = c.id) AND (NOT i.pago))
          ORDER BY i.n
         LIMIT 1) AS proxima_parcela,
    ( SELECT i.due_date
           FROM financing_installments i
          WHERE ((i.contract_id = c.id) AND (NOT i.pago))
          ORDER BY i.n
         LIMIT 1) AS proximo_vencimento,
    ( SELECT COALESCE(sum(i.valor), (0)::numeric) AS "coalesce"
           FROM financing_installments i
          WHERE ((i.contract_id = c.id) AND (NOT i.pago) AND (i.due_date < ((date_trunc('year'::text, (CURRENT_DATE)::timestamp with time zone) + '2 years'::interval))::date) AND (i.due_date >= ((date_trunc('year'::text, (CURRENT_DATE)::timestamp with time zone) + '1 year'::interval))::date))) AS total_proximo_ano
   FROM financing_contracts c;
