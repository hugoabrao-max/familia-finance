
create or replace function public.payee_key_of(p_counterpart text, p_description text) returns text
language sql stable set search_path=public as $$
  select lower(trim(regexp_replace(regexp_replace(coalesce(nullif(p_counterpart,''), left(norm_text(p_description),30)),'(parc\s*)?[0-9/*]+',' ','gi'),'\s+',' ','g')))
$$;

create table if not exists public.fixed_expenses(
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category_id text not null references categories(id),
  payee_key text,
  match_pattern text,
  channel text not null default 'conta' check (channel in ('conta','cartao')),
  due_day int check (due_day between 1 and 31),
  start_month date not null default date_trunc('month',current_date)::date,
  end_month date,
  is_active boolean not null default true,
  commitment_id uuid references commitments(id),
  notes text,
  source text not null default 'hugo',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid
);
create table if not exists public.fixed_expense_values(
  id uuid primary key default gen_random_uuid(),
  fixed_expense_id uuid not null references fixed_expenses(id),
  valid_from date not null,
  amount numeric(14,2) not null check (amount>=0),
  note text,
  created_at timestamptz not null default now(),
  created_by uuid,
  unique(fixed_expense_id, valid_from)
);
alter table fixed_expenses enable row level security;
alter table fixed_expense_values enable row level security;
create policy fe_read on fixed_expenses for select to authenticated using (true);
create policy fe_write on fixed_expenses for all to authenticated using (can_edit()) with check (can_edit());
create policy fev_read on fixed_expense_values for select to authenticated using (true);
create policy fev_write on fixed_expense_values for all to authenticated using (can_edit()) with check (can_edit());

-- valor devido e pago por mês (6 meses atrás até 12 à frente)
create or replace view public.v_fixed_month with (security_invoker=on) as
with meses as (
  select generate_series(date_trunc('month',current_date)-interval '6 months', date_trunc('month',current_date)+interval '12 months', interval '1 month')::date as mes
)
select m.mes as month, f.id as fixed_expense_id, f.name, f.category_id, coalesce(c.parent_id,c.id) as group_id, f.channel,
  (select v.amount from fixed_expense_values v where v.fixed_expense_id=f.id and v.valid_from<=m.mes order by v.valid_from desc limit 1) as devido,
  coalesce((select -sum(t.amount) from v_tx t where t.month=m.mes and t.amount<0 and t.category_kind='despesa' and (
      (f.payee_key is not null and payee_key_of(t.counterpart_name,t.description)=f.payee_key)
   or (f.match_pattern is not null and norm_text(coalesce(t.counterpart_name,'')||' '||t.description) like '%'||f.match_pattern||'%')
   or (f.payee_key is null and f.match_pattern is null and t.category_id=f.category_id))),0) as pago
from meses m
join fixed_expenses f on f.is_active and m.mes>=date_trunc('month',f.start_month) and (f.end_month is null or m.mes<=date_trunc('month',f.end_month))
left join categories c on c.id=f.category_id;

create or replace view public.v_fixed_expenses with (security_invoker=on) as
select f.*, coalesce(c.parent_id,c.id) as group_id, c.name as category_name, g.name as group_name,
  (select v.amount from fixed_expense_values v where v.fixed_expense_id=f.id and v.valid_from<=date_trunc('month',current_date) order by v.valid_from desc limit 1) as valor_atual,
  (select v.valid_from from fixed_expense_values v where v.fixed_expense_id=f.id and v.valid_from<=date_trunc('month',current_date) order by v.valid_from desc limit 1) as valor_desde,
  (select v.amount from fixed_expense_values v where v.fixed_expense_id=f.id and v.valid_from>date_trunc('month',current_date) order by v.valid_from limit 1) as proximo_valor,
  (select v.valid_from from fixed_expense_values v where v.fixed_expense_id=f.id and v.valid_from>date_trunc('month',current_date) order by v.valid_from limit 1) as proximo_desde,
  (select count(*) from fixed_expense_values v where v.fixed_expense_id=f.id) as n_valores,
  (select fm.pago from v_fixed_month fm where fm.fixed_expense_id=f.id and fm.month=date_trunc('month',current_date)::date) as pago_mes,
  (select fm.pago from v_fixed_month fm where fm.fixed_expense_id=f.id and fm.month=(date_trunc('month',current_date)-interval '1 month')::date) as pago_mes_anterior
from fixed_expenses f left join categories c on c.id=f.category_id left join categories g on g.id=coalesce(c.parent_id,c.id);

