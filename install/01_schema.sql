-- Family Finance — esquema completo para um projeto Supabase NOVO (gerado por install/build.py a partir de supabase/schema/live).
-- Rodar uma vez, como postgres (SQL editor do Supabase ou apply_migration). Não contém dados.
create extension if not exists unaccent with schema extensions;
create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;

-- sequências
create sequence if not exists public.account_balance_history_id_seq;
create sequence if not exists public.audit_logs_id_seq;
create sequence if not exists public.backup_runs_id_seq;
create sequence if not exists public.card_bill_reference_lines_id_seq;
create sequence if not exists public.classification_feedback_id_seq;
create sequence if not exists public.data_quality_issues_id_seq;
create sequence if not exists public.sync_errors_id_seq;

-- tabelas
create table public.account_balance_history (
  id bigint not null default nextval('account_balance_history_id_seq'::regclass),
  account_id uuid not null,
  balance numeric(14,2) not null,
  observed_at timestamp with time zone not null default now(),
  constraint account_balance_history_pkey PRIMARY KEY (id)
);

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
  constraint accounts_provider_account_id_key UNIQUE (provider_account_id)
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
  constraint assets_pkey PRIMARY KEY (id)
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
  constraint audit_logs_pkey PRIMARY KEY (id)
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
  cutoff_date date,
  constraint card_bill_cycles_pkey PRIMARY KEY (account_id, closing_date),
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
  constraint card_statements_provider_bill_id_key UNIQUE (provider_bill_id)
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
  constraint categories_kind_check CHECK ((kind = ANY (ARRAY['receita'::text, 'despesa'::text, 'transferencia'::text, 'investimento'::text, 'divida'::text])))
);

create table public.category_flex (
  group_id text not null,
  classe text not null,
  max_cut_pct numeric not null,
  source text not null default 'proposta'::text,
  updated_at timestamp with time zone not null default now(),
  constraint category_flex_pkey PRIMARY KEY (group_id),
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
  constraint classification_feedback_pkey PRIMARY KEY (id)
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
  constraint commitments_kind_check CHECK ((kind = ANY (ARRAY['financiamento'::text, 'parcelamento'::text, 'fixo'::text]))),
  constraint commitments_source_check CHECK ((source = ANY (ARRAY['detectado'::text, 'manual'::text, 'hugo'::text])))
);

create table public.connection_consents (
  id uuid not null default gen_random_uuid(),
  connection_id uuid not null,
  consent_expires_at timestamp with time zone,
  status text,
  observed_at timestamp with time zone not null default now(),
  constraint connection_consents_pkey PRIMARY KEY (id)
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
  constraint connections_provider_item_id_key UNIQUE (provider_item_id)
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
  constraint financing_contracts_pkey PRIMARY KEY (id)
);

create table public.financing_installments (
  contract_id text not null,
  n integer not null,
  due_date date not null,
  valor numeric(14,2) not null,
  saldo_apos numeric(14,2),
  pago boolean not null default false,
  constraint financing_installments_pkey PRIMARY KEY (contract_id, n)
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
  constraint import_jobs_source_ref_key UNIQUE (source_ref)
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
  constraint investment_positions_provider_investment_id_observed_at_key UNIQUE (provider_investment_id, observed_at)
);

create table public.mcc_category_map (
  mcc integer not null,
  category_id text not null,
  note text,
  constraint mcc_category_map_pkey PRIMARY KEY (mcc)
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
  constraint raw_transactions_provider_tx_id_key UNIQUE (provider_tx_id)
);

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
  constraint sync_errors_pkey PRIMARY KEY (id)
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
  constraint transaction_links_kind_check CHECK ((kind = ANY (ARRAY['transfer'::text, 'card_payment'::text, 'refund'::text, 'duplicate'::text, 'installment_group'::text]))),
  constraint transaction_links_status_check CHECK ((status = ANY (ARRAY['auto'::text, 'confirmed'::text, 'rejected'::text])))
);

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
  constraint transactions_review_status_check CHECK ((review_status = ANY (ARRAY['auto'::text, 'pending'::text, 'reviewed'::text, 'ignored'::text])))
);

alter sequence public.account_balance_history_id_seq owned by public.account_balance_history.id;
alter sequence public.audit_logs_id_seq owned by public.audit_logs.id;
alter sequence public.backup_runs_id_seq owned by public.backup_runs.id;
alter sequence public.card_bill_reference_lines_id_seq owned by public.card_bill_reference_lines.id;
alter sequence public.classification_feedback_id_seq owned by public.classification_feedback.id;
alter sequence public.data_quality_issues_id_seq owned by public.data_quality_issues.id;
alter sequence public.sync_errors_id_seq owned by public.sync_errors.id;

-- chaves estrangeiras
alter table public.account_balance_history add constraint account_balance_history_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE;
alter table public.accounts add constraint accounts_connection_id_fkey FOREIGN KEY (connection_id) REFERENCES connections(id) ON DELETE CASCADE;
alter table public.assets add constraint assets_financing_id_fkey FOREIGN KEY (financing_id) REFERENCES financing_contracts(id);
alter table public.audit_logs add constraint audit_logs_actor_fkey FOREIGN KEY (actor) REFERENCES household_members(id);
alter table public.budgets add constraint budgets_group_id_fkey FOREIGN KEY (group_id) REFERENCES categories(id);
alter table public.card_bill_cycles add constraint card_bill_cycles_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id);
alter table public.card_statements add constraint card_statements_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE;
alter table public.card_statements add constraint card_statements_import_job_id_fkey FOREIGN KEY (import_job_id) REFERENCES import_jobs(id);
alter table public.card_statements add constraint card_statements_paid_transaction_id_fkey FOREIGN KEY (paid_transaction_id) REFERENCES transactions(id);
alter table public.categories add constraint categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES categories(id);
alter table public.category_flex add constraint category_flex_group_id_fkey FOREIGN KEY (group_id) REFERENCES categories(id);
alter table public.classification_feedback add constraint classification_feedback_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES household_members(id);
alter table public.classification_feedback add constraint classification_feedback_new_category_id_fkey FOREIGN KEY (new_category_id) REFERENCES categories(id);
alter table public.classification_feedback add constraint classification_feedback_previous_category_id_fkey FOREIGN KEY (previous_category_id) REFERENCES categories(id);
alter table public.classification_feedback add constraint classification_feedback_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE;
alter table public.classification_rules add constraint classification_rules_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id);
alter table public.commitments add constraint commitments_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id);
alter table public.connection_consents add constraint connection_consents_connection_id_fkey FOREIGN KEY (connection_id) REFERENCES connections(id) ON DELETE CASCADE;
alter table public.connections add constraint connections_holder_member_id_fkey FOREIGN KEY (holder_member_id) REFERENCES household_members(id);
alter table public.connections add constraint connections_household_id_fkey FOREIGN KEY (household_id) REFERENCES households(id);
alter table public.connections add constraint connections_institution_id_fkey FOREIGN KEY (institution_id) REFERENCES financial_institutions(id);
alter table public.data_quality_issues add constraint data_quality_issues_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE;
alter table public.data_quality_issues add constraint data_quality_issues_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE;
alter table public.financing_contracts add constraint financing_contracts_commitment_id_fkey FOREIGN KEY (commitment_id) REFERENCES commitments(id);
alter table public.financing_installments add constraint financing_installments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES financing_contracts(id);
alter table public.fixed_expense_values add constraint fixed_expense_values_fixed_expense_id_fkey FOREIGN KEY (fixed_expense_id) REFERENCES fixed_expenses(id);
alter table public.fixed_expenses add constraint fixed_expenses_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id);
alter table public.fixed_expenses add constraint fixed_expenses_commitment_id_fkey FOREIGN KEY (commitment_id) REFERENCES commitments(id);
alter table public.household_members add constraint household_members_household_id_fkey FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE;
alter table public.import_jobs add constraint import_jobs_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id);
alter table public.investment_positions add constraint investment_positions_connection_id_fkey FOREIGN KEY (connection_id) REFERENCES connections(id) ON DELETE CASCADE;
alter table public.mcc_category_map add constraint mcc_category_map_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id);
alter table public.raw_transactions add constraint raw_transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE;
alter table public.sync_errors add constraint sync_errors_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id);
alter table public.sync_errors add constraint sync_errors_connection_id_fkey FOREIGN KEY (connection_id) REFERENCES connections(id);
alter table public.sync_errors add constraint sync_errors_sync_job_id_fkey FOREIGN KEY (sync_job_id) REFERENCES sync_jobs(id) ON DELETE CASCADE;
alter table public.transaction_links add constraint transaction_links_statement_id_fkey FOREIGN KEY (statement_id) REFERENCES card_statements(id) ON DELETE CASCADE;
alter table public.transaction_links add constraint transaction_links_tx_a_fkey FOREIGN KEY (tx_a) REFERENCES transactions(id) ON DELETE CASCADE;
alter table public.transaction_links add constraint transaction_links_tx_b_fkey FOREIGN KEY (tx_b) REFERENCES transactions(id) ON DELETE CASCADE;
alter table public.transactions add constraint transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE;
alter table public.transactions add constraint transactions_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id);
alter table public.transactions add constraint transactions_import_job_id_fkey FOREIGN KEY (import_job_id) REFERENCES import_jobs(id);
alter table public.transactions add constraint transactions_raw_transaction_id_fkey FOREIGN KEY (raw_transaction_id) REFERENCES raw_transactions(id);
alter table public.transactions add constraint transactions_rule_id_fkey FOREIGN KEY (rule_id) REFERENCES classification_rules(id);

-- índices
CREATE INDEX account_balance_history_account_id_observed_at_idx ON public.account_balance_history USING btree (account_id, observed_at DESC);
CREATE INDEX investment_positions_connection_id_observed_at_idx ON public.investment_positions USING btree (connection_id, observed_at DESC);
CREATE INDEX raw_transactions_account_id_last_seen_at_idx ON public.raw_transactions USING btree (account_id, last_seen_at);
CREATE INDEX transaction_links_tx_a_idx ON public.transaction_links USING btree (tx_a);
CREATE INDEX transaction_links_tx_b_idx ON public.transaction_links USING btree (tx_b);
CREATE INDEX transactions_account_id_event_date_idx ON public.transactions USING btree (account_id, event_date DESC);
CREATE INDEX transactions_category_id_idx ON public.transactions USING btree (category_id);
CREATE INDEX transactions_competence_month_idx ON public.transactions USING btree (competence_month);
CREATE INDEX transactions_event_date_idx ON public.transactions USING btree (event_date DESC);
CREATE INDEX transactions_review_status_idx ON public.transactions USING btree (review_status) WHERE (review_status = 'pending'::text);

