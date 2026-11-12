alter table public.account_balance_history enable row level security;
alter table public.accounts enable row level security;
alter table public.alert_settings enable row level security;
alter table public.app_settings enable row level security;
alter table public.assets enable row level security;
alter table public.audit_logs enable row level security;
alter table public.backup_ids_20261106 enable row level security;
alter table public.backup_runs enable row level security;
alter table public.budgets enable row level security;
alter table public.card_bill_cycles enable row level security;
alter table public.card_bill_reference_lines enable row level security;
alter table public.card_holders enable row level security;
alter table public.card_statements enable row level security;
alter table public.categories enable row level security;
alter table public.category_flex enable row level security;
alter table public.classification_feedback enable row level security;
alter table public.classification_rules enable row level security;
alter table public.commitments enable row level security;
alter table public.connection_consents enable row level security;
alter table public.connections enable row level security;
alter table public.data_quality_issues enable row level security;
alter table public.financial_institutions enable row level security;
alter table public.financing_contracts enable row level security;
alter table public.financing_installments enable row level security;
alter table public.fixed_expense_values enable row level security;
alter table public.fixed_expenses enable row level security;
alter table public.fixed_items enable row level security;
alter table public.goals enable row level security;
alter table public.household_members enable row level security;
alter table public.households enable row level security;
alter table public.import_jobs enable row level security;
alter table public.investment_positions enable row level security;
alter table public.mcc_category_map enable row level security;
alter table public.monthly_closings enable row level security;
alter table public.plan_settings enable row level security;
alter table public.project_docs enable row level security;
alter table public.raw_transactions enable row level security;
alter table public.sim_scenarios enable row level security;
alter table public.sync_errors enable row level security;
alter table public.sync_jobs enable row level security;
alter table public.transaction_links enable row level security;
alter table public.transactions enable row level security;

create policy abh_select on public.account_balance_history as PERMISSIVE for SELECT to public
  using ((EXISTS ( SELECT 1
   FROM (accounts a
     JOIN connections c ON ((c.id = a.connection_id)))
  WHERE ((a.id = account_balance_history.account_id) AND (c.household_id = ( SELECT my_household() AS my_household))))));

create policy acc_select on public.accounts as PERMISSIVE for SELECT to public
  using ((EXISTS ( SELECT 1
   FROM connections c
  WHERE ((c.id = accounts.connection_id) AND (c.household_id = ( SELECT my_household() AS my_household))))));

create policy as_read on public.alert_settings as PERMISSIVE for SELECT to authenticated
  using (true);

create policy as_read on public.assets as PERMISSIVE for SELECT to authenticated
  using (true);

create policy as_write on public.assets as PERMISSIVE for ALL to authenticated
  using (can_edit())
  with check (can_edit());

create policy al_select on public.audit_logs as PERMISSIVE for SELECT to public
  using ((auth.uid() IS NOT NULL));

create policy br_select on public.backup_runs as PERMISSIVE for SELECT to public
  using ((auth.uid() IS NOT NULL));

create policy bg_read on public.budgets as PERMISSIVE for SELECT to authenticated
  using (true);

create policy bg_write on public.budgets as PERMISSIVE for ALL to authenticated
  using (can_edit())
  with check (can_edit());

create policy cbc_read on public.card_bill_cycles as PERMISSIVE for SELECT to authenticated
  using (true);

create policy cbrl_read on public.card_bill_reference_lines as PERMISSIVE for SELECT to authenticated
  using (true);

create policy ch_read on public.card_holders as PERMISSIVE for SELECT to authenticated
  using (true);

create policy cs_select on public.card_statements as PERMISSIVE for SELECT to public
  using ((EXISTS ( SELECT 1
   FROM (accounts a
     JOIN connections c ON ((c.id = a.connection_id)))
  WHERE ((a.id = card_statements.account_id) AND (c.household_id = ( SELECT my_household() AS my_household))))));

create policy cat_select on public.categories as PERMISSIVE for SELECT to public
  using ((( SELECT auth.uid() AS uid) IS NOT NULL));

create policy cf_read on public.category_flex as PERMISSIVE for SELECT to authenticated
  using (true);

create policy cf_write on public.category_flex as PERMISSIVE for ALL to authenticated
  using (can_edit())
  with check (can_edit());

create policy cf_select on public.classification_feedback as PERMISSIVE for SELECT to public
  using ((auth.uid() IS NOT NULL));

create policy cr_select on public.classification_rules as PERMISSIVE for SELECT to public
  using ((( SELECT auth.uid() AS uid) IS NOT NULL));

create policy cr_write on public.classification_rules as PERMISSIVE for ALL to public
  using (can_edit())
  with check (can_edit());

create policy cm_read on public.commitments as PERMISSIVE for SELECT to authenticated
  using (true);

