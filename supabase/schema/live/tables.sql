create table public.account_balance_history (
  id bigint not null default nextval('account_balance_history_id_seq'::regclass),
  account_id uuid not null,
  balance numeric(14,2) not null,
  observed_at timestamp with time zone not null default now(),
  constraint account_balance_history_pkey PRIMARY KEY (id),
  constraint account_balance_history_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);
CREATE INDEX account_balance_history_account_id_observed_at_idx ON public.account_balance_history USING btree (account_id, observed_at DESC);

create table public.accounts (
  id uuid not null default gen_random_uuid(),
  connection_id uuid not null,
  provider_account_id text not null,
  type text not null,
  subtype text,
  name text,
  marketing_name text,
  number text,
  owner text,
  currency text not null default 'BRL'::text,
  balance numeric(14,2),
  credit_limit numeric(14,2),
  available_credit_limit numeric(14,2),
  bill_due_day integer,
  bill_closing_day integer,
  tax_number text,
  is_active boolean not null default true,
  raw jsonb,
  balance_observed_at timestamp with time zone,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint accounts_pkey PRIMARY KEY (id),
  constraint accounts_provider_account_id_key UNIQUE (provider_account_id),
  constraint accounts_connection_id_fkey FOREIGN KEY (connection_id) REFERENCES connections(id) ON DELETE CASCADE
);

create table public.alert_settings (
  key text not null,
  value numeric not null,
  note text,
  constraint alert_settings_pkey PRIMARY KEY (key)
);

create table public.app_settings (
  key text not null,
  value text not null,
  updated_at timestamp with time zone not null default now(),
  constraint app_settings_pkey PRIMARY KEY (key)
);

create table public.assets (
  id text not null,
  nome text not null,
  tipo text not null default 'imovel'::text,
  valor numeric(14,2) not null,
  valor_fonte text,
  valor_em date,
  financing_id text,
  is_active boolean not null default true,
  updated_at timestamp with time zone not null default now(),
  constraint assets_pkey PRIMARY KEY (id),
  constraint assets_financing_id_fkey FOREIGN KEY (financing_id) REFERENCES financing_contracts(id)
);

create table public.audit_logs (
  id bigint not null default nextval('audit_logs_id_seq'::regclass),
  table_name text not null,
  row_id text not null,
  action text not null,
  actor uuid,
  actor_label text,
  before jsonb,
  after jsonb,
  created_at timestamp with time zone not null default now(),
  constraint audit_logs_pkey PRIMARY KEY (id),
  constraint audit_logs_actor_fkey FOREIGN KEY (actor) REFERENCES household_members(id)
);

create table public.backup_ids_20261106 (
  tbl text,
  id uuid,
  ref text,
  account_id uuid
);

create table public.backup_runs (
  id bigint not null default nextval('backup_runs_id_seq'::regclass),
  started_at timestamp with time zone not null default now(),
  status text not null,
  object_key text,
  bytes bigint,
  sha256 text,
  tables jsonb,
  note text,
  constraint backup_runs_pkey PRIMARY KEY (id)
);

create table public.budgets (
  group_id text not null,
  month date not null default '1900-01-01'::date,
  amount numeric not null,
  source text not null default 'proposta'::text,
  basis jsonb,
  updated_at timestamp with time zone not null default now(),
  constraint budgets_pkey PRIMARY KEY (group_id, month),
  constraint budgets_group_id_fkey FOREIGN KEY (group_id) REFERENCES categories(id),
  constraint budgets_amount_check CHECK ((amount >= (0)::numeric)),
  constraint budgets_source_check CHECK ((source = ANY (ARRAY['proposta'::text, 'hugo'::text])))
);

create table public.card_bill_cycles (
  account_id uuid not null,
  closing_date date not null,
  due_date date,
  source text not null,
  superseded boolean not null default false,
  pdf_total numeric,
  paid_amount numeric,
  paid_transaction_id uuid,
  updated_at timestamp with time zone not null default now(),
  constraint card_bill_cycles_pkey PRIMARY KEY (account_id, closing_date),
  constraint card_bill_cycles_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id),
  constraint card_bill_cycles_source_check CHECK ((source = ANY (ARRAY['pdf'::text, 'pluggy_parcelas'::text, 'estimado'::text])))
);

