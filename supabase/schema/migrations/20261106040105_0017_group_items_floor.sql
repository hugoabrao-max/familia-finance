
-- Itens (estabelecimento/pessoa) de cada grupo nos 6 meses fechados, para conferir o piso de gastos
create or replace view public.v_group_items with (security_invoker = true) as
with m as (select (date_trunc('month', current_date) - interval '6 month')::date as ini, (date_trunc('month', current_date) - interval '1 month')::date as fim),
x as (
  select v.group_id, v.category_id, v.category_name, a.type,
    coalesce(nullif(v.counterpart_name,''), initcap(trim(regexp_replace(left(norm_text(v.description),30),'[0-9/*]+',' ','g')))) as payee,
    v.month, v.amount, v.event_date
  from v_tx v join accounts a on a.id=v.account_id, m
  where v.category_kind='despesa' and v.month between m.ini and m.fim)
select group_id, category_id, max(category_name) as category_name,
  lower(payee) as payee_key, max(payee) as payee,
  case when sum(amount) filter (where type='CREDIT') is null then 'conta'
       when sum(amount) filter (where type='BANK') is null then 'cartao' else 'ambos' end as canal,
  count(distinct month) as meses, count(*) as n,
  round(-sum(amount)/6, 2) as media_6m,
  round(-sum(amount)/count(distinct month), 2) as media_quando_ocorre,
  max(event_date) as ultimo
from x group by group_id, category_id, lower(payee);

create table if not exists public.fixed_items (
  group_id text not null, payee_key text not null,
  is_fixed boolean not null, note text,
  updated_at timestamptz not null default now(), updated_by uuid,
  primary key (group_id, payee_key));
alter table public.fixed_items enable row level security;
create policy fi_read on public.fixed_items for select to authenticated using (true);
create policy fi_write on public.fixed_items for all to authenticated using (can_edit()) with check (can_edit());
grant select on public.v_group_items to authenticated;

