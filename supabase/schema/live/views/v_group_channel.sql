create or replace view public.v_group_channel with (security_invoker = on) as
 WITH m AS (
         SELECT ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval))::date AS ini,
            ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval))::date AS fim
        )
 SELECT v.group_id,
    max(v.group_name) AS group_name,
    round(((- sum(v.amount) FILTER (WHERE (a.type = 'BANK'::text))) / (6)::numeric), 2) AS conta_mes,
    round(((- sum(v.amount) FILTER (WHERE (a.type = 'CREDIT'::text))) / (6)::numeric), 2) AS cartao_mes,
    round((((100)::numeric * sum(v.amount) FILTER (WHERE (a.type = 'CREDIT'::text))) / NULLIF(sum(v.amount), (0)::numeric))) AS pct_cartao
   FROM (v_tx v
     JOIN accounts a ON ((a.id = v.account_id))),
    m
  WHERE ((v.category_kind = 'despesa'::text) AND ((v.month >= m.ini) AND (v.month <= m.fim)))
  GROUP BY v.group_id;
