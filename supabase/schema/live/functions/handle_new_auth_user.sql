CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid;
begin
  -- vínculo apenas por e-mail cadastrado em household_members (convite do owner/admin ou cadastro manual)
  select id into v_id from household_members where lower(email) = lower(new.email) and auth_user_id is null limit 1;
  if v_id is not null then
    update household_members set auth_user_id = new.id where id = v_id;
  end if;
  return new;
end $function$
;