create table public.card_bill_reference_lines (
  id bigint not null default nextval('card_bill_reference_lines_id_seq'::regclass),
  closing_date date not null,
  tx_date date not null,
  amount_cents bigint not null,
  card_last4 text not null,
  inst_n integer,
  inst_t integer,
  kind text not null,
  matched_tx uuid,
  source text not null default 'pdf_v18'::text,
  constraint card_bill_reference_lines_pkey PRIMARY KEY (id)
);

create table public.card_holders (
  card_last4 text not null,
  holder_name text not null,
  kind text,
  constraint card_holders_pkey PRIMARY KEY (card_last4)
);

create table public.card_statements (
  id uuid not null default gen_random_uuid(),
  account_id uuid not null,
  provider_bill_id text not null,
  due_date date,
  closing_date date,
  total_amount numeric(14,2),
  minimum_payment numeric(14,2),
  allows_installments boolean,
  finance_charges jsonb,
  raw jsonb,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  import_job_id uuid,
  paid_transaction_id uuid,
  constraint card_statements_pkey PRIMARY KEY (id),
  constraint card_statements_provider_bill_id_key UNIQUE (provider_bill_id),
  constraint card_statements_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
  constraint card_statements_import_job_id_fkey FOREIGN KEY (import_job_id) REFERENCES import_jobs(id),
  constraint card_statements_paid_transaction_id_fkey FOREIGN KEY (paid_transaction_id) REFERENCES transactions(id)
);

create table public.categories (
  id text not null,
  parent_id text,
  name text not null,
  kind text not null,
  sort integer not null default 100,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  constraint categories_pkey PRIMARY KEY (id),
  constraint categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES categories(id),
  constraint categories_kind_check CHECK ((kind = ANY (ARRAY['receita'::text, 'despesa'::text, 'transferencia'::text, 'investimento'::text, 'divida'::text])))
);

create table public.category_flex (
  group_id text not null,
  classe text not null,
  max_cut_pct numeric not null,
  source text not null default 'proposta'::text,
  updated_at timestamp with time zone not null default now(),
  constraint category_flex_pkey PRIMARY KEY (group_id),
  constraint category_flex_group_id_fkey FOREIGN KEY (group_id) REFERENCES categories(id),
  constraint category_flex_classe_check CHECK ((classe = ANY (ARRAY['fixa'::text, 'essencial'::text, 'ajustavel'::text, 'discricionaria'::text]))),
  constraint category_flex_max_cut_pct_check CHECK (((max_cut_pct >= (0)::numeric) AND (max_cut_pct <= (100)::numeric))),
  constraint category_flex_source_check CHECK ((source = ANY (ARRAY['proposta'::text, 'hugo'::text])))
);

create table public.classification_feedback (
  id bigint not null default nextval('classification_feedback_id_seq'::regclass),
  transaction_id uuid not null,
  previous_category_id text,
  new_category_id text,
  previous_source text,
  changed_by uuid,
  reason text,
  created_at timestamp with time zone not null default now(),
  constraint classification_feedback_pkey PRIMARY KEY (id),
  constraint classification_feedback_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES household_members(id),
  constraint classification_feedback_new_category_id_fkey FOREIGN KEY (new_category_id) REFERENCES categories(id),
  constraint classification_feedback_previous_category_id_fkey FOREIGN KEY (previous_category_id) REFERENCES categories(id),
  constraint classification_feedback_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
);

create table public.classification_rules (
  id uuid not null default gen_random_uuid(),
  rule_type text not null,
  pattern text not null,
  category_id text not null,
  origin text not null,
  confidence numeric(4,3) not null default 0.800,
  priority integer not null default 100,
  example text,
  is_active boolean not null default true,
  history jsonb not null default '[]'::jsonb,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint classification_rules_pkey PRIMARY KEY (id),
  constraint classification_rules_rule_type_pattern_key UNIQUE (rule_type, pattern),
  constraint classification_rules_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id),
  constraint classification_rules_origin_check CHECK ((origin = ANY (ARRAY['usuario'::text, 'sugestao_ia'::text, 'sistema'::text, 'v18_usuario'::text, 'v18_sugestao_ia'::text]))),
  constraint classification_rules_rule_type_check CHECK ((rule_type = ANY (ARRAY['merchant_contains'::text, 'payee_name'::text, 'description_regex'::text, 'system'::text])))
);

