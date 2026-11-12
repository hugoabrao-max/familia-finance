create or replace view public.v_fixed_expenses with (security_invoker = on) as
 WITH fm AS (
         SELECT v_fixed_month.fixed_expense_id,
            max(v_fixed_month.pago) FILTER (WHERE (v_fixed_month.month = (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date)) AS pago_mes,
            max(v_fixed_month.pago) FILTER (WHERE (v_fixed_month.month = ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval))::date)) AS pago_mes_anterior
           FROM v_fixed_month
          WHERE ((v_fixed_month.month >= ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval))::date) AND (v_fixed_month.month <= (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date))
          GROUP BY v_fixed_month.fixed_expense_id
        ), vals AS (
         SELECT fixed_expense_values.fixed_expense_id,
            ((array_agg(fixed_expense_values.amount ORDER BY fixed_expense_values.valid_from DESC) FILTER (WHERE (fixed_expense_values.valid_from <= date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))))[1])::numeric(14,2) AS valor_atual,
            max(fixed_expense_values.valid_from) FILTER (WHERE (fixed_expense_values.valid_from <= date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))) AS valor_desde,
            ((array_agg(fixed_expense_values.amount ORDER BY fixed_expense_values.valid_from) FILTER (WHERE (fixed_expense_values.valid_from > date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))))[1])::numeric(14,2) AS proximo_valor,
            min(fixed_expense_values.valid_from) FILTER (WHERE (fixed_expense_values.valid_from > date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))) AS proximo_desde,
            count(*) AS n_valores
           FROM fixed_expense_values
          GROUP BY fixed_expense_values.fixed_expense_id
        )
 SELECT f.id,
    f.name,
    f.category_id,
    f.payee_key,
    f.match_pattern,
    f.channel,
    f.due_day,
    f.start_month,
    f.end_month,
    f.is_active,
    f.commitment_id,
    f.notes,
    f.source,
    f.created_at,
    f.updated_at,
    f.updated_by,
    COALESCE(c.parent_id, c.id) AS group_id,
    c.name AS category_name,
    g.name AS group_name,
    vals.valor_atual,
    vals.valor_desde,
    vals.proximo_valor,
    vals.proximo_desde,
    COALESCE(vals.n_valores, (0)::bigint) AS n_valores,
    fm.pago_mes,
    fm.pago_mes_anterior
   FROM ((((fixed_expenses f
     LEFT JOIN categories c ON ((c.id = f.category_id)))
     LEFT JOIN categories g ON ((g.id = COALESCE(c.parent_id, c.id))))
     LEFT JOIN vals ON ((vals.fixed_expense_id = f.id)))
     LEFT JOIN fm ON ((fm.fixed_expense_id = f.id)));
