CREATE OR REPLACE FUNCTION public.norm_text(t text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select trim(regexp_replace(regexp_replace(lower(extensions.unaccent(coalesce(t,''))), '[0-9]', '', 'g'), '[^a-z*]+', ' ', 'g'))
$function$
;
