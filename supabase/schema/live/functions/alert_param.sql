CREATE OR REPLACE FUNCTION public.alert_param(k text)
 RETURNS numeric
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$ select value from alert_settings where key = k $function$
;
