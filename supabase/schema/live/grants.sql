-- public.alert_param(k text)
-- proacl: =X/postgres postgres=X/postgres anon=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.alert_param(k text) from public;
grant execute on function public.alert_param(k text) to public;
grant execute on function public.alert_param(k text) to anon;
grant execute on function public.alert_param(k text) to authenticated;
grant execute on function public.alert_param(k text) to service_role;

-- public.assign_card_competence() [SECURITY DEFINER]
-- proacl: postgres=X/postgres service_role=X/postgres
revoke all on function public.assign_card_competence() from public;
grant execute on function public.assign_card_competence() to service_role;

-- public.can_edit() [SECURITY DEFINER]
-- proacl: postgres=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.can_edit() from public;
grant execute on function public.can_edit() to authenticated;
grant execute on function public.can_edit() to service_role;

-- public.classify_transactions(p_only_unclassified boolean)
-- proacl: postgres=X/postgres service_role=X/postgres
revoke all on function public.classify_transactions(p_only_unclassified boolean) from public;
grant execute on function public.classify_transactions(p_only_unclassified boolean) to service_role;

-- public.close_month(p_month date, p_notes text, p_force boolean) [SECURITY DEFINER]
-- proacl: postgres=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.close_month(p_month date, p_notes text, p_force boolean) from public;
grant execute on function public.close_month(p_month date, p_notes text, p_force boolean) to authenticated;
grant execute on function public.close_month(p_month date, p_notes text, p_force boolean) to service_role;

-- public.current_member() [SECURITY DEFINER]
-- proacl: postgres=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.current_member() from public;
grant execute on function public.current_member() to authenticated;
grant execute on function public.current_member() to service_role;

-- public.derive_counterpart(p_description text, p_payment jsonb)
-- proacl: =X/postgres postgres=X/postgres anon=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.derive_counterpart(p_description text, p_payment jsonb) from public;
grant execute on function public.derive_counterpart(p_description text, p_payment jsonb) to public;
grant execute on function public.derive_counterpart(p_description text, p_payment jsonb) to anon;
grant execute on function public.derive_counterpart(p_description text, p_payment jsonb) to authenticated;
grant execute on function public.derive_counterpart(p_description text, p_payment jsonb) to service_role;

-- public.detect_duplicates() [SECURITY DEFINER]
-- proacl: postgres=X/postgres service_role=X/postgres
revoke all on function public.detect_duplicates() from public;
grant execute on function public.detect_duplicates() to service_role;

-- public.export_backup() [SECURITY DEFINER]
-- proacl: postgres=X/postgres service_role=X/postgres
revoke all on function public.export_backup() from public;
grant execute on function public.export_backup() to service_role;

-- public.fmt_br(v date, f text)
-- proacl: =X/postgres postgres=X/postgres anon=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.fmt_br(v date, f text) from public;
grant execute on function public.fmt_br(v date, f text) to public;
grant execute on function public.fmt_br(v date, f text) to anon;
grant execute on function public.fmt_br(v date, f text) to authenticated;
grant execute on function public.fmt_br(v date, f text) to service_role;

-- public.fmt_br(v numeric, f text)
-- proacl: =X/postgres postgres=X/postgres anon=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.fmt_br(v numeric, f text) from public;
grant execute on function public.fmt_br(v numeric, f text) to public;
grant execute on function public.fmt_br(v numeric, f text) to anon;
grant execute on function public.fmt_br(v numeric, f text) to authenticated;
grant execute on function public.fmt_br(v numeric, f text) to service_role;

-- public.fmt_br(v timestamp with time zone, f text)
-- proacl: =X/postgres postgres=X/postgres anon=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.fmt_br(v timestamp with time zone, f text) from public;
grant execute on function public.fmt_br(v timestamp with time zone, f text) to public;
grant execute on function public.fmt_br(v timestamp with time zone, f text) to anon;
grant execute on function public.fmt_br(v timestamp with time zone, f text) to authenticated;
grant execute on function public.fmt_br(v timestamp with time zone, f text) to service_role;

