create or replace view public.v_daily_flow with (security_invoker = on) as
 SELECT event_date,
    account_subtype,
    sum(amount) FILTER (WHERE ((amount > (0)::numeric) AND (category_kind IS DISTINCT FROM 'transferencia'::text))) AS entradas,
    sum(amount) FILTER (WHERE ((amount < (0)::numeric) AND (category_kind IS DISTINCT FROM 'transferencia'::text))) AS saidas,
    count(*) AS n
   FROM v_tx
  GROUP BY event_date, account_subtype;
