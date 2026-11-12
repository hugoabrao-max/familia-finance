-- Família Finance AI — migração 0001: núcleo de ingestão (Pluggy / Meu Pluggy)
create extension if not exists pgcrypto;
create extension if not exists pg_cron;
create extension if not exists pg_net;

create table households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  display_name text not null,
  role text not null default 'member' check (role in ('owner','admin','member','viewer')),
  auth_user_id uuid unique,
  created_at timestamptz not null default now()
);

create table financial_institutions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  compe_code text,
  provider_connector_id int,
  unique (name)
);

create table connections (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id),
  holder_member_id uuid references household_members(id),
  provider text not null default 'pluggy',
  provider_item_id text not null unique,
  connector_id int,
  connector_name text,
  institution_id uuid references financial_institutions(id),
  status text,
  execution_status text,
  status_detail jsonb,
  consent_expires_at timestamptz,
  provider_updated_at timestamptz,
  last_sync_at timestamptz,
  is_active boolean not null default true,
  raw jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table connection_consents (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references connections(id) on delete cascade,
  consent_expires_at timestamptz,
  status text,
  observed_at timestamptz not null default now()
);

create table accounts (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references connections(id) on delete cascade,
  provider_account_id text not null unique,
  type text not null,
  subtype text,
  name text,
  marketing_name text,
  number text,
  owner text,
  currency text not null default 'BRL',
  balance numeric(14,2),
  credit_limit numeric(14,2),
  available_credit_limit numeric(14,2),
  bill_due_day int,
  bill_closing_day int,
  tax_number text,
  is_active boolean not null default true,
  raw jsonb,
  balance_observed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table account_balance_history (
  id bigserial primary key,
  account_id uuid not null references accounts(id) on delete cascade,
  balance numeric(14,2) not null,
  observed_at timestamptz not null default now()
);
create index on account_balance_history (account_id, observed_at desc);

create table card_statements (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references accounts(id) on delete cascade,
  provider_bill_id text not null unique,
  due_date date,
  closing_date date,
  total_amount numeric(14,2),
  minimum_payment numeric(14,2),
  allows_installments boolean,
  finance_charges jsonb,
  raw jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table raw_transactions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references accounts(id) on delete cascade,
  provider_tx_id text not null unique,
  payload jsonb not null,
  payload_hash text not null,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  changed_count int not null default 0,
  missing_since timestamptz
);
create index on raw_transactions (account_id, last_seen_at);

create table transactions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references accounts(id) on delete cascade,
  raw_transaction_id uuid references raw_transactions(id),
  source text not null default 'pluggy',
  source_ref text,
  event_date date not null,
  event_at timestamptz,
  amount numeric(14,2) not null,
  currency text not null default 'BRL',
  description text not null,
  description_raw text,
  provider_code text,
  type text,
  status text not null default 'POSTED',
  operation_type text,
  payment_data jsonb,
  merchant jsonb,
  installment_number int,
  installment_total int,
  bill_closing_date date,
  bill_forecast_date date,
  balance_after numeric(14,2),
  provider_category text,
  is_deleted_at_source boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source, source_ref)
);
create index on transactions (account_id, event_date desc);
create index on transactions (event_date desc);

create table investment_positions (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references connections(id) on delete cascade,
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
  observed_at timestamptz not null default now(),
  unique (provider_investment_id, observed_at)
);
create index on investment_positions (connection_id, observed_at desc);

create table sync_jobs (
  id uuid primary key default gen_random_uuid(),
  trigger text not null default 'cron',
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  status text not null default 'RUNNING',
  connections_total int default 0,
  accounts_total int default 0,
  tx_fetched int default 0,
  tx_new int default 0,
  tx_updated int default 0,
  bills_upserted int default 0,
  investments_upserted int default 0,
  summary jsonb
);

create table sync_errors (
  id bigserial primary key,
  sync_job_id uuid references sync_jobs(id) on delete cascade,
  connection_id uuid references connections(id),
  account_id uuid references accounts(id),
  stage text not null,
  message text not null,
  detail jsonb,
  created_at timestamptz not null default now()
);

create table app_settings (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

create or replace function set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

do $$ declare t text;
begin
  foreach t in array array['connections','accounts','card_statements','transactions']
  loop execute format('create trigger trg_%s_updated before update on %I for each row execute function set_updated_at()', t, t);
  end loop;
end $$;

do $$ declare t text;
begin
  foreach t in array array['households','household_members','financial_institutions','connections','connection_consents',
    'accounts','account_balance_history','card_statements','raw_transactions','transactions','investment_positions',
    'sync_jobs','sync_errors','app_settings']
  loop execute format('alter table %I enable row level security', t);
  end loop;
end $$;

insert into households (id, name) values ('00000000-0000-0000-0000-000000000001', 'Família Abrão');
insert into household_members (household_id, display_name, role)
  values ('00000000-0000-0000-0000-000000000001', 'Hugo', 'owner');
insert into financial_institutions (name, compe_code) values ('Banco Santander (Brasil) S.A.', '033');
insert into app_settings (key, value) values ('sync_token', encode(gen_random_bytes(32), 'hex'));