-- funções e views (ordem de dependência)
CREATE OR REPLACE FUNCTION public.alert_param(k text)
 RETURNS numeric
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$ select value from alert_settings where key = k $function$
;

CREATE OR REPLACE FUNCTION public.assign_card_competence()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n int;
begin
  with x as (
    select t.id,
      coalesce((r.payload->'creditCardMetadata'->>'billPostDate')::date, t.event_date) pd,
      r.payload->'creditCardMetadata'->>'cardNumber' card,
      nullif(r.payload->'creditCardMetadata'->>'billForecastDate','0001-01') bf,
      t.account_id
    from transactions t join accounts a on a.id=t.account_id and a.type='CREDIT'
    left join raw_transactions r on r.id=t.raw_transaction_id
  ), y as (
    select x.*, (select min(cc.closing_date) from card_bill_cycles cc where cc.account_id=x.account_id and not cc.superseded
                  and coalesce(cc.cutoff_date, cc.closing_date) > x.pd) fech,
           (select h.holder_name from card_holders h where h.card_last4=x.card) holder
    from x)
  update transactions t set
    bill_closing_date = y.fech,
    competence_month = date_trunc('month', coalesce(y.fech, y.pd))::date,
    bill_forecast_date = case when y.bf ~ '^\d{4}-\d{2}$' then (y.bf||'-01')::date else t.bill_forecast_date end,
    card_last4 = coalesce(y.card, t.card_last4),
    holder_name = coalesce(y.holder, t.holder_name)
  from y where t.id=y.id and (
    t.bill_closing_date is distinct from y.fech
    or t.competence_month is distinct from date_trunc('month', coalesce(y.fech, y.pd))::date
    or t.card_last4 is distinct from coalesce(y.card, t.card_last4)
    or t.holder_name is distinct from coalesce(y.holder, t.holder_name));
  get diagnostics n = row_count;
  return n;
end $function$
;

CREATE OR REPLACE FUNCTION public.can_edit()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce((select role in ('owner','admin','member') from household_members where auth_user_id = auth.uid() limit 1), false)
$function$
;

CREATE OR REPLACE FUNCTION public.classify_transactions(p_only_unclassified boolean DEFAULT true)
 RETURNS TABLE(classified integer, pending integer)
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare v_classified int := 0; v_pending int := 0;
begin
  with cand as (
    select t.id, norm_text(t.description) as nd, norm_text(coalesce(t.counterpart_name,'')) as nc,
           norm_text(t.description || ' ' || coalesce(t.counterpart_name,'')) as nall, t.operation_type,
           case when (r.payload->'creditCardMetadata'->>'payeeMCC') ~ '^\d+$' then (r.payload->'creditCardMetadata'->>'payeeMCC')::int end as mcc
    from transactions t left join raw_transactions r on r.id = t.raw_transaction_id
    where (not p_only_unclassified or t.category_id is null or t.category_source in ('regra_sistema','regra_estabelecimento','pluggy','padrao_operacao','pendente','mcc'))
      and coalesce(t.category_source,'') <> 'ajuste_usuario'
  ),
  matched as (
    select c.id, r.id as rule_id, r.category_id, r.confidence, r.rule_type, r.priority,
           row_number() over (partition by c.id order by r.priority, length(r.pattern) desc) as rn
    from cand c join classification_rules r on r.is_active and (
         (r.rule_type = 'payee_name' and (c.nc like r.pattern || '%' or c.nall like '%' || r.pattern || '%'))
      or (r.rule_type = 'description_regex' and c.nd ~ r.pattern)
      or (r.rule_type = 'merchant_contains' and c.nall like '%' || r.pattern || '%')
    )
  ),
  best as (select * from matched where rn = 1),
  fallback as (
    select c.id,
      case
        when c.operation_type = 'RENDIMENTO_APLIC_FINANCEIRA' then 'investimentos'
        when c.operation_type like 'ENCARGOS%' or c.nd like 'iof %' or c.nd like '%tarifa%' or c.nd like '%juros%' then 'despesas_financeiras'
        when c.nd like 'aplicacao%' or c.nd like 'resgate%' or c.nd like '%cdb%' then 'investimentos'
        when c.nd like 'pagamento de fatura%' or c.nd like 'deb autom de fatura%' or c.nd like 'pagto cartao%' then 'pagamento_cartao'
        when c.nd like 'transferencia entre contas%' or c.nd like '%transf entre contas%' then 'transferencia_entre_contas'
        else null end as category_id,
      m.category_id as mcc_category
    from cand c left join mcc_category_map m on m.mcc = c.mcc
    where c.id not in (select id from best)
  ),
  upd as (
    update transactions t set
      category_id = coalesce(b.category_id, f.category_id, f.mcc_category),
      category_source = case when b.id is not null then (case when b.rule_type = 'payee_name' then 'pessoa' when b.rule_type = 'description_regex' then 'regra_sistema' else 'regra_estabelecimento' end)
                             when f.category_id is not null then 'padrao_operacao'
                             when f.mcc_category is not null then 'mcc' else 'pendente' end,
      category_confidence = case when b.id is not null then b.confidence when f.category_id is not null then 0.800 when f.mcc_category is not null then 0.700 else null end,
      rule_id = b.rule_id,
      review_status = case when b.id is not null or f.category_id is not null or f.mcc_category is not null then 'auto' else 'pending' end
    from cand c left join best b on b.id = c.id left join fallback f on f.id = c.id
    where t.id = c.id
    returning t.category_id
  )
  select count(*) filter (where category_id is not null), count(*) filter (where category_id is null) into v_classified, v_pending from upd;
  return query select v_classified, v_pending;
end $function$
;

