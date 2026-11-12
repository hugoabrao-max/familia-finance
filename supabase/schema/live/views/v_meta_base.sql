create or replace view public.v_meta_base with (security_invoker = on) as
 WITH per AS (
         SELECT ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval))::date AS ini,
            ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval))::date AS fim
        ), meses AS (
         SELECT (generate_series((per.ini)::timestamp with time zone, (per.fim)::timestamp with time zone, '1 mon'::interval))::date AS mes
           FROM per
        ), fe AS MATERIALIZED (
         SELECT fixed_expenses.id,
            fixed_expenses.category_id,
            fixed_expenses.payee_key,
            fixed_expenses.match_pattern
           FROM fixed_expenses
          WHERE fixed_expenses.is_active
        ), tx AS MATERIALIZED (
         SELECT t.month,
            t.group_id,
            t.category_id,
            (- t.amount) AS v,
            (COALESCE(t.installment_total, 1) > 1) AS parc,
            payee_key_of(t.counterpart_name, t.description) AS pk,
            norm_text(((COALESCE(t.counterpart_name, ''::text) || ' '::text) || t.description)) AS nt
           FROM v_tx t,
            per
          WHERE ((t.amount < (0)::numeric) AND (t.category_kind = 'despesa'::text) AND ((t.month >= per.ini) AND (t.month <= per.fim)))
        ), cls AS MATERIALIZED (
         SELECT tx.month,
            tx.group_id,
            tx.category_id,
            tx.v,
            tx.parc,
            tx.pk,
            tx.nt,
            (EXISTS ( SELECT 1
                   FROM fe
                  WHERE (((fe.payee_key IS NOT NULL) AND (fe.payee_key = tx.pk)) OR ((fe.match_pattern IS NOT NULL) AND (tx.nt ~~ (('%'::text || fe.match_pattern) || '%'::text))) OR ((fe.payee_key IS NULL) AND (fe.match_pattern IS NULL) AND (fe.category_id = tx.category_id))))) AS fixo
           FROM tx
        ), grupos AS (
         SELECT DISTINCT cls.group_id
           FROM cls
        ), mm AS (
         SELECT m.mes,
            g.group_id,
            COALESCE(sum(c.v) FILTER (WHERE ((NOT c.fixo) AND (NOT c.parc))), (0)::numeric) AS variavel,
            COALESCE(sum(c.v) FILTER (WHERE c.fixo), (0)::numeric) AS fixo,
            COALESCE(sum(c.v) FILTER (WHERE (c.parc AND (NOT c.fixo))), (0)::numeric) AS parcelas
           FROM ((meses m
             CROSS JOIN grupos g)
             LEFT JOIN cls c ON (((c.month = m.mes) AND (c.group_id = g.group_id))))
          GROUP BY m.mes, g.group_id
        )
 SELECT mm.group_id,
    cat.name AS nome,
    round((percentile_cont((0.5)::double precision) WITHIN GROUP (ORDER BY ((mm.variavel)::double precision)))::numeric, 2) AS variavel_mediana,
    round(avg(mm.variavel), 2) AS variavel_media,
    round(avg(mm.fixo), 2) AS fixo_media,
    round(avg(mm.parcelas), 2) AS parcelas_media,
    jsonb_object_agg(to_char((mm.mes)::timestamp with time zone, 'YYYY-MM'::text), round(mm.variavel)) AS variavel_por_mes
   FROM (mm
     LEFT JOIN categories cat ON ((cat.id = mm.group_id)))
  GROUP BY mm.group_id, cat.name;
