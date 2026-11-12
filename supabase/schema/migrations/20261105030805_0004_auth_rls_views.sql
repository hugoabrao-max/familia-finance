-- 0004: autenticação por titular, RLS, views do painel, docs do projeto

alter table household_members add column if not exists email text unique;
update household_members set email = null where email = '';

-- vínculo automático: ao criar login, liga ao membro com o mesmo e-mail; se nenhum membro ainda tem login, o primeiro vira o owner
create or replace function public.handle_new_auth_user() returns trigger language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  select id into v_id from household_members where lower(email) = lower(new.email) and auth_user_id is null limit 1;
  if v_id is null and not exists (select 1 from household_members where auth_user_id is not null) then
    select id into v_id from household_members where role = 'owner' limit 1;
  end if;
  if v_id is not null then
    update household_members set auth_user_id = new.id, email = coalesce(email, new.email) where id = v_id;
  end if;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_auth_user();

create or replace function current_member() returns household_members language sql stable security definer set search_path = public as $$
  select * from household_members where auth_user_id = auth.uid() limit 1
$$;
create or replace function my_household() returns uuid language sql stable security definer set search_path = public as $$
  select household_id from household_members where auth_user_id = auth.uid() limit 1
$$;
create or replace function can_edit() returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role in ('owner','admin','member') from household_members where auth_user_id = auth.uid() limit 1), false)
$$;

-- Políticas: leitura para membros da unidade familiar; escrita gerencial restrita
create policy hm_select on household_members for select using (household_id = my_household());
create policy hh_select on households for select using (id = my_household());
create policy fi_select on financial_institutions for select using (auth.uid() is not null);
create policy conn_select on connections for select using (household_id = my_household());
create policy cc_select on connection_consents for select using (exists (select 1 from connections c where c.id = connection_id and c.household_id = my_household()));
create policy acc_select on accounts for select using (exists (select 1 from connections c where c.id = connection_id and c.household_id = my_household()));
create policy abh_select on account_balance_history for select using (exists (select 1 from accounts a join connections c on c.id = a.connection_id where a.id = account_id and c.household_id = my_household()));
create policy cs_select on card_statements for select using (exists (select 1 from accounts a join connections c on c.id = a.connection_id where a.id = account_id and c.household_id = my_household()));
create policy rt_select on raw_transactions for select using (exists (select 1 from accounts a join connections c on c.id = a.connection_id where a.id = account_id and c.household_id = my_household()));
create policy tx_select on transactions for select using (exists (select 1 from accounts a join connections c on c.id = a.connection_id where a.id = account_id and c.household_id = my_household()));
create policy ip_select on investment_positions for select using (exists (select 1 from connections c where c.id = connection_id and c.household_id = my_household()));
create policy sj_select on sync_jobs for select using (auth.uid() is not null);
create policy se_select on sync_errors for select using (auth.uid() is not null);
create policy cat_select on categories for select using (auth.uid() is not null);
create policy cr_select on classification_rules for select using (auth.uid() is not null);
create policy cr_write on classification_rules for all using (can_edit()) with check (can_edit());
create policy cf_select on classification_feedback for select using (auth.uid() is not null);
create policy ij_select on import_jobs for select using (auth.uid() is not null);
create policy al_select on audit_logs for select using (auth.uid() is not null);
-- app_settings: nada exposto (secrets internos); project_docs: leitura para todos os membros

create table project_docs (
  name text primary key,          -- README, CLAUDE, PROJECT_STATE, ...
  content text not null,
  updated_at timestamptz not null default now(),
  updated_by text
);
alter table project_docs enable row level security;
create policy pd_select on project_docs for select using (auth.uid() is not null);

-- Ajuste gerencial do usuário: nunca sobrescreve a origem; registra feedback, auditoria e, opcionalmente, cria regra
create or replace function set_transaction_category(p_tx uuid, p_category text, p_create_rule boolean default false, p_reason text default null)
returns void language plpgsql security definer set search_path = public as $$
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
    v_pattern := norm_text(coalesce(t.counterpart_name, split_part(t.description, '   ', 2), t.description));
    if length(v_pattern) >= 4 then
      insert into classification_rules (rule_type, pattern, category_id, origin, confidence, priority, example)
        values ('merchant_contains', v_pattern, p_category, 'usuario', 0.900, 90, t.description)
      on conflict (rule_type, pattern) do update set category_id = excluded.category_id, origin = 'usuario', confidence = 0.900,
        history = classification_rules.history || jsonb_build_object('em', now(), 'de', classification_rules.category_id, 'para', excluded.category_id);
      perform classify_transactions(true);
    end if;
  end if;
end $$;

-- Views do painel (visão gerencial: exclui transferências internas e pagamento de fatura; cartão por competência)
create or replace view v_tx as
  select t.*, a.subtype as account_subtype, a.name as account_name, c.name as category_name, c.kind as category_kind,
         coalesce(p.id, c.id) as group_id, coalesce(p.name, c.name) as group_name,
         coalesce(t.competence_month, date_trunc('month', t.event_date)::date) as month
  from transactions t
  join accounts a on a.id = t.account_id
  left join categories c on c.id = t.category_id
  left join categories p on p.id = c.parent_id
  where not t.is_deleted_at_source;

create or replace view v_month_summary as
  select month,
    sum(amount) filter (where category_kind = 'receita') as receitas,
    sum(amount) filter (where category_kind = 'despesa' or category_kind is null) as despesas,
    sum(amount) filter (where category_kind = 'investimento') as investimentos,
    sum(amount) filter (where category_kind = 'receita') + sum(amount) filter (where category_kind = 'despesa' or category_kind is null) as resultado,
    count(*) filter (where review_status = 'pending') as pendentes,
    sum(abs(amount)) filter (where review_status = 'pending') as valor_pendente
  from v_tx where category_kind is distinct from 'transferencia'
  group by month;

create or replace view v_category_month as
  select month, group_id, group_name, category_id, category_name, category_kind, count(*) as n, sum(amount) as total
  from v_tx where category_kind is distinct from 'transferencia' group by 1,2,3,4,5,6;

create or replace view v_daily_flow as
  select event_date, account_subtype,
    sum(amount) filter (where amount > 0 and category_kind is distinct from 'transferencia') as entradas,
    sum(amount) filter (where amount < 0 and category_kind is distinct from 'transferencia') as saidas,
    count(*) as n
  from v_tx group by 1,2;

create or replace view v_sync_status as
  select c.connector_name, c.status, c.execution_status, c.provider_updated_at, c.last_sync_at, c.consent_expires_at,
         (c.consent_expires_at - now()) < interval '30 days' as consent_warning,
         (select max(finished_at) from sync_jobs where status in ('SUCCESS','PARTIAL')) as last_ok_sync,
         (select status from sync_jobs order by started_at desc limit 1) as last_job_status,
         (select count(*) from sync_errors e join sync_jobs j on j.id = e.sync_job_id where j.started_at > now() - interval '7 days') as errors_7d
  from connections c where c.is_active;

