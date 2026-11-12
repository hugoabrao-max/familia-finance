create or replace view public.v_group_items with (security_invoker = on) as
 WITH m AS (
         SELECT ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval))::date AS ini,
            ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval))::date AS fim
        ), x AS (
         SELECT v.group_id,
            v.category_id,
            v.category_name,
            a.type,
            initcap(TRIM(BOTH FROM regexp_replace(regexp_replace(COALESCE(NULLIF(v.counterpart_name, ''::text), "left"(norm_text(v.description), 30)), '(parc\s*)?[0-9/*]+'::text, ' '::text, 'gi'::text), '\s+'::text, ' '::text, 'g'::text))) AS payee,
            v.month,
            v.amount,
            v.event_date
           FROM (v_tx v
             JOIN accounts a ON ((a.id = v.account_id))),
            m
          WHERE ((v.category_kind = 'despesa'::text) AND ((v.month >= m.ini) AND (v.month <= m.fim)))
        )
 SELECT group_id,
    category_id,
    max(category_name) AS category_name,
    lower(payee) AS payee_key,
    max(payee) AS payee,
        CASE
            WHEN (sum(amount) FILTER (WHERE (type = 'CREDIT'::text)) IS NULL) THEN 'conta'::text
            WHEN (sum(amount) FILTER (WHERE (type = 'BANK'::text)) IS NULL) THEN 'cartao'::text
            ELSE 'ambos'::text
        END AS canal,
    count(DISTINCT month) AS meses,
    count(*) AS n,
    round(((- sum(amount)) / (6)::numeric), 2) AS media_6m,
    round(((- sum(amount)) / (count(DISTINCT month))::numeric), 2) AS media_quando_ocorre,
    max(event_date) AS ultimo
   FROM x
  GROUP BY group_id, category_id, (lower(payee));
