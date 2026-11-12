CREATE OR REPLACE FUNCTION public.my_household()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select household_id from household_members where auth_user_id = auth.uid() limit 1
$function$
;
