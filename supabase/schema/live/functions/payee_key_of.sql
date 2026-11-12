CREATE OR REPLACE FUNCTION public.payee_key_of(p_counterpart text, p_description text)
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  select lower(trim(regexp_replace(regexp_replace(coalesce(nullif(p_counterpart,''), left(norm_text(p_description),30)),'(parc\s*)?[0-9/*]+',' ','gi'),'\s+',' ','g')))
$function$
;
