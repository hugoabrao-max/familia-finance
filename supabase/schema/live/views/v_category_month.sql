create or replace view public.v_category_month with (security_invoker = on) as
 SELECT month,
    group_id,
    group_name,
    category_id,
    category_name,
    category_kind,
    count(*) AS n,
    sum(amount) AS total
   FROM v_tx
  WHERE (category_kind IS DISTINCT FROM 'transferencia'::text)
  GROUP BY month, group_id, group_name, category_id, category_name, category_kind;
