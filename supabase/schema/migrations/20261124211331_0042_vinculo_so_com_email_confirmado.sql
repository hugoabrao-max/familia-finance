-- 0042: a conta só é ligada a um membro da família (por e-mail) depois que o e-mail é confirmado.
-- Antes, a ligação acontecia na criação da conta, mesmo sem confirmação: quem se cadastrasse primeiro com o e-mail de um
-- convite pendente ficava com a vaga. Contas criadas pelo convite (member-invite) já nascem confirmadas e continuam ligando
-- na hora. Nenhum dado alterado (hoje: 2 contas, ambas confirmadas e ligadas).
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid;
begin
  -- vínculo apenas por e-mail cadastrado em household_members (convite do owner/admin ou cadastro manual)
  -- v2 (24/11/2026): só com e-mail confirmado — roda na criação (contas criadas pelo convite já nascem confirmadas)
  -- e de novo quando a confirmação chega (gatilho on_auth_user_confirmed); quem se cadastrasse antes com o e-mail
  -- de um convite pendente não fica mais com a vaga
  if new.email_confirmed_at is null then return new; end if;
  select id into v_id from household_members where lower(email) = lower(new.email) and auth_user_id is null limit 1;
  if v_id is not null then
    update household_members set auth_user_id = new.id where id = v_id;
  end if;
  return new;
end $function$
;
drop trigger if exists on_auth_user_confirmed on auth.users;
create trigger on_auth_user_confirmed after update of email_confirmed_at on auth.users
  for each row when (old.email_confirmed_at is null and new.email_confirmed_at is not null)
  execute function public.handle_new_auth_user();
