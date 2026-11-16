create or replace view public.v_card_teto with (security_invoker = on) as
 WITH teto AS (
         SELECT plan_settings.value
           FROM plan_settings
          WHERE (plan_settings.key = 'teto_fatura'::text)
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
        )
 SELECT ms.mes,
    f.fecha,
    f.vence,
        CASE
            WHEN (ms.i = 0) THEN 'aberta'::text
            ELSE 'futura'::text
        END AS situacao,
    ( SELECT teto.value
           FROM teto) AS teto,
    round(COALESCE(l.parc, (0)::numeric), 2) AS parcelas_lancadas,
    round(COALESCE(fu.v, (0)::numeric), 2) AS parcelas_a_lancar,
    round((COALESCE(l.parc, (0)::numeric) + COALESCE(fu.v, (0)::numeric)), 2) AS comprometido,
    round(COALESCE(l.avista, (0)::numeric), 2) AS gasto_variavel,
    round((((( SELECT teto.value
           FROM teto) - COALESCE(l.parc, (0)::numeric)) - COALESCE(fu.v, (0)::numeric)) - COALESCE(l.avista, (0)::numeric)), 2) AS livre,
        CASE
            WHEN ((f.fecha IS NOT NULL) AND (f.fecha >= ((now() AT TIME ZONE 'America/Cuiaba'::text))::date)) THEN (f.fecha - ((now() AT TIME ZONE 'America/Cuiaba'::text))::date)
            ELSE NULL::integer
        END AS dias_ate_fechar
   FROM (((meses ms
     LEFT JOIN lanc l ON ((l.mes = ms.mes)))
     LEFT JOIN fut fu ON ((fu.mes = ms.mes)))
     LEFT JOIN fech f ON ((f.mes = ms.mes)))
  ORDER BY ms.mes;
