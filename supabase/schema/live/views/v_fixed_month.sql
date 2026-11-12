create or replace view public.v_fixed_month with (security_invoker = on) as
 WITH meses AS (
         SELECT (generate_series((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval), (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) + '1 year'::interval), '1 mon'::interval))::date AS mes
        ), tx AS MATERIALIZED (
         SELECT t.month,
            t.category_id,
            payee_key_of(t.counterpart_name, t.description) AS pk,
            norm_text(((COALESCE(t.counterpart_name, ''::text) || ' '::text) || t.description)) AS nt,
            (- t.amount) AS v
           FROM v_tx t
          WHERE ((t.amount < (0)::numeric) AND (t.category_kind = 'despesa'::text) AND (t.month >= ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval))::date))
        ), base AS MATERIALIZED (
         SELECT m.mes,
            f.id,
            f.name,
            f.category_id,
            f.channel,
            f.payee_key,
            f.match_pattern
           FROM (meses m
             JOIN fixed_expenses f ON ((f.is_active AND (m.mes >= date_trunc('month'::text, (f.start_month)::timestamp with time zone)) AND ((f.end_month IS NULL) OR (m.mes <= date_trunc('month'::text, (f.end_month)::timestamp with time zone))))))
        ), pagos AS (
         SELECT b_1.mes,
            b_1.id,
            sum(t.v) AS pago
           FROM (base b_1
             JOIN tx t ON (((t.month = b_1.mes) AND (((b_1.payee_key IS NOT NULL) AND (t.pk = b_1.payee_key)) OR ((b_1.match_pattern IS NOT NULL) AND (t.nt ~~ (('%'::text || b_1.match_pattern) || '%'::text))) OR ((b_1.payee_key IS NULL) AND (b_1.match_pattern IS NULL) AND (t.category_id = b_1.category_id))))))
          GROUP BY b_1.mes, b_1.id
        )
 SELECT b.mes AS month,
    b.id AS fixed_expense_id,
    b.name,
    b.category_id,
    COALESCE(c.parent_id, c.id) AS group_id,
    b.channel,
    dv.amount AS devido,
    COALESCE(p.pago, (0)::numeric) AS pago
   FROM (((base b
     LEFT JOIN categories c ON ((c.id = b.category_id)))
     LEFT JOIN pagos p ON (((p.mes = b.mes) AND (p.id = b.id))))
     LEFT JOIN LATERAL ( SELECT v.amount
           FROM fixed_expense_values v
          WHERE ((v.fixed_expense_id = b.id) AND (v.valid_from <= b.mes))
          ORDER BY v.valid_from DESC
         LIMIT 1) dv ON (true));
