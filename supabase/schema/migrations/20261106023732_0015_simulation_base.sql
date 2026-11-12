
-- Base para simulações (item 13). Só leitura; cenários salvos não alteram dados reais.
create or replace view public.v_sim_base with (security_invoker = true) as
with meses as (select generate_series(date_trunc('month', current_date) - interval '6 month', date_trunc('month', current_date) - interval '1 month', '1 month')::date as mes),
rec as (select percentile_cont(0.5) within group (order by coalesce(s.receitas,0)) as v,
               jsonb_agg(jsonb_build_object('mes', m.mes, 'receitas', coalesce(s.receitas,0), 'despesas', -coalesce(s.despesas,0)) order by m.mes) as hist
        from meses m left join v_month_summary s on s.month = m.mes),
grp as (select g.group_id, max(c2.name) as nome, percentile_cont(0.5) within group (order by coalesce(x.gasto,0)) as mediana
        from (select distinct group_id from v_category_month where category_kind='despesa') g
        cross join meses m
        left join (select month, group_id, -sum(total) as gasto from v_category_month where category_kind='despesa' group by 1,2) x on x.month=m.mes and x.group_id=g.group_id
        left join categories c2 on c2.id=g.group_id
        group by g.group_id),
fat as (select coalesce(sum(total_lancamentos),0) as v from v_card_bills where status='fechada')
select
  (select v from rec) as receita_mensal,
  (select hist from rec) as historico,
  (select jsonb_agg(jsonb_build_object('group_id', group_id, 'nome', nome, 'mediana', round(mediana::numeric,2)) order by mediana desc) from grp where mediana > 0) as despesas_grupo,
  (select jsonb_agg(jsonb_build_object('id', id, 'nome', name, 'tipo', kind, 'categoria', category_id, 'parcela', monthly_amount, 'fim', end_date, 'saldo_devedor', outstanding_balance)) from commitments where is_active) as compromissos,
  (select jsonb_agg(jsonb_build_object('mes', competence_month, 'valor', v)) from (select competence_month, sum(valor) as v from v_card_future_installments group by 1) f) as parcelas_cartao,
  n.conta_corrente + n.poupanca as liquidez_imediata, n.investimentos, n.cartao_utilizado, n.financiamentos_saldo,
  (select v from fat) as fatura_fechada_a_pagar,
  (select jsonb_agg(jsonb_build_object('nome', name, 'alvo', target_amount, 'progresso', progresso, 'status', status)) from v_goals) as metas,
  date_trunc('month', current_date)::date as mes_base
from v_net_worth n;

create table if not exists public.sim_scenarios (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  params jsonb not null,
  created_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.sim_scenarios enable row level security;
create policy ss_read on public.sim_scenarios for select to authenticated using (true);
create policy ss_write on public.sim_scenarios for all to authenticated using (can_edit()) with check (can_edit());
grant select on public.v_sim_base to authenticated;

