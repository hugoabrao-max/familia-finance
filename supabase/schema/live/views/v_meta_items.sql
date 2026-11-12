create or replace view public.v_meta_items with (security_invoker = on) as
 WITH per AS (
         SELECT ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval))::date AS ini,
            (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date AS atual
        ), fe AS MATERIALIZED (
         SELECT fixed_expenses.category_id,
            fixed_expenses.payee_key,
            fixed_expenses.match_pattern
           FROM fixed_expenses
          WHERE fixed_expenses.is_active
        ), tx AS MATERIALIZED (
         SELECT t.month,
            t.group_id,
            t.category_id,
            t.category_name,
            a.type AS acc_type,
            (- t.amount) AS v,
            (COALESCE(t.installment_total, 1) > 1) AS parc,
            (COALESCE(t.installment_total, 1) > 1) AS parcelado,
            payee_key_of(t.counterpart_name, t.description) AS pk,
            norm_text(((COALESCE(t.counterpart_name, ''::text) || ' '::text) || t.description)) AS nt,
            initcap(TRIM(BOTH FROM regexp_replace(regexp_replace(COALESCE(NULLIF(t.counterpart_name, ''::text), "left"(t.description, 30)), '(parc\s*)?[0-9/*]+'::text, ' '::text, 'gi'::text), '\s+'::text, ' '::text, 'g'::text))) AS payee
           FROM (v_tx t
             JOIN accounts a ON ((a.id = t.account_id))),
            per per_1
          WHERE ((t.amount < (0)::numeric) AND (t.category_kind = 'despesa'::text) AND ((t.month >= per_1.ini) AND (t.month <= per_1.atual)))
        ), cls AS MATERIALIZED (
         SELECT tx.month,
            tx.group_id,
            tx.category_id,
            tx.category_name,
            tx.acc_type,
            tx.v,
            tx.parc,
            tx.parcelado,
            tx.pk,
            tx.nt,
            tx.payee
           FROM tx
          WHERE ((NOT tx.parc) AND (NOT (EXISTS ( SELECT 1
                   FROM fe
                  WHERE (((fe.payee_key IS NOT NULL) AND (fe.payee_key = tx.pk)) OR ((fe.match_pattern IS NOT NULL) AND (tx.nt ~~ (('%'::text || fe.match_pattern) || '%'::text))) OR ((fe.payee_key IS NULL) AND (fe.match_pattern IS NULL) AND (fe.category_id = tx.category_id)))))))
        )
 SELECT c.group_id,
    c.pk AS payee_key,
    max(c.payee) AS payee,
    max(c.category_name) AS category_name,
        CASE
            WHEN bool_and((c.acc_type = 'CREDIT'::text)) THEN 'cartao'::text
            WHEN bool_and((c.acc_type = 'BANK'::text)) THEN 'conta'::text
            ELSE 'ambos'::text
        END AS canal,
    count(DISTINCT c.month) FILTER (WHERE (c.month < per.atual)) AS meses,
    count(*) FILTER (WHERE (c.month < per.atual)) AS n,
    round(COALESCE(sum(c.v) FILTER (WHERE (c.month < per.atual)), (0)::numeric), 2) AS total_6m,
    round((COALESCE(sum(c.v) FILTER (WHERE (c.month < per.atual)), (0)::numeric) / (6)::numeric), 2) AS media_6m,
    round(COALESCE(sum(c.v) FILTER (WHERE (c.month = per.atual)), (0)::numeric), 2) AS mes_atual,
    bool_or(c.parcelado) AS tem_parcelado
   FROM cls c,
    per
  GROUP BY c.group_id, c.pk;
