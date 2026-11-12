CREATE OR REPLACE FUNCTION public.derive_counterpart(p_description text, p_payment jsonb)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select coalesce(
    nullif(p_payment->'payer'->>'name',''),
    nullif(p_payment->'receiver'->>'name',''),
    nullif(trim(regexp_replace(split_part(p_description, '   ', 2), '^[0-9]{2}/[0-9]{2} ', '')), '')
  )
$function$
;
