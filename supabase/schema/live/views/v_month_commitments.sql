create or replace view public.v_month_commitments with (security_invoker = on) as
 WITH parc_lancadas AS (
         SELECT v.month AS mes,
            v.group_id,
            (- sum(v.amount)) AS v,
            count(*) AS n
           FROM v_tx v
          WHERE ((v.account_subtype = 'CREDIT_CARD'::text) AND (COALESCE(v.installment_number, 1) >= 2))
          GROUP BY v.month, v.group_id
        ), parc_futuras AS (
         SELECT f.competence_month AS mes,
            f.group_id,
            sum(f.valor) AS v,
            count(*) AS n
           FROM v_card_future_installments f
          WHERE (NOT (EXISTS ( SELECT 1
                   FROM parc_lancadas p_1
                  WHERE (p_1.mes = f.competence_month))))
          GROUP BY f.competence_month, f.group_id
        ), parc AS (
         SELECT parc_lancadas.mes,
            parc_lancadas.group_id,
            parc_lancadas.v,
            parc_lancadas.n
           FROM parc_lancadas
        UNION ALL
         SELECT parc_futuras.mes,
            parc_futuras.group_id,
            parc_futuras.v,
            parc_futuras.n
           FROM parc_futuras
        ), comp AS (
         SELECT fm.month AS mes,
            fm.group_id,
            fm.name,
            COALESCE(fm.devido, (0)::numeric) AS devido,
            fm.pago
           FROM v_fixed_month fm
          WHERE (fm.month >= (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date)
        )
 SELECT COALESCE(p.mes, k.mes) AS month,
    COALESCE(p.group_id, k.group_id) AS group_id,
    COALESCE(p.v, (0)::numeric) AS parcelas_cartao,
    COALESCE(p.n, (0)::numeric) AS n_parcelas,
    COALESCE(k.pendente, (0)::numeric) AS compromissos_pendentes,
    k.nomes
   FROM (( SELECT parc.mes,
            parc.group_id,
            sum(parc.v) AS v,
            sum(parc.n) AS n
           FROM parc
          GROUP BY parc.mes, parc.group_id) p
     FULL JOIN ( SELECT comp.mes,
            comp.group_id,
            sum(GREATEST((comp.devido - comp.pago), (0)::numeric)) AS pendente,
            string_agg(comp.name, ', '::text ORDER BY comp.devido DESC) FILTER (WHERE ((comp.devido - comp.pago) > 0.5)) AS nomes
           FROM comp
          GROUP BY comp.mes, comp.group_id) k ON (((k.mes = p.mes) AND (k.group_id = p.group_id))));
