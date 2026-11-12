
-- Classes de flexibilidade por grupo de despesa (editáveis pelo Hugo)
create table if not exists public.category_flex (
  group_id text primary key references categories(id),
  classe text not null check (classe in ('fixa','essencial','ajustavel','discricionaria')),
  max_cut_pct numeric not null check (max_cut_pct between 0 and 100),
  source text not null default 'proposta' check (source in ('proposta','hugo')),
  updated_at timestamptz not null default now()
);
alter table public.category_flex enable row level security;
create policy cf_read on public.category_flex for select to authenticated using (true);
create policy cf_write on public.category_flex for all to authenticated using (can_edit()) with check (can_edit());
insert into public.category_flex (group_id, classe, max_cut_pct) values
 ('moradia','fixa',0),('educacao','fixa',0),('equipe_domestica','fixa',0),('apoio_familiar','fixa',0),('impostos_taxas','fixa',0),('seguros','fixa',0),('veiculos','fixa',0),('despesas_financeiras','fixa',0),
 ('alimentacao','essencial',10),('saude','essencial',10),('transporte','essencial',10),
 ('compras','ajustavel',30),('outros','ajustavel',30),('assinaturas','ajustavel',30),
 ('lazer','discricionaria',50)
on conflict (group_id) do nothing;

-- Parâmetros do plano (meta de sobra mensal etc.)
create table if not exists public.plan_settings (
  key text primary key, value numeric, text_value text, updated_at timestamptz not null default now(), updated_by uuid);
alter table public.plan_settings enable row level security;
create policy ps_read on public.plan_settings for select to authenticated using (true);
create policy ps_write on public.plan_settings for all to authenticated using (can_edit()) with check (can_edit());
insert into public.plan_settings (key, value, text_value) values ('sobra_meta', 10000, 'Meta de sobra mensal para a reserva (fixa)') on conflict (key) do nothing;

-- Canal de pagamento por grupo (6 meses fechados): conta (PIX, transferência, boleto, débito) × cartão de crédito
create or replace view public.v_group_channel with (security_invoker = true) as
with m as (select (date_trunc('month', current_date) - interval '6 month')::date as ini, (date_trunc('month', current_date) - interval '1 month')::date as fim)
select v.group_id, max(v.group_name) as group_name,
  round(-sum(v.amount) filter (where a.type='BANK')/6, 2) as conta_mes,
  round(-sum(v.amount) filter (where a.type='CREDIT')/6, 2) as cartao_mes,
  round(100 * sum(v.amount) filter (where a.type='CREDIT') / nullif(sum(v.amount),0)) as pct_cartao
from v_tx v join accounts a on a.id=v.account_id, m
where v.category_kind='despesa' and v.month between m.ini and m.fim
group by v.group_id;
grant select on public.v_group_channel to authenticated;

