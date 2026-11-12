CREATE OR REPLACE FUNCTION public.fmt_br(v date, f text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$ select to_char(v, f) $function$
;

CREATE OR REPLACE FUNCTION public.fmt_br(v numeric, f text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$ select translate(to_char(v, f), ',.', '.,') $function$
;

CREATE OR REPLACE FUNCTION public.fmt_br(v timestamp with time zone, f text)
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$ select to_char(v, f) $function$
;

CREATE OR REPLACE FUNCTION public.fmt_br(v timestamp without time zone, f text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$ select to_char(v, f) $function$
;