-- compromissos do mês passam a vir do cadastro de despesas fixas
create or replace view public.v_month_commitments with (security_invoker=on) as
with parc_lancadas as (
  select v.month as mes, v.group_id, -sum(v.amount) as v, count(*) as n from v_tx v
  where v.account_subtype='CREDIT_CARD' and coalesce(v.installment_number,1)>=2 group by v.month, v.group_id
), parc_futuras as (
  select f.competence_month as mes, f.group_id, sum(f.valor) as v, count(*) as n from v_card_future_installments f
  where not exists (select 1 from parc_lancadas p where p.mes=f.competence_month) group by f.competence_month, f.group_id
), parc as (select * from parc_lancadas union all select * from parc_futuras),
comp as (
  select fm.month as mes, fm.group_id, fm.name, coalesce(fm.devido,0) as devido, fm.pago
  from v_fixed_month fm where fm.month>=date_trunc('month',current_date)::date
)
select coalesce(p.mes,k.mes) as month, coalesce(p.group_id,k.group_id) as group_id,
  coalesce(p.v,0) as parcelas_cartao, coalesce(p.n,0) as n_parcelas,
  coalesce(k.pendente,0) as compromissos_pendentes, k.nomes
from (select mes, group_id, sum(v) v, sum(n) n from parc group by mes, group_id) p
full join (select mes, group_id, sum(greatest(devido-pago,0)) as pendente, string_agg(name, ', ' order by devido desc) filter (where devido-pago>0.5) as nomes from comp group by mes, group_id) k
  on k.mes=p.mes and k.group_id=p.group_id;

-- carga inicial: compromissos cadastrados + itens marcados/identificados como fixos
insert into fixed_expenses(name,category_id,payee_key,match_pattern,channel,end_month,commitment_id,notes,source,start_month)
select c.name, c.category_id,
  case c.category_id when 'financiamento_imobiliario' then 'prest cr im' when 'condominio' then null else null end,
  case when c.category_id='financiamento_imobiliario' then null else c.match_pattern end,
  'conta', date_trunc('month',c.end_date)::date, c.id, c.notes, 'compromisso', '2026-05-01'
from commitments c where c.is_active and not exists (select 1 from fixed_expenses f where f.commitment_id=c.id);
insert into fixed_expense_values(fixed_expense_id,valid_from,amount,note)
select f.id,'2026-05-01',c.monthly_amount,'valor do compromisso cadastrado' from fixed_expenses f join commitments c on c.id=f.commitment_id
on conflict do nothing;

with cand as (
  select i.*, fi.is_fixed manual from v_group_items i left join fixed_items fi on fi.group_id=i.group_id and fi.payee_key=i.payee_key
  where coalesce(fi.is_fixed, i.meses>=5 and i.canal<>'cartao')
    and i.payee_key not in ('cacau show','periodo: a','prest cr im','condominio edificio america tower','partnerbank instituicao de pagamento s.a.','allianz segu d','allianz seguros s a','allianz seguros s')
), ins as (
  insert into fixed_expenses(name,category_id,payee_key,channel,notes,source,start_month)
  select initcap(payee), category_id, payee_key, case when canal='cartao' then 'cartao' else 'conta' end,
    case when meses>=5 then 'Valor inicial: média dos meses em que houve pagamento' else 'Pagamento irregular ('||meses||' de 6 meses): valor inicial é a média mensal — confira' end,
    'sugerido','2026-05-01'
  from cand where not exists (select 1 from fixed_expenses f where f.payee_key=cand.payee_key)
  returning id, payee_key
)
insert into fixed_expense_values(fixed_expense_id,valid_from,amount,note)
select ins.id,'2026-05-01', case when c.meses>=5 then c.media_quando_ocorre else c.media_6m end, 'carga inicial (histórico mai–out/26)'
from ins join cand c on c.payee_key=ins.payee_key;

insert into fixed_expenses(name,category_id,match_pattern,channel,notes,source,start_month)
select 'Seguro Allianz','seguros','allianz','cartao','Pagamentos irregulares (cartão e conta): valor inicial é a média mensal — confira','sugerido','2026-05-01'
where not exists (select 1 from fixed_expenses where match_pattern='allianz');
insert into fixed_expense_values(fixed_expense_id,valid_from,amount,note)
select id,'2026-05-01',364.32,'carga inicial (média mai–out/26)' from fixed_expenses where match_pattern='allianz' on conflict do nothing;