CREATE OR REPLACE FUNCTION public.close_month(p_month date, p_notes text DEFAULT NULL::text, p_force boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare mb household_members; chk jsonb; snap jsonb; mm date := date_trunc('month', p_month)::date;
begin
  mb := current_member();
  if mb.id is null or mb.role not in ('owner','admin') then raise exception 'sem permissão'; end if;
  chk := month_close_check(mm);
  if not (chk->>'mes_encerrado')::boolean then raise exception 'o mês ainda não terminou'; end if;
  if not (chk->>'pronto')::boolean and not p_force then
    raise exception 'há % lançamentos sem categoria; revise ou feche com ressalva', chk->>'pendentes_categoria';
  end if;
  snap := jsonb_build_object(
    'resumo', (select to_jsonb(s) from v_month_summary s where month = mm),
    'grupos', (select jsonb_agg(jsonb_build_object('grupo', group_name, 'tipo', category_kind, 'total', total, 'n', n) order by total)
               from (select group_name, category_kind, sum(total) total, sum(n) n from v_category_month where month = mm group by 1,2) g),
    'saldos', (select jsonb_agg(jsonb_build_object('conta', name, 'tipo', subtype, 'saldo', balance, 'em', balance_observed_at)) from accounts where is_active),
    'gerado_em', now());
  insert into monthly_closings (month, status, snapshot, checklist, notes, closed_by)
  values (mm, 'fechado', snap, chk, p_notes, mb.id)
  on conflict (month) do update set status='fechado', snapshot=excluded.snapshot, checklist=excluded.checklist,
    notes=excluded.notes, closed_at=now(), closed_by=excluded.closed_by,
    history = monthly_closings.history || jsonb_build_object('em', now(), 'acao', 'refechado', 'snapshot_anterior', monthly_closings.snapshot);
  insert into audit_logs (table_name, row_id, action, actor, actor_label, after)
    values ('monthly_closings', mm::text, 'close', mb.id, mb.display_name, jsonb_build_object('force', p_force, 'notes', p_notes));
  return jsonb_build_object('ok', true, 'mes', mm, 'checklist', chk);
end $function$
;

CREATE OR REPLACE FUNCTION public.current_member()
 RETURNS household_members
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select * from household_members where auth_user_id = auth.uid() limit 1
$function$
;

CREATE OR REPLACE FUNCTION public.derive_counterpart(p_description text, p_payment jsonb)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select coalesce(
    nullif(p_payment->'payer'->>'name',''),
    nullif(p_payment->'receiver'->>'name',''),
    nullif(trim(regexp_replace(split_part(p_description, '   ', 2), '^[0-9]{2}/[0-9]{2} ', '')), '')
  )
$function$
;

CREATE OR REPLACE FUNCTION public.detect_duplicates()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n int;
begin
  with dup as (
    select b.id
    from transactions a join transactions b
      on b.account_id = a.account_id and b.event_date = a.event_date and b.amount = a.amount
     and norm_text(b.description) = norm_text(a.description) and b.id <> a.id
     and (a.source <> b.source or a.provider_code is distinct from b.provider_code)
     and (a.created_at, a.id) < (b.created_at, b.id)
  ), ins as (
    insert into data_quality_issues (kind, severity, transaction_id, detail)
    select 'duplicate_suspect', 'high', id, jsonb_build_object('rule','same_account_date_amount_desc') from dup
    on conflict do nothing returning 1
  ) select count(*) into n from ins;
  update transactions t set reconciliation = 'duplicate_suspect' from data_quality_issues q where q.transaction_id = t.id and q.kind = 'duplicate_suspect' and q.status = 'open' and t.reconciliation is distinct from 'duplicate_suspect';
  return n;
end $function$
;

CREATE OR REPLACE FUNCTION public.export_backup()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare t text; out jsonb := '{}'::jsonb; part jsonb;
begin
  -- v9: todas as tabelas do esquema public (novas tabelas entram automaticamente)
  for t in select table_name from information_schema.tables
           where table_schema='public' and table_type='BASE TABLE' and table_name <> 'app_settings' order by 1
  loop
    execute format('select coalesce(jsonb_agg(to_jsonb(x)), ''[]''::jsonb) from public.%I x', t) into part;
    out := out || jsonb_build_object(t, part);
  end loop;
  select coalesce(jsonb_agg(to_jsonb(s)), '[]'::jsonb) into part from app_settings s where key not in ('sync_token','backup_token');
  out := out || jsonb_build_object('app_settings', part);
  return jsonb_build_object('schema_version', 9, 'exported_at', now(), 'tables', out);
end $function$
;

CREATE OR REPLACE FUNCTION public.fmt_br(v date, f text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$ select to_char(v, f) $function$
;

CREATE OR REPLACE FUNCTION public.fmt_br(v numeric, f text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$ select translate(to_char(v, f), ',.', '.,') $function$
;

CREATE OR REPLACE FUNCTION public.fmt_br(v timestamp with time zone, f text)
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$ select to_char(v, f) $function$
;

CREATE OR REPLACE FUNCTION public.fmt_br(v timestamp without time zone, f text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$ select to_char(v, f) $function$
;

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

CREATE OR REPLACE FUNCTION public.my_household()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select household_id from household_members where auth_user_id = auth.uid() limit 1
$function$
;

CREATE OR REPLACE FUNCTION public.norm_text(t text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select trim(regexp_replace(regexp_replace(lower(extensions.unaccent(coalesce(t,''))), '[0-9]', '', 'g'), '[^a-z*]+', ' ', 'g'))
$function$
;

CREATE OR REPLACE FUNCTION public.payee_key_of(p_counterpart text, p_description text)
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  select lower(trim(regexp_replace(regexp_replace(coalesce(nullif(p_counterpart,''), left(norm_text(p_description),30)),'(parc\s*)?[0-9/*]+',' ','gi'),'\s+',' ','g')))
$function$
;

CREATE OR REPLACE FUNCTION public.post_sync()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  perform refresh_card_cycles();
  perform assign_card_competence();
  perform classify_transactions(true);
  perform reconcile_all();
  perform detect_duplicates();
end $function$
;

CREATE OR REPLACE FUNCTION public.reconcile_all()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n_transfer int; n_card int; n_refund int; n_dup int;
begin
  -- 1. Transferências entre contas próprias: mesmo valor absoluto, sentidos opostos, contas diferentes, até 2 dias
  with pairs as (
    select a.id as out_id, b.id as in_id,
      row_number() over (partition by a.id order by abs(b.event_date - a.event_date)) rn_a,
      row_number() over (partition by b.id order by abs(b.event_date - a.event_date)) rn_b
    from transactions a join transactions b
      on b.account_id <> a.account_id and b.amount = -a.amount and a.amount < 0
     and abs(b.event_date - a.event_date) <= 2
    where (a.category_id in ('transferencia_entre_contas') or b.category_id in ('transferencia_entre_contas')
           or norm_text(a.description) ~ '^(pix enviado|ted|transferencia)' and norm_text(b.description) ~ '^(pix recebido|ted|transferencia)')
      and not exists (select 1 from transaction_links l where l.kind='transfer' and (l.tx_a = a.id or l.tx_b = b.id))
  ), ins as (
    insert into transaction_links (kind, tx_a, tx_b, confidence, method)
    select 'transfer', out_id, in_id, 0.95, 'amount_opposite_2d' from pairs where rn_a = 1 and rn_b = 1
    on conflict do nothing returning tx_a, tx_b
  ), upd as (
    update transactions t set category_id = 'transferencia_entre_contas', category_source = coalesce(nullif(t.category_source,'pendente'), 'regra_sistema'), reconciliation = 'transfer_matched', review_status = 'auto'
    from ins where t.id in (ins.tx_a, ins.tx_b) and coalesce(t.category_source,'') <> 'ajuste_usuario' returning 1
  ) select count(*) into n_transfer from ins;

  -- 2. Pagamento de fatura: débito automático/pagamento na CC ↔ fatura do cartão (valor igual ±1, até 5 dias do vencimento)
  with cand as (
    select t.id as tx_id, s.id as st_id,
      row_number() over (partition by s.id order by abs(t.event_date - s.due_date)) rn
    from card_statements s join transactions t
      on t.category_id = 'pagamento_cartao' and t.amount < 0 and abs(-t.amount - s.total_amount) <= 1.00
     and abs(t.event_date - s.due_date) <= 5
    where s.paid_transaction_id is null
  ), ins as (
    insert into transaction_links (kind, tx_a, statement_id, confidence, method)
    select 'card_payment', tx_id, st_id, 0.95, 'amount_due_5d' from cand where rn = 1
    on conflict do nothing returning tx_a, statement_id
  ), u1 as (update card_statements s set paid_transaction_id = ins.tx_a from ins where s.id = ins.statement_id returning 1),
  u2 as (update transactions t set reconciliation = 'card_payment_matched' from ins where t.id = ins.tx_a returning 1)
  select count(*) into n_card from ins;

  -- 3. Estornos no cartão: crédito com mesmo valor e mesma contraparte/descrição de um débito até 60 dias antes
  with cand as (
    select d.id as debit_id, c.id as credit_id,
      row_number() over (partition by c.id order by c.event_date - d.event_date) rn
    from transactions c join transactions d
      on d.account_id = c.account_id and d.amount = -c.amount and d.amount < 0 and c.amount > 0
     and c.event_date between d.event_date and d.event_date + 60
     and norm_text(d.description) = norm_text(c.description)
    join accounts a on a.id = c.account_id and a.type = 'CREDIT'
    where not exists (select 1 from transaction_links l where l.kind = 'refund' and l.tx_b = c.id)
  ), ins as (
    insert into transaction_links (kind, tx_a, tx_b, confidence, method)
    select 'refund', debit_id, credit_id, 0.90, 'same_merchant_amount_60d' from cand where rn = 1
    on conflict do nothing returning tx_a, tx_b
  ), upd as (
    update transactions t set reconciliation = 'refund', category_id = d.category_id, category_source = 'regra_sistema'
    from ins join transactions d on d.id = ins.tx_a where t.id = ins.tx_b and coalesce(t.category_source,'') <> 'ajuste_usuario' returning 1
  ) select count(*) into n_refund from ins;

  -- 4. Duplicidades suspeitas: mesma conta, data, valor e descrição, origens diferentes (nunca apaga; só sinaliza)
  with dup as (
    select b.id
    from transactions a join transactions b
      on b.account_id = a.account_id and b.event_date = a.event_date and b.amount = a.amount
     and norm_text(b.description) = norm_text(a.description) and b.id <> a.id
     and (a.source <> b.source or a.provider_code is distinct from b.provider_code)
     and a.created_at < b.created_at
  ), ins as (
    insert into data_quality_issues (kind, severity, transaction_id, detail)
    select 'duplicate_suspect', 'high', id, jsonb_build_object('rule','same_account_date_amount_desc') from dup
    on conflict do nothing returning 1
  ) select count(*) into n_dup from ins;

  -- 5. Pendentes antigos (status PENDING há mais de 7 dias)
  insert into data_quality_issues (kind, severity, transaction_id, detail)
  select 'pending_stale', 'low', id, jsonb_build_object('since', event_date) from transactions
  where status = 'PENDING' and event_date < current_date - 7
  on conflict do nothing;

  return jsonb_build_object('transfers', n_transfer, 'card_payments', n_card, 'refunds', n_refund, 'duplicates', n_dup);
end $function$
;

CREATE OR REPLACE FUNCTION public.refresh_card_cycles()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n_new int := 0; n_paid int := 0; n_tmp int; r record; est date; c date;
begin
  for r in select id, number from accounts where type='CREDIT' and is_active loop
    with d as (
      select date_trunc('month', event_date)::date m, event_date, count(*) n,
             row_number() over (partition by date_trunc('month', event_date) order by count(*) desc, event_date desc) rn
      from transactions where account_id=r.id and coalesce(installment_number,1)>=2 and not is_deleted_at_source
      group by 1,2
    ), ins as (
      insert into card_bill_cycles (account_id, closing_date, source)
      select r.id, d.event_date, 'pluggy_parcelas' from d
      where rn=1 and n>=2
        and not exists (select 1 from card_bill_cycles x where x.account_id=r.id and date_trunc('month',x.closing_date)=d.m and x.source in ('pdf','pluggy_parcelas'))
      on conflict do nothing returning 1)
    select count(*) into n_tmp from ins;
    n_new := n_new + n_tmp;
    update card_bill_cycles e set superseded = true, updated_at = now()
      where e.account_id=r.id and e.source='estimado' and not e.superseded
      and exists (select 1 from card_bill_cycles x where x.account_id=r.id and x.source<>'estimado' and date_trunc('month',x.closing_date)=date_trunc('month',e.closing_date));
    for est in select (date_trunc('month', current_date) + (k||' month')::interval)::date from generate_series(0,1) k loop
      c := least(est + 28, (est + interval '1 month' - interval '1 day')::date);
      while extract(isodow from c) > 5 loop c := c - 1; end loop;
      insert into card_bill_cycles (account_id, closing_date, source)
      select r.id, c, 'estimado'
      where not exists (select 1 from card_bill_cycles x where x.account_id=r.id and date_trunc('month',x.closing_date)=est)
      on conflict do nothing;
    end loop;
    update card_bill_cycles set due_date = (date_trunc('month', closing_date) + interval '1 month')::date + 5
      where account_id=r.id and due_date is null;
    with p as (
      select x.closing_date, t.id tx, -t.amount v,
        row_number() over (partition by x.closing_date order by abs(t.event_date - x.due_date), t.amount) rn
      from card_bill_cycles x join transactions t on t.amount<0
       and t.event_date between x.closing_date + 3 and x.closing_date + 15
       and norm_text(t.description) like '%fatura%' and t.description like '%' || r.number || '%'
      join accounts a on a.id=t.account_id and a.type='BANK'
      where x.account_id=r.id and not x.superseded)
    update card_bill_cycles x set paid_amount=p.v, paid_transaction_id=p.tx, updated_at=now()
      from p where x.account_id=r.id and x.closing_date=p.closing_date and p.rn=1
       and x.paid_transaction_id is distinct from p.tx;
    get diagnostics n_tmp = row_count;
    n_paid := n_paid + n_tmp;
  end loop;
  return jsonb_build_object('novos_fechamentos', n_new, 'pagamentos_vinculados', n_paid);
end $function$
;

CREATE OR REPLACE FUNCTION public.reopen_month(p_month date, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare mb household_members;
begin
  mb := current_member();
  if mb.id is null or mb.role not in ('owner','admin') then raise exception 'sem permissão'; end if;
  update monthly_closings set status='reaberto', history = history || jsonb_build_object('em', now(), 'acao', 'reaberto', 'motivo', p_reason)
   where month = date_trunc('month', p_month)::date;
  insert into audit_logs (table_name, row_id, action, actor, actor_label, after)
    values ('monthly_closings', p_month::text, 'reopen', mb.id, mb.display_name, jsonb_build_object('motivo', p_reason));
end $function$
;

CREATE OR REPLACE FUNCTION public.restore_backup_to_test(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare t text; tables jsonb := p->'tables'; n_json bigint; n_rest bigint; n_prod bigint; rep jsonb := '{}'::jsonb; ok boolean := true;
        sum_json numeric; sum_rest numeric; sum_prod numeric; falhas text[] := '{}';
begin
  execute 'drop schema if exists restore_test cascade';
  execute 'create schema restore_test';
  for t in select jsonb_object_keys(tables) loop
    execute format('create table restore_test.%I (like public.%I including defaults)', t, t);
    execute format('insert into restore_test.%I select * from jsonb_populate_recordset(null::public.%I, $1)', t, t) using tables->t;
    execute format('select count(*) from restore_test.%I', t) into n_rest;
    n_json := jsonb_array_length(tables->t);
    if t = 'app_settings' then
      select count(*) into n_prod from public.app_settings where key not in ('sync_token','backup_token');
    else
      execute format('select count(*) from public.%I', t) into n_prod;
    end if;
    rep := rep || jsonb_build_object(t, jsonb_build_object('backup', n_json, 'restaurado', n_rest, 'producao', n_prod));
    if n_rest <> n_json then ok := false; falhas := falhas || (t || ': restaurado difere do backup'); end if;
    if t in ('transactions','raw_transactions') and n_prod < n_json then
      ok := false; falhas := falhas || (t || ': produção com menos linhas que o backup');
    end if;
  end loop;
  select coalesce(sum((e->>'amount')::numeric),0) into sum_json from jsonb_array_elements(tables->'transactions') e;
  select coalesce(sum(amount),0) into sum_rest from restore_test.transactions;
  select coalesce(sum(amount),0) into sum_prod from public.transactions;
  rep := rep || jsonb_build_object('soma_transacoes', jsonb_build_object('backup', sum_json, 'restaurado', sum_rest, 'producao', sum_prod));
  if sum_rest <> sum_json then ok := false; falhas := falhas || 'soma das transações restauradas difere do backup'::text; end if;
  insert into backup_runs (status, note, tables)
  values (case when ok then 'RESTORE_TEST_OK' else 'RESTORE_TEST_DIVERGENT' end,
          'v2: restaurado × próprio backup; produção só informativa (alarme se perder lançamentos)'
            || case when ok then '' else ' | ' || array_to_string(falhas, '; ') end, rep);
  execute 'drop schema if exists restore_test cascade';
  return jsonb_build_object('ok', ok, 'exported_at', p->>'exported_at', 'falhas', to_jsonb(falhas), 'detail', rep);
end $function$
;

CREATE OR REPLACE FUNCTION public.set_transaction_category(p_tx uuid, p_category text, p_create_rule boolean DEFAULT false, p_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare m household_members; t transactions; v_pattern text;
begin
  m := current_member();
  if m.id is null or m.role not in ('owner','admin','member') then raise exception 'sem permissão'; end if;
  select * into t from transactions where id = p_tx;
  if t.id is null then raise exception 'lançamento não encontrado'; end if;
  insert into classification_feedback (transaction_id, previous_category_id, new_category_id, previous_source, changed_by, reason)
    values (p_tx, t.category_id, p_category, t.category_source, m.id, p_reason);
  insert into audit_logs (table_name, row_id, action, actor, actor_label, before, after)
    values ('transactions', p_tx::text, 'reclassify', m.id, m.display_name,
            jsonb_build_object('category_id', t.category_id, 'source', t.category_source),
            jsonb_build_object('category_id', p_category, 'source', 'ajuste_usuario'));
  update transactions set category_id = p_category, category_source = 'ajuste_usuario', category_confidence = 1.0,
         review_status = 'reviewed', rule_id = null where id = p_tx;
  if p_create_rule then
    v_pattern := norm_text(coalesce(nullif(btrim(t.counterpart_name), ''), nullif(btrim(split_part(t.description, '   ', 2)), ''), t.description));
    -- sem nome de estabelecimento, uma descrição que começa com termo de operação (pix, boleto, pagamento...) geraria regra ampla demais
    if length(v_pattern) >= 4 and not (nullif(btrim(t.counterpart_name), '') is null and v_pattern ~ '^(pix|ted|doc|pagamento|pagto|pag|boleto|transferencia|transf|saque|deposito|dep|tarifa|debito|deb|credito|cred|compra|estorno|resgate|aplicacao|rendimento)( |$)') then
      insert into classification_rules (rule_type, pattern, category_id, origin, confidence, priority, example)
        values ('merchant_contains', v_pattern, p_category, 'usuario', 0.900, 90, t.description)
      on conflict (rule_type, pattern) do update set category_id = excluded.category_id, origin = 'usuario', confidence = 0.900,
        history = classification_rules.history || jsonb_build_object('em', now(), 'de', classification_rules.category_id, 'para', excluded.category_id);
      perform classify_transactions(true);
    end if;
  end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin new.updated_at = now(); return new; end $function$
;

create or replace view public.v_card_bills with (security_invoker = on) as
 SELECT account_id,
    closing_date,
    due_date,
    source,
    (date_trunc('month'::text, (closing_date)::timestamp with time zone))::date AS competence_month,
    COALESCE(( SELECT (- sum(t.amount))
           FROM (transactions t
             LEFT JOIN categories k ON ((k.id = t.category_id)))
          WHERE ((t.account_id = c.account_id) AND (t.bill_closing_date = c.closing_date) AND (NOT t.is_deleted_at_source) AND (t.reconciliation IS DISTINCT FROM 'duplicate_suspect'::text) AND (k.kind IS DISTINCT FROM 'transferencia'::text))), (0)::numeric) AS total_lancamentos,
    ( SELECT count(*) AS count
           FROM (transactions t
             LEFT JOIN categories k ON ((k.id = t.category_id)))
          WHERE ((t.account_id = c.account_id) AND (t.bill_closing_date = c.closing_date) AND (NOT t.is_deleted_at_source) AND (k.kind IS DISTINCT FROM 'transferencia'::text))) AS n_lancamentos,
    pdf_total,
    paid_amount,
    paid_transaction_id,
        CASE
            WHEN (paid_transaction_id IS NOT NULL) THEN 'paga'::text
            WHEN (closing_date < CURRENT_DATE) THEN 'fechada'::text
            ELSE 'aberta'::text
        END AS status
   FROM card_bill_cycles c
  WHERE (NOT superseded);

create or replace view public.v_card_future_installments with (security_invoker = on) as
 WITH s AS (
         SELECT t.account_id,
            norm_text(t.description) AS chave,
            t.installment_total AS tt,
            max(t.installment_number) AS n,
            (array_agg(t.description ORDER BY t.installment_number DESC))[1] AS description,
            (array_agg(t.holder_name ORDER BY t.installment_number DESC))[1] AS holder_name,
            (array_agg((- t.amount) ORDER BY t.installment_number DESC))[1] AS valor,
            (array_agg(t.category_id ORDER BY t.installment_number DESC))[1] AS category_id,
            max(t.bill_closing_date) AS ult_fechamento
           FROM (transactions t
             JOIN accounts a ON (((a.id = t.account_id) AND (a.type = 'CREDIT'::text))))
          WHERE ((t.installment_total > 1) AND (NOT t.is_deleted_at_source))
          GROUP BY t.account_id, (norm_text(t.description)), t.installment_total
        )
 SELECT s.description,
    s.holder_name,
    s.n AS parcela_atual,
    s.tt AS total_parcelas,
    s.valor,
    ((date_trunc('month'::text, (COALESCE(s.ult_fechamento, CURRENT_DATE))::timestamp with time zone) + ((g.i || ' month'::text))::interval))::date AS competence_month,
    s.category_id,
    COALESCE(c.parent_id, c.id, 'outros'::text) AS group_id,
    (s.n + g.i) AS parcela_no_mes
   FROM (s
     LEFT JOIN categories c ON ((c.id = s.category_id))),
    generate_series(1, 36) g(i)
  WHERE ((s.n < s.tt) AND (g.i <= (s.tt - s.n)) AND (((date_trunc('month'::text, (COALESCE(s.ult_fechamento, CURRENT_DATE))::timestamp with time zone) + ((g.i || ' month'::text))::interval))::date >= (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date));

create or replace view public.v_financing with (security_invoker = on) as
 SELECT id,
    nome,
    banco,
    contrato,
    commitment_id,
    data_contrato,
    valor_financiado,
    sistema,
    indexador,
    taxa_efetiva_aa,
    taxa_nominal_aa,
    prazo_total,
    dia_vencimento,
    saldo_devedor,
    saldo_em,
    parcelas_pagas,
    parcelas_restantes,
    ultima_parcela,
    amortizacao_mensal,
    total_a_pagar,
    juros_a_pagar,
    seguros_tarifas_a_pagar,
    participacao,
    fonte,
    updated_at,
    ( SELECT i.valor
           FROM financing_installments i
          WHERE ((i.contract_id = c.id) AND (NOT i.pago))
          ORDER BY i.n
         LIMIT 1) AS proxima_parcela,
    ( SELECT i.due_date
           FROM financing_installments i
          WHERE ((i.contract_id = c.id) AND (NOT i.pago))
          ORDER BY i.n
         LIMIT 1) AS proximo_vencimento,
    ( SELECT COALESCE(sum(i.valor), (0)::numeric) AS "coalesce"
           FROM financing_installments i
          WHERE ((i.contract_id = c.id) AND (NOT i.pago) AND (i.due_date < ((date_trunc('year'::text, (CURRENT_DATE)::timestamp with time zone) + '2 years'::interval))::date) AND (i.due_date >= ((date_trunc('year'::text, (CURRENT_DATE)::timestamp with time zone) + '1 year'::interval))::date))) AS total_proximo_ano
   FROM financing_contracts c;

create or replace view public.v_investments_latest with (security_invoker = on) as
 SELECT DISTINCT ON (provider_investment_id) provider_investment_id,
    name,
    type,
    subtype,
    balance,
    amount_invested,
    due_date,
    rate,
    rate_type,
    observed_at
   FROM investment_positions
  WHERE (observed_at >= (( SELECT max(investment_positions_1.observed_at) AS max
           FROM investment_positions investment_positions_1) - '01:00:00'::interval))
  ORDER BY provider_investment_id, observed_at DESC;

create or replace view public.v_net_worth with (security_invoker = on) as
 WITH contas AS (
         SELECT COALESCE(sum(accounts.balance) FILTER (WHERE (accounts.subtype = 'CHECKING_ACCOUNT'::text)), (0)::numeric) AS cc,
            COALESCE(sum(accounts.balance) FILTER (WHERE (accounts.subtype = 'SAVINGS_ACCOUNT'::text)), (0)::numeric) AS poup
           FROM accounts
          WHERE (accounts.is_active AND (accounts.type = 'BANK'::text))
        ), inv AS (
         SELECT COALESCE(sum(v_investments_latest.balance), (0)::numeric) AS v
           FROM v_investments_latest
        ), cartao AS (
         SELECT COALESCE(sum(accounts.balance), (0)::numeric) AS v
           FROM accounts
          WHERE (accounts.is_active AND (accounts.type = 'CREDIT'::text))
        ), div AS (
         SELECT COALESCE(sum(commitments.outstanding_balance), (0)::numeric) AS v,
            count(*) FILTER (WHERE ((commitments.kind = 'financiamento'::text) AND (commitments.outstanding_balance IS NULL))) AS sem_saldo
           FROM commitments
          WHERE commitments.is_active
        ), bens AS (
         SELECT COALESCE(sum(assets.valor), (0)::numeric) AS v
           FROM assets
          WHERE assets.is_active
        )
 SELECT contas.cc AS conta_corrente,
    contas.poup AS poupanca,
    inv.v AS investimentos,
    ((contas.cc + contas.poup) + inv.v) AS ativos_financeiros,
    cartao.v AS cartao_utilizado,
    div.v AS financiamentos_saldo,
    div.sem_saldo AS financiamentos_sem_saldo,
    ((((contas.cc + contas.poup) + inv.v) - cartao.v) - div.v) AS patrimonio_financeiro_liquido,
    ( SELECT max(accounts.balance_observed_at) AS max
           FROM accounts) AS atualizado_em,
    bens.v AS bens,
    (((((contas.cc + contas.poup) + inv.v) + bens.v) - cartao.v) - div.v) AS patrimonio_liquido
   FROM contas,
    inv,
    cartao,
    div,
    bens;

create or replace view public.v_sync_status with (security_invoker = on) as
 SELECT connector_name,
    status,
    execution_status,
    provider_updated_at,
    last_sync_at,
    consent_expires_at,
    ((consent_expires_at - now()) < '30 days'::interval) AS consent_warning,
    ( SELECT max(sync_jobs.finished_at) AS max
           FROM sync_jobs
          WHERE (sync_jobs.status = ANY (ARRAY['SUCCESS'::text, 'PARTIAL'::text]))) AS last_ok_sync,
    ( SELECT sync_jobs.status
           FROM sync_jobs
          ORDER BY sync_jobs.started_at DESC
         LIMIT 1) AS last_job_status,
    ( SELECT count(*) AS count
           FROM (sync_errors e
             JOIN sync_jobs j ON ((j.id = e.sync_job_id)))
          WHERE (j.started_at > (now() - '7 days'::interval))) AS errors_7d
   FROM connections c
  WHERE is_active;

create or replace view public.v_tx with (security_invoker = on) as
 SELECT t.id,
    t.account_id,
    t.raw_transaction_id,
    t.source,
    t.source_ref,
    t.event_date,
    t.event_at,
    t.amount,
    t.currency,
    t.description,
    t.description_raw,
    t.provider_code,
    t.type,
    t.status,
    t.operation_type,
    t.payment_data,
    t.merchant,
    t.installment_number,
    t.installment_total,
    t.bill_closing_date,
    t.bill_forecast_date,
    t.balance_after,
    t.provider_category,
    t.is_deleted_at_source,
    t.created_at,
    t.updated_at,
    t.category_id,
    t.category_source,
    t.category_confidence,
    t.rule_id,
    t.review_status,
    t.card_last4,
    t.holder_name,
    t.competence_month,
    t.import_job_id,
    t.counterpart_name,
    t.reconciliation,
    a.subtype AS account_subtype,
    a.name AS account_name,
    c.name AS category_name,
    c.kind AS category_kind,
    COALESCE(p.id, c.id) AS group_id,
    COALESCE(p.name, c.name) AS group_name,
    COALESCE(t.competence_month, (date_trunc('month'::text, (t.event_date)::timestamp with time zone))::date) AS month
   FROM (((transactions t
     JOIN accounts a ON ((a.id = t.account_id)))
     LEFT JOIN categories c ON ((c.id = t.category_id)))
     LEFT JOIN categories p ON ((p.id = c.parent_id)))
  WHERE ((NOT t.is_deleted_at_source) AND (t.reconciliation IS DISTINCT FROM 'duplicate_suspect'::text));

CREATE OR REPLACE FUNCTION public.month_close_check(p_month date)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  with m as (select date_trunc('month', p_month)::date m),
  b as (select * from v_card_bills, m where competence_month = m.m)
  select jsonb_build_object(
    'mes', (select m from m),
    'mes_encerrado', (select (m + interval '1 month')::date <= (now() at time zone 'America/Cuiaba')::date from m),
    'pendentes_categoria', (select count(*) from v_tx, m where month = m.m and category_id is null),
    'valor_pendente', (select coalesce(sum(abs(amount)),0) from v_tx, m where month = m.m and category_id is null),
    'duplicidades_abertas', (select count(*) from data_quality_issues q join transactions t on t.id=q.transaction_id, m
                              where q.kind='duplicate_suspect' and q.status='open' and coalesce(t.competence_month, date_trunc('month',t.event_date)::date)=m.m),
    'fatura', (select jsonb_build_object('fechamento', closing_date, 'status', status, 'lancamentos', total_lancamentos,
               'pago', paid_amount, 'pdf', pdf_total, 'diferenca', round(total_lancamentos - coalesce(pdf_total, paid_amount, total_lancamentos), 2),
               'fonte_fechamento', source) from b limit 1),
    'sincronizacao_ok', (select last_ok_sync from v_sync_status limit 1),
    'pronto', (select (m + interval '1 month')::date <= (now() at time zone 'America/Cuiaba')::date from m)
              and (select count(*) from v_tx, m where month = m.m and category_id is null) = 0
  );
$function$
;

create or replace view public.v_alerts_base with (security_invoker = on) as
 WITH hoje AS (
         SELECT ((now() AT TIME ZONE 'America/Cuiaba'::text))::date AS d
        ), mes AS (
         SELECT (date_trunc('month'::text, (hoje.d)::timestamp with time zone))::date AS m,
            hoje.d,
            EXTRACT(day FROM hoje.d) AS dia,
            EXTRACT(day FROM (date_trunc('month'::text, (hoje.d)::timestamp with time zone) + '1 mon -1 days'::interval)) AS dias
           FROM hoje
        ), cc AS (
         SELECT COALESCE(sum(accounts.balance), (0)::numeric) AS saldo
           FROM accounts
          WHERE ((accounts.type = 'BANK'::text) AND (accounts.subtype = 'CHECKING_ACCOUNT'::text) AND accounts.is_active)
        ), aberta AS (
         SELECT v_card_bills.account_id,
            v_card_bills.closing_date,
            v_card_bills.due_date,
            v_card_bills.source,
            v_card_bills.competence_month,
            v_card_bills.total_lancamentos,
            v_card_bills.n_lancamentos,
            v_card_bills.pdf_total,
            v_card_bills.paid_amount,
            v_card_bills.paid_transaction_id,
            v_card_bills.status
           FROM v_card_bills
          WHERE (v_card_bills.status = ANY (ARRAY['aberta'::text, 'fechada'::text]))
          ORDER BY v_card_bills.closing_date
         LIMIT 1
        ), media_fatura AS (
         SELECT avg(COALESCE(x.paid_amount, x.total_lancamentos)) AS v
           FROM ( SELECT v_card_bills.account_id,
                    v_card_bills.closing_date,
                    v_card_bills.due_date,
                    v_card_bills.source,
                    v_card_bills.competence_month,
                    v_card_bills.total_lancamentos,
                    v_card_bills.n_lancamentos,
                    v_card_bills.pdf_total,
                    v_card_bills.paid_amount,
                    v_card_bills.paid_transaction_id,
                    v_card_bills.status
                   FROM v_card_bills
                  WHERE (v_card_bills.status = 'paga'::text)
                  ORDER BY v_card_bills.closing_date DESC
                 LIMIT 6) x
        ), cat_mes AS (
         SELECT v_tx.group_id,
            v_tx.group_name,
            (- sum(v_tx.amount)) AS v
           FROM v_tx,
            mes
          WHERE ((v_tx.month = mes.m) AND (v_tx.amount < (0)::numeric) AND (v_tx.category_kind IS DISTINCT FROM 'transferencia'::text) AND (v_tx.category_kind IS DISTINCT FROM 'investimento'::text))
          GROUP BY v_tx.group_id, v_tx.group_name
        ), cat_media AS (
         SELECT v_tx.group_id,
            ((- sum(v_tx.amount)) / 6.0) AS v
           FROM v_tx,
            mes
          WHERE ((v_tx.month >= (mes.m - '6 mons'::interval)) AND (v_tx.month < mes.m) AND (v_tx.amount < (0)::numeric) AND (v_tx.category_kind IS DISTINCT FROM 'transferencia'::text) AND (v_tx.category_kind IS DISTINCT FROM 'investimento'::text))
          GROUP BY v_tx.group_id
        )
 SELECT 'fatura_vencimento'::text AS kind,
        CASE
            WHEN (a.total_lancamentos > ( SELECT cc.saldo
               FROM cc)) THEN 'alta'::text
            ELSE 'media'::text
        END AS severity,
    ('Fatura do cartão vence em '::text || fmt_br((a.due_date)::timestamp with time zone, 'DD/MM'::text)) AS title,
    ((('Valor estimado R$ '::text || fmt_br(a.total_lancamentos, 'FM999G999D00'::text)) || '; saldo em conta R$ '::text) || fmt_br(( SELECT cc.saldo
           FROM cc), 'FM999G999D00'::text)) AS detail,
    a.total_lancamentos AS amount,
    a.due_date AS ref_date
   FROM aberta a,
    hoje
  WHERE ((a.status = 'fechada'::text) AND (((a.due_date - hoje.d) >= 0) AND (((a.due_date - hoje.d))::numeric <= alert_param('fatura_vence_dias'::text))))
UNION ALL
 SELECT 'fatura_acima_media'::text AS kind,
    'media'::text AS severity,
    ('Fatura em aberto já soma R$ '::text || fmt_br(b.total_lancamentos, 'FM999G999D00'::text)) AS title,
    (((('Média das últimas 6 faturas: R$ '::text || fmt_br(m.v, 'FM999G999D00'::text)) || ' ('::text) || round(((100)::numeric * ((b.total_lancamentos / m.v) - (1)::numeric)))) || '% acima)'::text) AS detail,
    b.total_lancamentos AS amount,
    b.closing_date AS ref_date
   FROM v_card_bills b,
    media_fatura m
  WHERE ((b.status = 'aberta'::text) AND (b.closing_date = ( SELECT min(v_card_bills.closing_date) AS min
           FROM v_card_bills
          WHERE (v_card_bills.status = 'aberta'::text))) AND (m.v > (0)::numeric) AND (b.total_lancamentos > (m.v * ((1)::numeric + (alert_param('fatura_acima_media_pct'::text) / (100)::numeric)))))
UNION ALL
 SELECT 'categoria_ritmo'::text AS kind,
    'media'::text AS severity,
    (c.group_name || ' acima do ritmo'::text) AS title,
    ((('No mês: R$ '::text || fmt_br(c.v, 'FM999G999D00'::text)) || '; ritmo médio até hoje: R$ '::text) || fmt_br(((cm.v * mes.dia) / mes.dias), 'FM999G999D00'::text)) AS detail,
    (c.v - ((cm.v * mes.dia) / mes.dias)) AS amount,
    mes.d AS ref_date
   FROM (cat_mes c
     JOIN cat_media cm USING (group_id)),
    mes
  WHERE ((mes.dia >= (7)::numeric) AND (c.v > (((cm.v * mes.dia) / mes.dias) * ((1)::numeric + (alert_param('categoria_acima_media_pct'::text) / (100)::numeric)))) AND ((c.v - ((cm.v * mes.dia) / mes.dias)) > alert_param('categoria_minimo_reais'::text)))
UNION ALL
 SELECT 'compra_grande'::text AS kind,
    'baixa'::text AS severity,
    ((('Compra de R$ '::text || fmt_br((- t.amount), 'FM999G999D00'::text)) || ' em '::text) || t.description) AS title,
    (((COALESCE(t.holder_name, ''::text) || ' · '::text) || fmt_br((t.event_date)::timestamp with time zone, 'DD/MM'::text)) || COALESCE((((' · '::text || t.installment_number) || '/'::text) || t.installment_total), ''::text)) AS detail,
    (- t.amount) AS amount,
    t.event_date AS ref_date
   FROM v_tx t,
    hoje
  WHERE ((t.account_subtype = 'CREDIT_CARD'::text) AND ((- t.amount) >= alert_param('compra_grande_reais'::text)) AND (t.event_date >= (hoje.d - 7)) AND (COALESCE(t.installment_number, 1) = 1))
UNION ALL
 SELECT 'revisao_pendente'::text AS kind,
        CASE
            WHEN (count(*) > 30) THEN 'media'::text
            ELSE 'baixa'::text
        END AS severity,
    (count(*) || ' lançamentos aguardando categoria'::text) AS title,
    ('Valor envolvido: R$ '::text || fmt_br(sum(abs(v_tx.amount)), 'FM999G999D00'::text)) AS detail,
    sum(abs(v_tx.amount)) AS amount,
    NULL::date AS ref_date
   FROM v_tx
  WHERE (v_tx.category_id IS NULL)
 HAVING (count(*) > 0)
UNION ALL
 SELECT 'sincronizacao'::text AS kind,
    'alta'::text AS severity,
    'Sincronização com o banco atrasada'::text AS title,
    ('Última sincronização ok: '::text || COALESCE(fmt_br((s.last_ok_sync AT TIME ZONE 'America/Cuiaba'::text), 'DD/MM HH24:MI'::text), 'nunca'::text)) AS detail,
    NULL::numeric AS amount,
    NULL::date AS ref_date
   FROM v_sync_status s
  WHERE ((s.last_ok_sync IS NULL) OR (s.last_ok_sync < (now() - ((alert_param('sync_atraso_horas'::text) || ' hours'::text))::interval)))
UNION ALL
 SELECT 'consentimento'::text AS kind,
    'alta'::text AS severity,
    'Autorização Open Finance vence em breve'::text AS title,
    (('Vence em '::text || fmt_br(s.consent_expires_at, 'DD/MM/YYYY'::text)) || ' — renovar no Meu Pluggy'::text) AS detail,
    NULL::numeric AS amount,
    (s.consent_expires_at)::date AS ref_date
   FROM v_sync_status s
  WHERE s.consent_warning
UNION ALL
 SELECT 'duplicidade'::text AS kind,
    'media'::text AS severity,
    (count(*) || ' possíveis duplicidades'::text) AS title,
    'Ocultas dos totais até confirmação'::text AS detail,
    NULL::numeric AS amount,
    NULL::date AS ref_date
   FROM data_quality_issues
  WHERE ((data_quality_issues.kind = 'duplicate_suspect'::text) AND (data_quality_issues.status = 'open'::text))
 HAVING (count(*) > 0);

create or replace view public.v_category_month with (security_invoker = on) as
 SELECT month,
    group_id,
    group_name,
    category_id,
    category_name,
    category_kind,
    count(*) AS n,
    sum(amount) AS total
   FROM v_tx
  WHERE (category_kind IS DISTINCT FROM 'transferencia'::text)
  GROUP BY month, group_id, group_name, category_id, category_name, category_kind;

create or replace view public.v_daily_flow with (security_invoker = on) as
 SELECT event_date,
    account_subtype,
    sum(amount) FILTER (WHERE ((amount > (0)::numeric) AND (category_kind IS DISTINCT FROM 'transferencia'::text))) AS entradas,
    sum(amount) FILTER (WHERE ((amount < (0)::numeric) AND (category_kind IS DISTINCT FROM 'transferencia'::text))) AS saidas,
    count(*) AS n
   FROM v_tx
  GROUP BY event_date, account_subtype;

create or replace view public.v_fixed_month with (security_invoker = on) as
 WITH meses AS (
         SELECT (generate_series((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval), (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) + '1 year'::interval), '1 mon'::interval))::date AS mes
        ), tx AS MATERIALIZED (
         SELECT t.month,
            t.category_id,
            payee_key_of(t.counterpart_name, t.description) AS pk,
            norm_text(((COALESCE(t.counterpart_name, ''::text) || ' '::text) || t.description)) AS nt,
            (- t.amount) AS v
           FROM v_tx t
          WHERE ((t.amount < (0)::numeric) AND (t.category_kind = 'despesa'::text) AND (t.month >= ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval))::date))
        ), base AS MATERIALIZED (
         SELECT m.mes,
            f.id,
            f.name,
            f.category_id,
            f.channel,
            f.payee_key,
            f.match_pattern
           FROM (meses m
             JOIN fixed_expenses f ON ((f.is_active AND (m.mes >= date_trunc('month'::text, (f.start_month)::timestamp with time zone)) AND ((f.end_month IS NULL) OR (m.mes <= date_trunc('month'::text, (f.end_month)::timestamp with time zone))))))
        ), pagos AS (
         SELECT b_1.mes,
            b_1.id,
            sum(t.v) AS pago
           FROM (base b_1
             JOIN tx t ON (((t.month = b_1.mes) AND (((b_1.payee_key IS NOT NULL) AND (t.pk = b_1.payee_key)) OR ((b_1.match_pattern IS NOT NULL) AND (t.nt ~~ (('%'::text || b_1.match_pattern) || '%'::text))) OR ((b_1.payee_key IS NULL) AND (b_1.match_pattern IS NULL) AND (t.category_id = b_1.category_id))))))
          GROUP BY b_1.mes, b_1.id
        )
 SELECT b.mes AS month,
    b.id AS fixed_expense_id,
    b.name,
    b.category_id,
    COALESCE(c.parent_id, c.id) AS group_id,
    b.channel,
    dv.amount AS devido,
    COALESCE(p.pago, (0)::numeric) AS pago
   FROM (((base b
     LEFT JOIN categories c ON ((c.id = b.category_id)))
     LEFT JOIN pagos p ON (((p.mes = b.mes) AND (p.id = b.id))))
     LEFT JOIN LATERAL ( SELECT v.amount
           FROM fixed_expense_values v
          WHERE ((v.fixed_expense_id = b.id) AND (v.valid_from <= b.mes))
          ORDER BY v.valid_from DESC
         LIMIT 1) dv ON (true));

create or replace view public.v_goals with (security_invoker = on) as
 SELECT id,
    name,
    target_amount,
    target_date,
    progress_source,
    current_amount,
    monthly_contribution,
    status,
    notes,
    created_at,
    updated_at,
        CASE progress_source
            WHEN 'manual'::text THEN COALESCE(current_amount, (0)::numeric)
            WHEN 'investimentos'::text THEN ( SELECT v_net_worth.investimentos
               FROM v_net_worth)
            ELSE ( SELECT (v_net_worth.poupanca + v_net_worth.investimentos)
               FROM v_net_worth)
        END AS progresso,
    round((((100)::numeric *
        CASE progress_source
            WHEN 'manual'::text THEN COALESCE(current_amount, (0)::numeric)
            WHEN 'investimentos'::text THEN ( SELECT v_net_worth.investimentos
               FROM v_net_worth)
            ELSE ( SELECT (v_net_worth.poupanca + v_net_worth.investimentos)
               FROM v_net_worth)
        END) / NULLIF(target_amount, (0)::numeric))) AS pct
   FROM goals g
  WHERE (status <> 'cancelada'::text);

create or replace view public.v_group_channel with (security_invoker = on) as
 WITH m AS (
         SELECT ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval))::date AS ini,
            ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval))::date AS fim
        )
 SELECT v.group_id,
    max(v.group_name) AS group_name,
    round(((- sum(v.amount) FILTER (WHERE (a.type = 'BANK'::text))) / (6)::numeric), 2) AS conta_mes,
    round(((- sum(v.amount) FILTER (WHERE (a.type = 'CREDIT'::text))) / (6)::numeric), 2) AS cartao_mes,
    round((((100)::numeric * sum(v.amount) FILTER (WHERE (a.type = 'CREDIT'::text))) / NULLIF(sum(v.amount), (0)::numeric))) AS pct_cartao
   FROM (v_tx v
     JOIN accounts a ON ((a.id = v.account_id))),
    m
  WHERE ((v.category_kind = 'despesa'::text) AND ((v.month >= m.ini) AND (v.month <= m.fim)))
  GROUP BY v.group_id;

create or replace view public.v_group_items with (security_invoker = on) as
 WITH m AS (
         SELECT ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval))::date AS ini,
            ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval))::date AS fim
        ), x AS (
         SELECT v.group_id,
            v.category_id,
            v.category_name,
            a.type,
            initcap(TRIM(BOTH FROM regexp_replace(regexp_replace(COALESCE(NULLIF(v.counterpart_name, ''::text), "left"(norm_text(v.description), 30)), '(parc\s*)?[0-9/*]+'::text, ' '::text, 'gi'::text), '\s+'::text, ' '::text, 'g'::text))) AS payee,
            v.month,
            v.amount,
            v.event_date
           FROM (v_tx v
             JOIN accounts a ON ((a.id = v.account_id))),
            m
          WHERE ((v.category_kind = 'despesa'::text) AND ((v.month >= m.ini) AND (v.month <= m.fim)))
        )
 SELECT group_id,
    category_id,
    max(category_name) AS category_name,
    lower(payee) AS payee_key,
    max(payee) AS payee,
        CASE
            WHEN (sum(amount) FILTER (WHERE (type = 'CREDIT'::text)) IS NULL) THEN 'conta'::text
            WHEN (sum(amount) FILTER (WHERE (type = 'BANK'::text)) IS NULL) THEN 'cartao'::text
            ELSE 'ambos'::text
        END AS canal,
    count(DISTINCT month) AS meses,
    count(*) AS n,
    round(((- sum(amount)) / (6)::numeric), 2) AS media_6m,
    round(((- sum(amount)) / (count(DISTINCT month))::numeric), 2) AS media_quando_ocorre,
    max(event_date) AS ultimo
   FROM x
  GROUP BY group_id, category_id, (lower(payee));

