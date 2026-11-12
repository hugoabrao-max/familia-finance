
-- Funções internas: só service_role/postgres (cron, Edge Functions)
revoke execute on function public.export_backup() from public, anon, authenticated;
revoke execute on function public.restore_backup_to_test(jsonb) from public, anon, authenticated;
revoke execute on function public.post_sync() from public, anon, authenticated;
revoke execute on function public.reconcile_all() from public, anon, authenticated;
revoke execute on function public.detect_duplicates() from public, anon, authenticated;
revoke execute on function public.refresh_card_cycles() from public, anon, authenticated;
revoke execute on function public.assign_card_competence() from public, anon, authenticated;
revoke execute on function public.classify_transactions(boolean) from public, anon, authenticated;
revoke execute on function public.handle_new_auth_user() from public, anon, authenticated;
-- Funções do app: só usuário logado (cada uma valida o membro internamente)
revoke execute on function public.set_transaction_category(uuid, text, boolean, text) from public, anon;
revoke execute on function public.close_month(date, text, boolean) from public, anon;
revoke execute on function public.reopen_month(date, text) from public, anon;
revoke execute on function public.month_close_check(date) from public, anon;
grant execute on function public.set_transaction_category(uuid, text, boolean, text) to authenticated;
grant execute on function public.close_month(date, text, boolean) to authenticated;
grant execute on function public.reopen_month(date, text) to authenticated;
grant execute on function public.month_close_check(date) to authenticated;
-- Auxiliares usadas nas políticas RLS: logado sim, anônimo não
revoke execute on function public.current_member() from public, anon;
revoke execute on function public.my_household() from public, anon;
revoke execute on function public.can_edit() from public, anon;
grant execute on function public.current_member() to authenticated;
grant execute on function public.my_household() to authenticated;
grant execute on function public.can_edit() to authenticated;
alter function public.alert_param(text) set search_path = public;
alter function public.classify_transactions(boolean) set search_path = public;

