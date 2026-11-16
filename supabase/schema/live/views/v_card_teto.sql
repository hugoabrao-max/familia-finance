create or replace view public.v_card_teto with (security_invoker = on) as
 WITH fixo AS (
         SELECT plan_settings.value
           FROM plan_settings
          WHERE (plan_settings.key = 'teto_fatura'::text)
        ), base AS (
         SELECT (( SELECT v_sim_base.receita_mensal
                   FROM v_sim_base))::numeric AS receita,
            COALESCE(( SELECT plan_settings.value
                   FROM plan_settings
                  WHERE (plan_settings.key = 'sobra_meta'::text)), (0)::numeric) AS reserva
        ), fxc AS (
         SELECT v_fixed_month.month AS mes,
            sum(COALESCE(v_fixed_month.devido, (0)::numeric)) AS v
           FROM v_fixed_month
          WHERE (v_fixed_month.channel = 'conta'::text)
          GROUP BY v_fixed_month.month
        ), m0 AS (
         SELECT COALESCE(min(v_card_bills.competence_month), (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date) AS m
           FROM v_card_bills
          WHERE (v_card_bills.status = 'aberta'::text)
        ), meses AS (
         SELECT ((m0.m + ((g.i || ' month'::text))::interval))::date AS mes,
            g.i
           FROM m0,
            generate_series(0, 6) g(i)
        ), lanc AS (
         SELECT (date_trunc('month'::text, (t.bill_closing_date)::timestamp with time zone))::date AS mes,
            sum((- t.amount)) FILTER (WHERE (COALESCE(t.installment_number, 1) >= 2)) AS parc,
            sum((- t.amount)) FILTER (WHERE (COALESCE(t.installment_number, 1) < 2)) AS avista
           FROM v_tx t
          WHERE ((t.account_subtype = 'CREDIT_CARD'::text) AND (t.bill_closing_date IS NOT NULL) AND (t.category_kind IS DISTINCT FROM 'transferencia'::text))
          GROUP BY ((date_trunc('month'::text, (t.bill_closing_date)::timestamp with time zone))::date)
        ), fut AS (
         SELECT v_card_future_installments.competence_month AS mes,
            sum(v_card_future_installments.valor) AS v
           FROM v_card_future_installments
          GROUP BY v_card_future_installments.competence_month
        ), fech AS (
         SELECT v_card_bills.competence_month AS mes,
            min(v_card_bills.closing_date) AS fecha,
            min(v_card_bills.due_date) AS vence
           FROM v_card_bills
          WHERE (v_card_bills.status <> 'paga'::text)
          GROUP BY v_card_bills.competence_month
        ), r AS (
         SELECT ms.mes,
            ms.i,
            f.fecha,
            f.vence,
            COALESCE(l.parc, (0)::numeric) AS parc,
            COALESCE(fu.v, (0)::numeric) AS fut,
            COALESCE(l.avista, (0)::numeric) AS avista,
            ( SELECT fixo.value
                   FROM fixo) AS fixo,
            round(((b.receita - COALESCE(x.v, (0)::numeric)) - b.reserva), 2) AS auto,
            b.receita,
            COALESCE(x.v, (0)::numeric) AS fixas_conta,
            b.reserva
           FROM (((((meses ms
             CROSS JOIN base b)
             LEFT JOIN lanc l ON ((l.mes = ms.mes)))
             LEFT JOIN fut fu ON ((fu.mes = ms.mes)))
             LEFT JOIN fech f ON ((f.mes = ms.mes)))
             LEFT JOIN fxc x ON ((x.mes = ms.mes)))
        )
 SELECT mes,
    fecha,
    vence,
        CASE
            WHEN (i = 0) THEN 'aberta'::text
            ELSE 'futura'::text
        END AS situacao,
    COALESCE(fixo, auto) AS teto,
    round(parc, 2) AS parcelas_lancadas,
    round(fut, 2) AS parcelas_a_lancar,
    round((parc + fut), 2) AS comprometido,
    round(avista, 2) AS gasto_variavel,
    round((((COALESCE(fixo, auto) - parc) - fut) - avista), 2) AS livre,
        CASE
            WHEN ((fecha IS NOT NULL) AND (fecha >= ((now() AT TIME ZONE 'America/Cuiaba'::text))::date)) THEN (fecha - ((now() AT TIME ZONE 'America/Cuiaba'::text))::date)
            ELSE NULL::integer
        END AS dias_ate_fechar,
        CASE
            WHEN (fixo IS NOT NULL) THEN 'fixado'::text
            WHEN (auto IS NOT NULL) THEN 'automatico'::text
            ELSE NULL::text
        END AS teto_origem,
    auto AS teto_auto,
    round(receita, 2) AS receita_base,
    round(fixas_conta, 2) AS fixas_conta,
    reserva
   FROM r
  ORDER BY mes;