create or replace view public.v_meta_base with (security_invoker = on) as
 WITH per AS (
         SELECT ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval))::date AS ini,
            ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval))::date AS fim
        ), meses AS (
         SELECT (generate_series((per.ini)::timestamp with time zone, (per.fim)::timestamp with time zone, '1 mon'::interval))::date AS mes
           FROM per
        ), fe AS MATERIALIZED (
         SELECT fixed_expenses.id,
            fixed_expenses.category_id,
            fixed_expenses.payee_key,
            fixed_expenses.match_pattern
           FROM fixed_expenses
          WHERE fixed_expenses.is_active
        ), tx AS MATERIALIZED (
         SELECT t.month,
            t.group_id,
            t.category_id,
            (- t.amount) AS v,
            (COALESCE(t.installment_total, 1) > 1) AS parc,
            payee_key_of(t.counterpart_name, t.description) AS pk,
            norm_text(((COALESCE(t.counterpart_name, ''::text) || ' '::text) || t.description)) AS nt
           FROM v_tx t,
            per
          WHERE ((t.amount < (0)::numeric) AND (t.category_kind = 'despesa'::text) AND ((t.month >= per.ini) AND (t.month <= per.fim)))
        ), cls AS MATERIALIZED (
         SELECT tx.month,
            tx.group_id,
            tx.category_id,
            tx.v,
            tx.parc,
            tx.pk,
            tx.nt,
            (EXISTS ( SELECT 1
                   FROM fe
                  WHERE (((fe.payee_key IS NOT NULL) AND (fe.payee_key = tx.pk)) OR ((fe.match_pattern IS NOT NULL) AND (tx.nt ~~ (('%'::text || fe.match_pattern) || '%'::text))) OR ((fe.payee_key IS NULL) AND (fe.match_pattern IS NULL) AND (fe.category_id = tx.category_id))))) AS fixo
           FROM tx
        ), grupos AS (
         SELECT DISTINCT cls.group_id
           FROM cls
        ), mm AS (
         SELECT m.mes,
            g.group_id,
            COALESCE(sum(c.v) FILTER (WHERE ((NOT c.fixo) AND (NOT c.parc))), (0)::numeric) AS variavel,
            COALESCE(sum(c.v) FILTER (WHERE c.fixo), (0)::numeric) AS fixo,
            COALESCE(sum(c.v) FILTER (WHERE (c.parc AND (NOT c.fixo))), (0)::numeric) AS parcelas
           FROM ((meses m
             CROSS JOIN grupos g)
             LEFT JOIN cls c ON (((c.month = m.mes) AND (c.group_id = g.group_id))))
          GROUP BY m.mes, g.group_id
        )
 SELECT mm.group_id,
    cat.name AS nome,
    round((percentile_cont((0.5)::double precision) WITHIN GROUP (ORDER BY ((mm.variavel)::double precision)))::numeric, 2) AS variavel_mediana,
    round(avg(mm.variavel), 2) AS variavel_media,
    round(avg(mm.fixo), 2) AS fixo_media,
    round(avg(mm.parcelas), 2) AS parcelas_media,
    jsonb_object_agg(to_char((mm.mes)::timestamp with time zone, 'YYYY-MM'::text), round(mm.variavel)) AS variavel_por_mes
   FROM (mm
     LEFT JOIN categories cat ON ((cat.id = mm.group_id)))
  GROUP BY mm.group_id, cat.name;

