create or replace view public.v_budget_month with (security_invoker = on) as
 WITH m AS (
         SELECT (generate_series(('2025-11-01'::date)::timestamp with time zone, (((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) + '1 year'::interval))::date)::timestamp with time zone, '1 mon'::interval))::date AS mes
        ), b AS (
         SELECT DISTINCT ON (bm.mes, bu.group_id) bm.mes,
            bu.group_id,
            bu.amount,
            bu.source
           FROM (m bm
             JOIN budgets bu ON (((bu.month = bm.mes) OR (bu.month = '1900-01-01'::date))))
          ORDER BY bm.mes, bu.group_id, bu.month DESC
        ), r AS (
         SELECT v_category_month.month AS mes,
            v_category_month.group_id,
            v_category_month.group_name,
            (- sum(v_category_month.total)) AS gasto
           FROM v_category_month
          WHERE (v_category_month.category_kind = 'despesa'::text)
          GROUP BY v_category_month.month, v_category_month.group_id, v_category_month.group_name
        )
 SELECT COALESCE(b.mes, r.mes) AS month,
    COALESCE(b.group_id, r.group_id) AS group_id,
    COALESCE(r.group_name, c.name) AS group_name,
    COALESCE(b.amount, (0)::numeric) AS orcado,
    b.source,
    COALESCE(r.gasto, (0)::numeric) AS gasto,
    (COALESCE(b.amount, (0)::numeric) - COALESCE(r.gasto, (0)::numeric)) AS saldo,
        CASE
            WHEN (COALESCE(b.amount, (0)::numeric) > (0)::numeric) THEN round((((100)::numeric * COALESCE(r.gasto, (0)::numeric)) / b.amount))
            ELSE NULL::numeric
        END AS pct
   FROM ((b
     FULL JOIN r ON (((r.mes = b.mes) AND (r.group_id = b.group_id))))
     LEFT JOIN categories c ON ((c.id = COALESCE(b.group_id, r.group_id))));