create table public.commitments (
  id uuid not null default gen_random_uuid(),
  name text not null,
  category_id text,
  kind text not null,
  match_pattern text,
  monthly_amount numeric,
  installments_paid integer,
  installments_total integer,
  end_date date,
  outstanding_balance numeric,
  outstanding_at date,
  source text not null default 'detectado'::text,
  notes text,
  is_active boolean not null default true,
  updated_at timestamp with time zone not null default now(),
  constraint commitments_pkey PRIMARY KEY (id),
  constraint commitments_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id),
  constraint commitments_kind_check CHECK ((kind = ANY (ARRAY['financiamento'::text, 'parcelamento'::text, 'fixo'::text]))),
  constraint commitments_source_check CHECK ((source = ANY (ARRAY['detectado'::text, 'manual'::text, 'hugo'::text])))
);

create table public.connection_consents (
  id uuid not null default gen_random_uuid(),
  connection_id uuid not null,
  consent_expires_at timestamp with time zone,
  status text,
  observed_at timestamp with time zone not null default now(),
  constraint connection_consents_pkey PRIMARY KEY (id),
  constraint connection_consents_connection_id_fkey FOREIGN KEY (connection_id) REFERENCES connections(id) ON DELETE CASCADE
);

create table public.connections (
  id uuid not null default gen_random_uuid(),
  household_id uuid not null,
  holder_member_id uuid,
  provider text not null default 'pluggy'::text,
  provider_item_id text not null,
  connector_id integer,
  connector_name text,
  institution_id uuid,
  status text,
  execution_status text,
  status_detail jsonb,
  consent_expires_at timestamp with time zone,
  provider_updated_at timestamp with time zone,
  last_sync_at timestamp with time zone,
  is_active boolean not null default true,
  raw jsonb,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint connections_pkey PRIMARY KEY (id),
  constraint connections_provider_item_id_key UNIQUE (provider_item_id),
  constraint connections_holder_member_id_fkey FOREIGN KEY (holder_member_id) REFERENCES household_members(id),
  constraint connections_household_id_fkey FOREIGN KEY (household_id) REFERENCES households(id),
  constraint connections_institution_id_fkey FOREIGN KEY (institution_id) REFERENCES financial_institutions(id)
);

create table public.data_quality_issues (
  id bigint not null default nextval('data_quality_issues_id_seq'::regclass),
  kind text not null,
  severity text not null default 'medium'::text,
  transaction_id uuid,
  account_id uuid,
  detail jsonb,
  status text not null default 'open'::text,
  created_at timestamp with time zone not null default now(),
  constraint data_quality_issues_pkey PRIMARY KEY (id),
  constraint data_quality_issues_kind_transaction_id_key UNIQUE (kind, transaction_id),
  constraint data_quality_issues_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
  constraint data_quality_issues_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
  constraint data_quality_issues_status_check CHECK ((status = ANY (ARRAY['open'::text, 'resolved'::text, 'ignored'::text])))
);

create table public.financial_institutions (
  id uuid not null default gen_random_uuid(),
  name text not null,
  compe_code text,
  provider_connector_id integer,
  constraint financial_institutions_pkey PRIMARY KEY (id),
  constraint financial_institutions_name_key UNIQUE (name)
);

create table public.financing_contracts (
  id text not null,
  nome text not null,
  banco text,
  contrato text,
  commitment_id uuid,
  data_contrato date,
  valor_financiado numeric(14,2),
  sistema text,
  indexador text,
  taxa_efetiva_aa numeric(8,4),
  taxa_nominal_aa numeric(8,4),
  prazo_total integer,
  dia_vencimento integer,
  saldo_devedor numeric(14,2),
  saldo_em date,
  parcelas_pagas integer,
  parcelas_restantes integer,
  ultima_parcela date,
  amortizacao_mensal numeric(14,2),
  total_a_pagar numeric(14,2),
  juros_a_pagar numeric(14,2),
  seguros_tarifas_a_pagar numeric(14,2),
  participacao jsonb,
  fonte text,
  updated_at timestamp with time zone not null default now(),
  constraint financing_contracts_pkey PRIMARY KEY (id),
  constraint financing_contracts_commitment_id_fkey FOREIGN KEY (commitment_id) REFERENCES commitments(id)
);