-- public.fmt_br(v timestamp without time zone, f text)
-- proacl: =X/postgres postgres=X/postgres anon=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.fmt_br(v timestamp without time zone, f text) from public;
grant execute on function public.fmt_br(v timestamp without time zone, f text) to public;
grant execute on function public.fmt_br(v timestamp without time zone, f text) to anon;
grant execute on function public.fmt_br(v timestamp without time zone, f text) to authenticated;
grant execute on function public.fmt_br(v timestamp without time zone, f text) to service_role;

-- public.handle_new_auth_user() [SECURITY DEFINER]
-- proacl: postgres=X/postgres service_role=X/postgres
revoke all on function public.handle_new_auth_user() from public;
grant execute on function public.handle_new_auth_user() to service_role;

-- public.month_close_check(p_month date)
-- proacl: postgres=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.month_close_check(p_month date) from public;
grant execute on function public.month_close_check(p_month date) to authenticated;
grant execute on function public.month_close_check(p_month date) to service_role;

-- public.my_household() [SECURITY DEFINER]
-- proacl: postgres=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.my_household() from public;
grant execute on function public.my_household() to authenticated;
grant execute on function public.my_household() to service_role;

-- public.norm_text(t text)
-- proacl: =X/postgres postgres=X/postgres anon=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.norm_text(t text) from public;
grant execute on function public.norm_text(t text) to public;
grant execute on function public.norm_text(t text) to anon;
grant execute on function public.norm_text(t text) to authenticated;
grant execute on function public.norm_text(t text) to service_role;

-- public.payee_key_of(p_counterpart text, p_description text)
-- proacl: =X/postgres postgres=X/postgres anon=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.payee_key_of(p_counterpart text, p_description text) from public;
grant execute on function public.payee_key_of(p_counterpart text, p_description text) to public;
grant execute on function public.payee_key_of(p_counterpart text, p_description text) to anon;
grant execute on function public.payee_key_of(p_counterpart text, p_description text) to authenticated;
grant execute on function public.payee_key_of(p_counterpart text, p_description text) to service_role;

-- public.post_sync() [SECURITY DEFINER]
-- proacl: postgres=X/postgres service_role=X/postgres
revoke all on function public.post_sync() from public;
grant execute on function public.post_sync() to service_role;

-- public.reconcile_all() [SECURITY DEFINER]
-- proacl: postgres=X/postgres service_role=X/postgres
revoke all on function public.reconcile_all() from public;
grant execute on function public.reconcile_all() to service_role;

-- public.refresh_card_cycles() [SECURITY DEFINER]
-- proacl: postgres=X/postgres service_role=X/postgres
revoke all on function public.refresh_card_cycles() from public;
grant execute on function public.refresh_card_cycles() to service_role;

-- public.reopen_month(p_month date, p_reason text) [SECURITY DEFINER]
-- proacl: postgres=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.reopen_month(p_month date, p_reason text) from public;
grant execute on function public.reopen_month(p_month date, p_reason text) to authenticated;
grant execute on function public.reopen_month(p_month date, p_reason text) to service_role;

-- public.restore_backup_to_test(p jsonb) [SECURITY DEFINER]
-- proacl: postgres=X/postgres service_role=X/postgres
revoke all on function public.restore_backup_to_test(p jsonb) from public;
grant execute on function public.restore_backup_to_test(p jsonb) to service_role;

-- public.set_transaction_category(p_tx uuid, p_category text, p_create_rule boolean, p_reason text) [SECURITY DEFINER]
-- proacl: postgres=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.set_transaction_category(p_tx uuid, p_category text, p_create_rule boolean, p_reason text) from public;
grant execute on function public.set_transaction_category(p_tx uuid, p_category text, p_create_rule boolean, p_reason text) to authenticated;
grant execute on function public.set_transaction_category(p_tx uuid, p_category text, p_create_rule boolean, p_reason text) to service_role;

-- public.set_updated_at()
-- proacl: =X/postgres postgres=X/postgres anon=X/postgres authenticated=X/postgres service_role=X/postgres
revoke all on function public.set_updated_at() from public;
grant execute on function public.set_updated_at() to public;
grant execute on function public.set_updated_at() to anon;
grant execute on function public.set_updated_at() to authenticated;
grant execute on function public.set_updated_at() to service_role;
