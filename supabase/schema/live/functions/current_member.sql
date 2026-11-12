CREATE OR REPLACE FUNCTION public.current_member()
 RETURNS household_members
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select * from household_members where auth_user_id = auth.uid() limit 1
$function$
;
