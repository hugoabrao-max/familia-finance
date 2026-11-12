create or replace view public.v_investments_latest with (security_invoker = on) as
 SELECT DISTINCT ON (provider_investment_id) provider_investment_id,
    name,
    type,
    subtype,
    balance,
    amount_invested,
    due_date,
    rate,
    rate_type,
    observed_at
   FROM investment_positions
  WHERE (observed_at >= (( SELECT max(investment_positions_1.observed_at) AS max
           FROM investment_positions investment_positions_1) - '01:00:00'::interval))
  ORDER BY provider_investment_id, observed_at DESC;
