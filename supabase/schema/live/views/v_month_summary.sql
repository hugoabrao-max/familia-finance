create or replace view public.v_month_summary with (security_invoker = on) as
 SELECT month,
    sum(amount) FILTER (WHERE (category_kind = 'receita'::text)) AS receitas,
    sum(amount) FILTER (WHERE ((category_kind = 'despesa'::text) OR (category_kind IS NULL))) AS despesas,
    sum(amount) FILTER (WHERE (category_kind = 'investimento'::text)) AS investimentos,
    (sum(amount) FILTER (WHERE (category_kind = 'receita'::text)) + sum(amount) FILTER (WHERE ((category_kind = 'despesa'::text) OR (category_kind IS NULL)))) AS resultado,
    count(*) FILTER (WHERE (review_status = 'pending'::text)) AS pendentes,
    sum(abs(amount)) FILTER (WHERE (review_status = 'pending'::text)) AS valor_pendente
   FROM v_tx
  WHERE (category_kind IS DISTINCT FROM 'transferencia'::text)
  GROUP BY month;