create policy cm_write on public.commitments as PERMISSIVE for ALL to authenticated
  using (can_edit())
  with check (can_edit());

create policy cc_select on public.connection_consents as PERMISSIVE for SELECT to public
  using ((EXISTS ( SELECT 1
   FROM connections c
  WHERE ((c.id = connection_consents.connection_id) AND (c.household_id = ( SELECT my_household() AS my_household))))));

create policy conn_select on public.connections as PERMISSIVE for SELECT to public
  using ((household_id = ( SELECT my_household() AS my_household)));

create policy dq_select on public.data_quality_issues as PERMISSIVE for SELECT to public
  using ((auth.uid() IS NOT NULL));

create policy fi_select on public.financial_institutions as PERMISSIVE for SELECT to public
  using ((auth.uid() IS NOT NULL));

create policy fc_read on public.financing_contracts as PERMISSIVE for SELECT to authenticated
  using (true);

create policy fc_write on public.financing_contracts as PERMISSIVE for ALL to authenticated
  using (can_edit())
  with check (can_edit());

create policy fi2_read on public.financing_installments as PERMISSIVE for SELECT to authenticated
  using (true);

create policy fi2_write on public.financing_installments as PERMISSIVE for ALL to authenticated
  using (can_edit())
  with check (can_edit());

create policy fev_read on public.fixed_expense_values as PERMISSIVE for SELECT to authenticated
  using (true);

create policy fev_write on public.fixed_expense_values as PERMISSIVE for ALL to authenticated
  using (can_edit())
  with check (can_edit());

create policy fe_read on public.fixed_expenses as PERMISSIVE for SELECT to authenticated
  using (true);

create policy fe_write on public.fixed_expenses as PERMISSIVE for ALL to authenticated
  using (can_edit())
  with check (can_edit());

create policy fi_read on public.fixed_items as PERMISSIVE for SELECT to authenticated
  using (true);

create policy fi_write on public.fixed_items as PERMISSIVE for ALL to authenticated
  using (can_edit())
  with check (can_edit());

create policy gl_read on public.goals as PERMISSIVE for SELECT to authenticated
  using (true);

create policy gl_write on public.goals as PERMISSIVE for ALL to authenticated
  using (can_edit())
  with check (can_edit());

create policy hm_select on public.household_members as PERMISSIVE for SELECT to public
  using ((household_id = ( SELECT my_household() AS my_household)));

create policy hh_select on public.households as PERMISSIVE for SELECT to public
  using ((id = ( SELECT my_household() AS my_household)));

create policy ij_select on public.import_jobs as PERMISSIVE for SELECT to public
  using ((auth.uid() IS NOT NULL));

create policy ip_select on public.investment_positions as PERMISSIVE for SELECT to public
  using ((EXISTS ( SELECT 1
   FROM connections c
  WHERE ((c.id = investment_positions.connection_id) AND (c.household_id = ( SELECT my_household() AS my_household))))));

create policy mcc_read on public.mcc_category_map as PERMISSIVE for SELECT to authenticated
  using (true);

create policy mc_read on public.monthly_closings as PERMISSIVE for SELECT to authenticated
  using (true);

create policy ps_read on public.plan_settings as PERMISSIVE for SELECT to authenticated
  using (true);

create policy ps_write on public.plan_settings as PERMISSIVE for ALL to authenticated
  using (can_edit())
  with check (can_edit());

create policy pd_select on public.project_docs as PERMISSIVE for SELECT to public
  using ((auth.uid() IS NOT NULL));

create policy rt_select on public.raw_transactions as PERMISSIVE for SELECT to public
  using ((EXISTS ( SELECT 1
   FROM (accounts a
     JOIN connections c ON ((c.id = a.connection_id)))
  WHERE ((a.id = raw_transactions.account_id) AND (c.household_id = ( SELECT my_household() AS my_household))))));

create policy ss_read on public.sim_scenarios as PERMISSIVE for SELECT to authenticated
  using (true);

create policy ss_write on public.sim_scenarios as PERMISSIVE for ALL to authenticated
  using (can_edit())
  with check (can_edit());

create policy se_select on public.sync_errors as PERMISSIVE for SELECT to public
  using ((auth.uid() IS NOT NULL));

create policy sj_select on public.sync_jobs as PERMISSIVE for SELECT to public
  using ((auth.uid() IS NOT NULL));

create policy tl_select on public.transaction_links as PERMISSIVE for SELECT to public
  using ((auth.uid() IS NOT NULL));

create policy tx_select on public.transactions as PERMISSIVE for SELECT to public
  using ((EXISTS ( SELECT 1
   FROM (accounts a
     JOIN connections c ON ((c.id = a.connection_id)))
  WHERE ((a.id = transactions.account_id) AND (c.household_id = ( SELECT my_household() AS my_household))))));