create table public.financing_installments (
  contract_id text not null,
  n integer not null,
  due_date date not null,
  valor numeric(14,2) not null,
  saldo_apos numeric(14,2),
  pago boolean not null default false,
  constraint financing_installments_pkey PRIMARY KEY (contract_id, n),
  constraint financing_installments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES financing_contracts(id)
);

create table public.fixed_expense_values (
  id uuid not null default gen_random_uuid(),
  fixed_expense_id uuid not null,
  valid_from date not null,
  amount numeric(14,2) not null,
  note text,
  created_at timestamp with time zone not null default now(),
  created_by uuid,
  constraint fixed_expense_values_pkey PRIMARY KEY (id),
  constraint fixed_expense_values_fixed_expense_id_valid_from_key UNIQUE (fixed_expense_id, valid_from),
  constraint fixed_expense_values_fixed_expense_id_fkey FOREIGN KEY (fixed_expense_id) REFERENCES fixed_expenses(id),
  constraint fixed_expense_values_amount_check CHECK ((amount >= (0)::numeric))
);

create table public.fixed_expenses (
  id uuid not null default gen_random_uuid(),
  name text not null,
  category_id text not null,
  payee_key text,
  match_pattern text,
  channel text not null default 'conta'::text,
  due_day integer,
  start_month date not null default (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date,
  end_month date,
  is_active boolean not null default true,
  commitment_id uuid,
  notes text,
  source text not null default 'hugo'::text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  updated_by uuid,
  constraint fixed_expenses_pkey PRIMARY KEY (id),
  constraint fixed_expenses_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id),
  constraint fixed_expenses_commitment_id_fkey FOREIGN KEY (commitment_id) REFERENCES commitments(id),
  constraint fixed_expenses_channel_check CHECK ((channel = ANY (ARRAY['conta'::text, 'cartao'::text]))),
  constraint fixed_expenses_due_day_check CHECK (((due_day >= 1) AND (due_day <= 31)))
);

create table public.fixed_items (
  group_id text not null,
  payee_key text not null,
  is_fixed boolean not null,
  note text,
  updated_at timestamp with time zone not null default now(),
  updated_by uuid,
  constraint fixed_items_pkey PRIMARY KEY (group_id, payee_key)
);

create table public.goals (
  id uuid not null default gen_random_uuid(),
  name text not null,
  target_amount numeric not null,
  target_date date,
  progress_source text not null default 'manual'::text,
  current_amount numeric default 0,
  monthly_contribution numeric,
  status text not null default 'proposta'::text,
  notes text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint goals_pkey PRIMARY KEY (id),
  constraint goals_progress_source_check CHECK ((progress_source = ANY (ARRAY['manual'::text, 'investimentos'::text, 'poupanca_investimentos'::text]))),
  constraint goals_status_check CHECK ((status = ANY (ARRAY['proposta'::text, 'ativa'::text, 'concluida'::text, 'cancelada'::text])))
);

create table public.household_members (
  id uuid not null default gen_random_uuid(),
  household_id uuid not null,
  display_name text not null,
  role text not null default 'member'::text,
  auth_user_id uuid,
  created_at timestamp with time zone not null default now(),
  email text,
  constraint household_members_pkey PRIMARY KEY (id),
  constraint household_members_auth_user_id_key UNIQUE (auth_user_id),
  constraint household_members_email_key UNIQUE (email),
  constraint household_members_household_id_fkey FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE,
  constraint household_members_role_check CHECK ((role = ANY (ARRAY['owner'::text, 'admin'::text, 'member'::text, 'viewer'::text])))
);

create table public.households (
  id uuid not null default gen_random_uuid(),
  name text not null,
  created_at timestamp with time zone not null default now(),
  constraint households_pkey PRIMARY KEY (id)
);