create or replace view public.v_meta_items with (security_invoker = on) as
 WITH per AS (
         SELECT ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval))::date AS ini,
            (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date AS atual
        ), fe AS MATERIALIZED (
         SELECT fixed_expenses.category_id,
            fixed_expenses.payee_key,
            fixed_expenses.match_pattern
           FROM fixed_expenses
          WHERE fixed_expenses.is_active
        ), tx AS MATERIALIZED (
         SELECT t.month,
            t.group_id,
            t.category_id,
            t.category_name,
            a.type AS acc_type,
            (- t.amount) AS v,
            (COALESCE(t.installment_total, 1) > 1) AS parc,
            (COALESCE(t.installment_total, 1) > 1) AS parcelado,
            payee_key_of(t.counterpart_name, t.description) AS pk,
            norm_text(((COALESCE(t.counterpart_name, ''::text) || ' '::text) || t.description)) AS nt,
            initcap(TRIM(BOTH FROM regexp_replace(regexp_replace(COALESCE(NULLIF(t.counterpart_name, ''::text), "left"(t.description, 30)), '(parc\s*)?[0-9/*]+'::text, ' '::text, 'gi'::text), '\s+'::text, ' '::text, 'g'::text))) AS payee
           FROM (v_tx t
             JOIN accounts a ON ((a.id = t.account_id))),
            per per_1
          WHERE ((t.amount < (0)::numeric) AND (t.category_kind = 'despesa'::text) AND ((t.month >= per_1.ini) AND (t.month <= per_1.atual)))
        ), cls AS MATERIALIZED (
         SELECT tx.month,
            tx.group_id,
            tx.category_id,
            tx.category_name,
            tx.acc_type,
            tx.v,
            tx.parc,
            tx.parcelado,
            tx.pk,
            tx.nt,
            tx.payee
           FROM tx
          WHERE ((NOT tx.parc) AND (NOT (EXISTS ( SELECT 1
                   FROM fe
                  WHERE (((fe.payee_key IS NOT NULL) AND (fe.payee_key = tx.pk)) OR ((fe.match_pattern IS NOT NULL) AND (tx.nt ~~ (('%'::text || fe.match_pattern) || '%'::text))) OR ((fe.payee_key IS NULL) AND (fe.match_pattern IS NULL) AND (fe.category_id = tx.category_id)))))))
        )
 SELECT c.group_id,
    c.pk AS payee_key,
    max(c.payee) AS payee,
    max(c.category_name) AS category_name,
        CASE
            WHEN bool_and((c.acc_type = 'CREDIT'::text)) THEN 'cartao'::text
            WHEN bool_and((c.acc_type = 'BANK'::text)) THEN 'conta'::text
            ELSE 'ambos'::text
        END AS canal,
    count(DISTINCT c.month) FILTER (WHERE (c.month < per.atual)) AS meses,
    count(*) FILTER (WHERE (c.month < per.atual)) AS n,
    round(COALESCE(sum(c.v) FILTER (WHERE (c.month < per.atual)), (0)::numeric), 2) AS total_6m,
    round((COALESCE(sum(c.v) FILTER (WHERE (c.month < per.atual)), (0)::numeric) / (6)::numeric), 2) AS media_6m,
    round(COALESCE(sum(c.v) FILTER (WHERE (c.month = per.atual)), (0)::numeric), 2) AS mes_atual,
    bool_or(c.parcelado) AS tem_parcelado
   FROM cls c,
    per
  GROUP BY c.group_id, c.pk;

