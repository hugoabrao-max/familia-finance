create or replace view public.v_goals with (security_invoker = on) as
 SELECT id,
    name,
    target_amount,
    target_date,
    progress_source,
    current_amount,
    monthly_contribution,
    status,
    notes,
    created_at,
    updated_at,
        CASE progress_source
            WHEN 'manual'::text THEN COALESCE(current_amount, (0)::numeric)
            WHEN 'investimentos'::text THEN ( SELECT v_net_worth.investimentos
               FROM v_net_worth)
            ELSE ( SELECT (v_net_worth.poupanca + v_net_worth.investimentos)
               FROM v_net_worth)
        END AS progresso,
    round((((100)::numeric *
        CASE progress_source
            WHEN 'manual'::text THEN COALESCE(current_amount, (0)::numeric)
            WHEN 'investimentos'::text THEN ( SELECT v_net_worth.investimentos
               FROM v_net_worth)
            ELSE ( SELECT (v_net_worth.poupanca + v_net_worth.investimentos)
               FROM v_net_worth)
        END) / NULLIF(target_amount, (0)::numeric))) AS pct
   FROM goals g
  WHERE (status <> 'cancelada'::text);
