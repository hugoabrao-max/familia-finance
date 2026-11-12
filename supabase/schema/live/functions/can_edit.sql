CREATE OR REPLACE FUNCTION public.can_edit()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce((select role in ('owner','admin','member') from household_members where auth_user_id = auth.uid() limit 1), false)
$function$
;
