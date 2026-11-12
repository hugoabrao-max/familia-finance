alter view v_tx set (security_invoker = on);
alter view v_month_summary set (security_invoker = on);
alter view v_category_month set (security_invoker = on);
alter view v_daily_flow set (security_invoker = on);
alter view v_sync_status set (security_invoker = on);
-- função de leitura por membro: sem execute para anon
revoke execute on function set_transaction_category(uuid, text, boolean, text) from anon;
revoke execute on function classify_transactions(boolean) from anon, authenticated;