create table public.import_jobs (
  id uuid not null default gen_random_uuid(),
  source text not null,
  source_ref text not null,
  file_name text,
  doc_type text,
  period text,
  account_id uuid,
  reconciliation jsonb,
  status text not null default 'IMPORTED'::text,
  rows_imported integer default 0,
  imported_at timestamp with time zone not null default now(),
  constraint import_jobs_pkey PRIMARY KEY (id),
  constraint import_jobs_source_ref_key UNIQUE (source_ref),
  constraint import_jobs_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id)
);

create table public.investment_positions (
  id uuid not null default gen_random_uuid(),
  connection_id uuid not null,
  provider_investment_id text not null,
  name text,
  type text,
  subtype text,
  balance numeric(14,2),
  amount_invested numeric(14,2),
  rate numeric(10,4),
  rate_type text,
  due_date date,
  raw jsonb,
  observed_at timestamp with time zone not null default now(),
  constraint investment_positions_pkey PRIMARY KEY (id),
  constraint investment_positions_provider_investment_id_observed_at_key UNIQUE (provider_investment_id, observed_at),
  constraint investment_positions_connection_id_fkey FOREIGN KEY (connection_id) REFERENCES connections(id) ON DELETE CASCADE
);
CREATE INDEX investment_positions_connection_id_observed_at_idx ON public.investment_positions USING btree (connection_id, observed_at DESC);

create table public.mcc_category_map (
  mcc integer not null,
  category_id text not null,
  note text,
  constraint mcc_category_map_pkey PRIMARY KEY (mcc),
  constraint mcc_category_map_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id)
);

create table public.monthly_closings (
  month date not null,
  status text not null default 'fechado'::text,
  snapshot jsonb not null,
  checklist jsonb not null,
  notes text,
  closed_at timestamp with time zone not null default now(),
  closed_by uuid,
  history jsonb not null default '[]'::jsonb,
  constraint monthly_closings_pkey PRIMARY KEY (month),
  constraint monthly_closings_status_check CHECK ((status = ANY (ARRAY['fechado'::text, 'reaberto'::text])))
);

create table public.plan_settings (
  key text not null,
  value numeric,
  text_value text,
  updated_at timestamp with time zone not null default now(),
  updated_by uuid,
  constraint plan_settings_pkey PRIMARY KEY (key)
);

create table public.project_docs (
  name text not null,
  content text not null,
  updated_at timestamp with time zone not null default now(),
  updated_by text,
  constraint project_docs_pkey PRIMARY KEY (name)
);

create table public.raw_transactions (
  id uuid not null default gen_random_uuid(),
  account_id uuid not null,
  provider_tx_id text not null,
  payload jsonb not null,
  payload_hash text not null,
  first_seen_at timestamp with time zone not null default now(),
  last_seen_at timestamp with time zone not null default now(),
  changed_count integer not null default 0,
  missing_since timestamp with time zone,
  constraint raw_transactions_pkey PRIMARY KEY (id),
  constraint raw_transactions_provider_tx_id_key UNIQUE (provider_tx_id),
  constraint raw_transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);
CREATE INDEX raw_transactions_account_id_last_seen_at_idx ON public.raw_transactions USING btree (account_id, last_seen_at);

create table public.sim_scenarios (
  id uuid not null default gen_random_uuid(),
  name text not null,
  params jsonb not null,
  created_by uuid,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint sim_scenarios_pkey PRIMARY KEY (id)
);

create table public.sync_errors (
  id bigint not null default nextval('sync_errors_id_seq'::regclass),
  sync_job_id uuid,
  connection_id uuid,
  account_id uuid,
  stage text not null,
  message text not null,
  detail jsonb,
  created_at timestamp with time zone not null default now(),
  constraint sync_errors_pkey PRIMARY KEY (id),
  constraint sync_errors_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id),
  constraint sync_errors_connection_id_fkey FOREIGN KEY (connection_id) REFERENCES connections(id),
  constraint sync_errors_sync_job_id_fkey FOREIGN KEY (sync_job_id) REFERENCES sync_jobs(id) ON DELETE CASCADE
);