create or replace view public.v_month_commitments with (security_invoker = on) as
 WITH parc_lancadas AS (
         SELECT v.month AS mes,
            v.group_id,
            (- sum(v.amount)) AS v,
            count(*) AS n
           FROM v_tx v
          WHERE ((v.account_subtype = 'CREDIT_CARD'::text) AND (COALESCE(v.installment_number, 1) >= 2))
          GROUP BY v.month, v.group_id
        ), parc_futuras AS (
         SELECT f.competence_month AS mes,
            f.group_id,
            sum(f.valor) AS v,
            count(*) AS n
           FROM v_card_future_installments f
          WHERE (NOT (EXISTS ( SELECT 1
                   FROM parc_lancadas p_1
                  WHERE (p_1.mes = f.competence_month))))
          GROUP BY f.competence_month, f.group_id
        ), parc AS (
         SELECT parc_lancadas.mes,
            parc_lancadas.group_id,
            parc_lancadas.v,
            parc_lancadas.n
           FROM parc_lancadas
        UNION ALL
         SELECT parc_futuras.mes,
            parc_futuras.group_id,
            parc_futuras.v,
            parc_futuras.n
           FROM parc_futuras
        ), comp AS (
         SELECT fm.month AS mes,
            fm.group_id,
            fm.name,
            COALESCE(fm.devido, (0)::numeric) AS devido,
            fm.pago
           FROM v_fixed_month fm
          WHERE (fm.month >= (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date)
        )
 SELECT COALESCE(p.mes, k.mes) AS month,
    COALESCE(p.group_id, k.group_id) AS group_id,
    COALESCE(p.v, (0)::numeric) AS parcelas_cartao,
    COALESCE(p.n, (0)::numeric) AS n_parcelas,
    COALESCE(k.pendente, (0)::numeric) AS compromissos_pendentes,
    k.nomes
   FROM (( SELECT parc.mes,
            parc.group_id,
            sum(parc.v) AS v,
            sum(parc.n) AS n
           FROM parc
          GROUP BY parc.mes, parc.group_id) p
     FULL JOIN ( SELECT comp.mes,
            comp.group_id,
            sum(GREATEST((comp.devido - comp.pago), (0)::numeric)) AS pendente,
            string_agg(comp.name, ', '::text ORDER BY comp.devido DESC) FILTER (WHERE ((comp.devido - comp.pago) > 0.5)) AS nomes
           FROM comp
          GROUP BY comp.mes, comp.group_id) k ON (((k.mes = p.mes) AND (k.group_id = p.group_id))));

create or replace view public.v_month_summary with (security_invoker = on) as
 SELECT month,
    sum(amount) FILTER (WHERE (category_kind = 'receita'::text)) AS receitas,
    sum(amount) FILTER (WHERE ((category_kind = 'despesa'::text) OR (category_kind IS NULL))) AS despesas,
    sum(amount) FILTER (WHERE (category_kind = 'investimento'::text)) AS investimentos,
    (sum(amount) FILTER (WHERE (category_kind = 'receita'::text)) + sum(amount) FILTER (WHERE ((category_kind = 'despesa'::text) OR (category_kind IS NULL)))) AS resultado,
    count(*) FILTER (WHERE (review_status = 'pending'::text)) AS pendentes,
    sum(abs(amount)) FILTER (WHERE (review_status = 'pending'::text)) AS valor_pendente
   FROM v_tx
  WHERE (category_kind IS DISTINCT FROM 'transferencia'::text)
  GROUP BY month;

create or replace view public.v_sim_base with (security_invoker = on) as
 WITH meses AS (
         SELECT (generate_series((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval), (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval), '1 mon'::interval))::date AS mes
        ), rec AS (
         SELECT percentile_cont((0.5)::double precision) WITHIN GROUP (ORDER BY ((COALESCE(s.receitas, (0)::numeric))::double precision)) AS v,
            jsonb_agg(jsonb_build_object('mes', m.mes, 'receitas', COALESCE(s.receitas, (0)::numeric), 'despesas', (- COALESCE(s.despesas, (0)::numeric))) ORDER BY m.mes) AS hist
           FROM (meses m
             LEFT JOIN v_month_summary s ON ((s.month = m.mes)))
        ), grp AS (
         SELECT g.group_id,
            max(c2.name) AS nome,
            percentile_cont((0.5)::double precision) WITHIN GROUP (ORDER BY ((COALESCE(x.gasto, (0)::numeric))::double precision)) AS mediana
           FROM (((( SELECT DISTINCT v_category_month.group_id
                   FROM v_category_month
                  WHERE (v_category_month.category_kind = 'despesa'::text)) g
             CROSS JOIN meses m)
             LEFT JOIN ( SELECT v_category_month.month,
                    v_category_month.group_id,
                    (- sum(v_category_month.total)) AS gasto
                   FROM v_category_month
                  WHERE (v_category_month.category_kind = 'despesa'::text)
                  GROUP BY v_category_month.month, v_category_month.group_id) x ON (((x.month = m.mes) AND (x.group_id = g.group_id))))
             LEFT JOIN categories c2 ON ((c2.id = g.group_id)))
          GROUP BY g.group_id
        ), fat AS (
         SELECT COALESCE(sum(v_card_bills.total_lancamentos), (0)::numeric) AS v
           FROM v_card_bills
          WHERE (v_card_bills.status = 'fechada'::text)
        )
 SELECT ( SELECT rec.v
           FROM rec) AS receita_mensal,
    ( SELECT rec.hist
           FROM rec) AS historico,
    ( SELECT jsonb_agg(jsonb_build_object('group_id', grp.group_id, 'nome', grp.nome, 'mediana', round((grp.mediana)::numeric, 2)) ORDER BY grp.mediana DESC) AS jsonb_agg
           FROM grp
          WHERE (grp.mediana > (0)::double precision)) AS despesas_grupo,
    ( SELECT jsonb_agg(jsonb_build_object('id', commitments.id, 'nome', commitments.name, 'tipo', commitments.kind, 'categoria', commitments.category_id, 'parcela', commitments.monthly_amount, 'fim', commitments.end_date, 'saldo_devedor', commitments.outstanding_balance)) AS jsonb_agg
           FROM commitments
          WHERE commitments.is_active) AS compromissos,
    ( SELECT jsonb_agg(jsonb_build_object('mes', f.competence_month, 'valor', f.v)) AS jsonb_agg
           FROM ( SELECT v_card_future_installments.competence_month,
                    sum(v_card_future_installments.valor) AS v
                   FROM v_card_future_installments
                  GROUP BY v_card_future_installments.competence_month) f) AS parcelas_cartao,
    (conta_corrente + poupanca) AS liquidez_imediata,
    investimentos,
    cartao_utilizado,
    financiamentos_saldo,
    ( SELECT fat.v
           FROM fat) AS fatura_fechada_a_pagar,
    ( SELECT jsonb_agg(jsonb_build_object('nome', v_goals.name, 'alvo', v_goals.target_amount, 'progresso', v_goals.progresso, 'status', v_goals.status)) AS jsonb_agg
           FROM v_goals) AS metas,
    (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date AS mes_base
   FROM v_net_worth n;

create or replace view public.v_alerts with (security_invoker = on) as
 SELECT v_alerts_base.kind,
    v_alerts_base.severity,
    v_alerts_base.title,
    v_alerts_base.detail,
    v_alerts_base.amount,
    v_alerts_base.ref_date
   FROM v_alerts_base
UNION ALL
 SELECT 'cartao_itau_teto'::text AS kind,
    'media'::text AS severity,
    ('Cartão Itaú acima do teto de R$ '::text || fmt_br(alert_param('cartao_itau_teto'::text), 'FM999G999'::text)) AS title,
    ((('Último boleto: R$ '::text || fmt_br((- t.amount), 'FM999G999D00'::text)) || ' em '::text) || fmt_br((t.event_date)::timestamp with time zone, 'DD/MM'::text)) AS detail,
    (- t.amount) AS amount,
    t.event_date AS ref_date
   FROM ( SELECT transactions.amount,
            transactions.event_date
           FROM transactions
          WHERE (transactions.category_id = 'cartao_itau'::text)
          ORDER BY transactions.event_date DESC
         LIMIT 1) t
  WHERE ((- t.amount) > alert_param('cartao_itau_teto'::text));

create or replace view public.v_budget_month with (security_invoker = on) as
 WITH m AS (
         SELECT (generate_series(('2025-11-01'::date)::timestamp with time zone, (((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) + '1 year'::interval))::date)::timestamp with time zone, '1 mon'::interval))::date AS mes
        ), b AS (
         SELECT DISTINCT ON (bm.mes, bu.group_id) bm.mes,
            bu.group_id,
            bu.amount,
            bu.source
           FROM (m bm
             JOIN budgets bu ON (((bu.month = bm.mes) OR (bu.month = '1900-01-01'::date))))
          ORDER BY bm.mes, bu.group_id, bu.month DESC
        ), r AS (
         SELECT v_category_month.month AS mes,
            v_category_month.group_id,
            v_category_month.group_name,
            (- sum(v_category_month.total)) AS gasto
           FROM v_category_month
          WHERE (v_category_month.category_kind = 'despesa'::text)
          GROUP BY v_category_month.month, v_category_month.group_id, v_category_month.group_name
        )
 SELECT COALESCE(b.mes, r.mes) AS month,
    COALESCE(b.group_id, r.group_id) AS group_id,
    COALESCE(r.group_name, c.name) AS group_name,
    COALESCE(b.amount, (0)::numeric) AS orcado,
    b.source,
    COALESCE(r.gasto, (0)::numeric) AS gasto,
    (COALESCE(b.amount, (0)::numeric) - COALESCE(r.gasto, (0)::numeric)) AS saldo,
        CASE
            WHEN (COALESCE(b.amount, (0)::numeric) > (0)::numeric) THEN round((((100)::numeric * COALESCE(r.gasto, (0)::numeric)) / b.amount))
            ELSE NULL::numeric
        END AS pct
   FROM ((b
     FULL JOIN r ON (((r.mes = b.mes) AND (r.group_id = b.group_id))))
     LEFT JOIN categories c ON ((c.id = COALESCE(b.group_id, r.group_id))));

create or replace view public.v_fixed_expenses with (security_invoker = on) as
 WITH fm AS (
         SELECT v_fixed_month.fixed_expense_id,
            max(v_fixed_month.pago) FILTER (WHERE (v_fixed_month.month = (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date)) AS pago_mes,
            max(v_fixed_month.pago) FILTER (WHERE (v_fixed_month.month = ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval))::date)) AS pago_mes_anterior
           FROM v_fixed_month
          WHERE ((v_fixed_month.month >= ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval))::date) AND (v_fixed_month.month <= (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date))
          GROUP BY v_fixed_month.fixed_expense_id
        ), vals AS (
         SELECT fixed_expense_values.fixed_expense_id,
            ((array_agg(fixed_expense_values.amount ORDER BY fixed_expense_values.valid_from DESC) FILTER (WHERE (fixed_expense_values.valid_from <= date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))))[1])::numeric(14,2) AS valor_atual,
            max(fixed_expense_values.valid_from) FILTER (WHERE (fixed_expense_values.valid_from <= date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))) AS valor_desde,
            ((array_agg(fixed_expense_values.amount ORDER BY fixed_expense_values.valid_from) FILTER (WHERE (fixed_expense_values.valid_from > date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))))[1])::numeric(14,2) AS proximo_valor,
            min(fixed_expense_values.valid_from) FILTER (WHERE (fixed_expense_values.valid_from > date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))) AS proximo_desde,
            count(*) AS n_valores
           FROM fixed_expense_values
          GROUP BY fixed_expense_values.fixed_expense_id
        )
 SELECT f.id,
    f.name,
    f.category_id,
    f.payee_key,
    f.match_pattern,
    f.channel,
    f.due_day,
    f.start_month,
    f.end_month,
    f.is_active,
    f.commitment_id,
    f.notes,
    f.source,
    f.created_at,
    f.updated_at,
    f.updated_by,
    COALESCE(c.parent_id, c.id) AS group_id,
    c.name AS category_name,
    g.name AS group_name,
    vals.valor_atual,
    vals.valor_desde,
    vals.proximo_valor,
    vals.proximo_desde,
    COALESCE(vals.n_valores, (0)::bigint) AS n_valores,
    fm.pago_mes,
    fm.pago_mes_anterior
   FROM ((((fixed_expenses f
     LEFT JOIN categories c ON ((c.id = f.category_id)))
     LEFT JOIN categories g ON ((g.id = COALESCE(c.parent_id, c.id))))
     LEFT JOIN vals ON ((vals.fixed_expense_id = f.id)))
     LEFT JOIN fm ON ((fm.fixed_expense_id = f.id)));

-- policies.sql
alter table public.account_balance_history enable row level security;
alter table public.accounts enable row level security;
alter table public.alert_settings enable row level security;
alter table public.app_settings enable row level security;
alter table public.assets enable row level security;
alter table public.audit_logs enable row level security;
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


-- triggers.sql
CREATE TRIGGER trg_accounts_updated BEFORE UPDATE ON public.accounts FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_card_statements_updated BEFORE UPDATE ON public.card_statements FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_classification_rules_updated BEFORE UPDATE ON public.classification_rules FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_connections_updated BEFORE UPDATE ON public.connections FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_transactions_updated BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- grants.sql
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


-- login novo vira membro pelo e-mail cadastrado
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_auth_user();