create table public.sync_jobs (
  id uuid not null default gen_random_uuid(),
  trigger text not null default 'cron'::text,
  started_at timestamp with time zone not null default now(),
  finished_at timestamp with time zone,
  status text not null default 'RUNNING'::text,
  connections_total integer default 0,
  accounts_total integer default 0,
  tx_fetched integer default 0,
  tx_new integer default 0,
  tx_updated integer default 0,
  bills_upserted integer default 0,
  investments_upserted integer default 0,
  summary jsonb,
  constraint sync_jobs_pkey PRIMARY KEY (id)
);

create table public.transaction_links (
  id uuid not null default gen_random_uuid(),
  kind text not null,
  tx_a uuid not null,
  tx_b uuid,
  statement_id uuid,
  confidence numeric(4,3) not null,
  method text not null,
  status text not null default 'auto'::text,
  note text,
  created_at timestamp with time zone not null default now(),
  constraint transaction_links_pkey PRIMARY KEY (id),
  constraint transaction_links_kind_tx_a_tx_b_key UNIQUE (kind, tx_a, tx_b),
  constraint transaction_links_statement_id_fkey FOREIGN KEY (statement_id) REFERENCES card_statements(id) ON DELETE CASCADE,
  constraint transaction_links_tx_a_fkey FOREIGN KEY (tx_a) REFERENCES transactions(id) ON DELETE CASCADE,
  constraint transaction_links_tx_b_fkey FOREIGN KEY (tx_b) REFERENCES transactions(id) ON DELETE CASCADE,
  constraint transaction_links_kind_check CHECK ((kind = ANY (ARRAY['transfer'::text, 'card_payment'::text, 'refund'::text, 'duplicate'::text, 'installment_group'::text]))),
  constraint transaction_links_status_check CHECK ((status = ANY (ARRAY['auto'::text, 'confirmed'::text, 'rejected'::text])))
);
CREATE INDEX transaction_links_tx_a_idx ON public.transaction_links USING btree (tx_a);
CREATE INDEX transaction_links_tx_b_idx ON public.transaction_links USING btree (tx_b);

create table public.transactions (
  id uuid not null default gen_random_uuid(),
  account_id uuid not null,
  raw_transaction_id uuid,
  source text not null default 'pluggy'::text,
  source_ref text,
  event_date date not null,
  event_at timestamp with time zone,
  amount numeric(14,2) not null,
  currency text not null default 'BRL'::text,
  description text not null,
  description_raw text,
  provider_code text,
  type text,
  status text not null default 'POSTED'::text,
  operation_type text,
  payment_data jsonb,
  merchant jsonb,
  installment_number integer,
  installment_total integer,
  bill_closing_date date,
  bill_forecast_date date,
  balance_after numeric(14,2),
  provider_category text,
  is_deleted_at_source boolean not null default false,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  category_id text,
  category_source text,
  category_confidence numeric(4,3),
  rule_id uuid,
  review_status text not null default 'auto'::text,
  card_last4 text,
  holder_name text,
  competence_month date,
  import_job_id uuid,
  counterpart_name text,
  reconciliation text,
  original_amount numeric,
  original_currency text,
  constraint transactions_pkey PRIMARY KEY (id),
  constraint transactions_source_source_ref_key UNIQUE (source, source_ref),
  constraint transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
  constraint transactions_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id),
  constraint transactions_import_job_id_fkey FOREIGN KEY (import_job_id) REFERENCES import_jobs(id),
  constraint transactions_raw_transaction_id_fkey FOREIGN KEY (raw_transaction_id) REFERENCES raw_transactions(id),
  constraint transactions_rule_id_fkey FOREIGN KEY (rule_id) REFERENCES classification_rules(id),
  constraint transactions_review_status_check CHECK ((review_status = ANY (ARRAY['auto'::text, 'pending'::text, 'reviewed'::text, 'ignored'::text])))
);
CREATE INDEX transactions_account_id_event_date_idx ON public.transactions USING btree (account_id, event_date DESC);
CREATE INDEX transactions_category_id_idx ON public.transactions USING btree (category_id);
CREATE INDEX transactions_competence_month_idx ON public.transactions USING btree (competence_month);
CREATE INDEX transactions_event_date_idx ON public.transactions USING btree (event_date DESC);
CREATE INDEX transactions_review_status_idx ON public.transactions USING btree (review_status) WHERE (review_status = 'pending'::text);
