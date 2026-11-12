
-- Parâmetros de alerta (editáveis sem código)
create table if not exists public.alert_settings (
  key text primary key, value numeric not null, note text);
alter table public.alert_settings enable row level security;
create policy as_read on public.alert_settings for select to authenticated using (true);
insert into public.alert_settings values
 ('fatura_acima_media_pct', 15, 'fatura aberta projetada acima da média dos últimos 6 meses'),
 ('categoria_acima_media_pct', 25, 'gasto da categoria no mês acima do ritmo médio'),
 ('categoria_minimo_reais', 500, 'diferença mínima em R$ para alertar categoria'),
 ('compra_grande_reais', 3000, 'compra individual no cartão a destacar (últimos 7 dias)'),
 ('fatura_vence_dias', 5, 'dias de antecedência para avisar vencimento'),
 ('sync_atraso_horas', 26, 'horas sem sincronização bem-sucedida')
on conflict (key) do nothing;

create or replace function public.alert_param(k text) returns numeric language sql stable as
$$ select value from alert_settings where key = k $$;

-- Alertas calculados ao vivo (nunca gravam nada)
create or replace view public.v_alerts with (security_invoker = true) as
with hoje as (select (now() at time zone 'America/Cuiaba')::date d),
 mes as (select date_trunc('month', d)::date m, d, extract(day from d)::numeric dia,
          extract(day from (date_trunc('month', d) + interval '1 month - 1 day'))::numeric dias from hoje),
 cc as (select coalesce(sum(balance),0) saldo from accounts where type='BANK' and subtype='CHECKING_ACCOUNT' and is_active),
 aberta as (select * from v_card_bills where status in ('aberta','fechada') order by closing_date limit 1),
 media_fatura as (select avg(coalesce(paid_amount,total_lancamentos)) v from (select * from v_card_bills where status='paga' order by closing_date desc limit 6) x),
 cat_mes as (select group_id, group_name, -sum(amount) v from v_tx, mes where v_tx.month = mes.m and amount < 0
              and category_kind is distinct from 'transferencia' and category_kind is distinct from 'investimento' group by 1,2),
 cat_media as (select group_id, -sum(amount)/6.0 v from v_tx, mes where v_tx.month >= (mes.m - interval '6 month') and v_tx.month < mes.m and amount < 0
              and category_kind is distinct from 'transferencia' and category_kind is distinct from 'investimento' group by 1)
-- 1. Fatura a vencer x saldo da conta corrente
select 'fatura_vencimento'::text kind,
  case when a.total_lancamentos > (select saldo from cc) then 'alta' else 'media' end severity,
  'Fatura do cartão vence em ' || to_char(a.due_date,'DD/MM') as title,
  'Valor estimado R$ ' || to_char(a.total_lancamentos,'FM999G999D00') || '; saldo em conta R$ ' || to_char((select saldo from cc),'FM999G999D00') as detail,
  a.total_lancamentos amount, a.due_date ref_date
from aberta a, hoje where a.status='fechada' and a.due_date - hoje.d between 0 and alert_param('fatura_vence_dias')
union all
-- 2. Fatura em aberto acima da média
select 'fatura_acima_media', 'media',
  'Fatura em aberto já soma R$ ' || to_char(b.total_lancamentos,'FM999G999D00'),
  'Média das últimas 6 faturas: R$ ' || to_char(m.v,'FM999G999D00') || ' (' || round(100*(b.total_lancamentos/m.v-1)) || '% acima)',
  b.total_lancamentos, b.closing_date
from v_card_bills b, media_fatura m where b.status='aberta' and b.closing_date = (select min(closing_date) from v_card_bills where status='aberta')
  and m.v > 0 and b.total_lancamentos > m.v * (1 + alert_param('fatura_acima_media_pct')/100)
union all
-- 3. Categoria acima do ritmo médio (proporcional ao dia do mês)
select 'categoria_ritmo', 'media',
  c.group_name || ' acima do ritmo',
  'No mês: R$ ' || to_char(c.v,'FM999G999D00') || '; ritmo médio até hoje: R$ ' || to_char(cm.v*mes.dia/mes.dias,'FM999G999D00'),
  c.v - cm.v*mes.dia/mes.dias, mes.d
from cat_mes c join cat_media cm using (group_id), mes
where mes.dia >= 7 and c.v > cm.v*mes.dia/mes.dias * (1 + alert_param('categoria_acima_media_pct')/100)
  and c.v - cm.v*mes.dia/mes.dias > alert_param('categoria_minimo_reais')
union all
-- 4. Compras grandes recentes no cartão
select 'compra_grande', 'baixa',
  'Compra de R$ ' || to_char(-t.amount,'FM999G999D00') || ' em ' || t.description,
  coalesce(t.holder_name,'') || ' · ' || to_char(t.event_date,'DD/MM') || coalesce(' · ' || t.installment_number || '/' || t.installment_total,''),
  -t.amount, t.event_date
from v_tx t, hoje where t.account_subtype='CREDIT_CARD' and -t.amount >= alert_param('compra_grande_reais')
  and t.event_date >= hoje.d - 7 and coalesce(t.installment_number,1) = 1
union all
-- 5. Revisão pendente
select 'revisao_pendente', case when count(*) > 30 then 'media' else 'baixa' end,
  count(*) || ' lançamentos aguardando categoria',
  'Valor envolvido: R$ ' || to_char(sum(abs(amount)),'FM999G999D00'), sum(abs(amount)), null::date
from v_tx where category_id is null having count(*) > 0
union all
-- 6. Sincronização atrasada / consentimento
select 'sincronizacao', 'alta', 'Sincronização com o banco atrasada',
  'Última sincronização ok: ' || coalesce(to_char(s.last_ok_sync at time zone 'America/Cuiaba','DD/MM HH24:MI'),'nunca'), null, null
from v_sync_status s where s.last_ok_sync is null or s.last_ok_sync < now() - (alert_param('sync_atraso_horas') || ' hours')::interval
union all
select 'consentimento', 'alta', 'Autorização Open Finance vence em breve',
  'Vence em ' || to_char(s.consent_expires_at,'DD/MM/YYYY') || ' — renovar no Meu Pluggy', null, s.consent_expires_at::date
from v_sync_status s where s.consent_warning
union all
-- 7. Duplicidades a confirmar
select 'duplicidade', 'media', count(*) || ' possíveis duplicidades', 'Ocultas dos totais até confirmação', null, null
from data_quality_issues where kind='duplicate_suspect' and status='open' having count(*) > 0;

-- Fechamento mensal (item 12): checklist + snapshot imutável
create table if not exists public.monthly_closings (
  month date primary key,
  status text not null default 'fechado' check (status in ('fechado','reaberto')),
  snapshot jsonb not null,
  checklist jsonb not null,
  notes text,
  closed_at timestamptz not null default now(),
  closed_by uuid,
  history jsonb not null default '[]'::jsonb
);
alter table public.monthly_closings enable row level security;
create policy mc_read on public.monthly_closings for select to authenticated using (true);

create or replace function public.month_close_check(p_month date) returns jsonb
language sql stable security invoker set search_path to 'public' as $$
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
$$;

create or replace function public.close_month(p_month date, p_notes text default null, p_force boolean default false) returns jsonb
language plpgsql security definer set search_path to 'public' as $$
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
end $$;

create or replace function public.reopen_month(p_month date, p_reason text) returns void
language plpgsql security definer set search_path to 'public' as $$
declare mb household_members;
begin
  mb := current_member();
  if mb.id is null or mb.role not in ('owner','admin') then raise exception 'sem permissão'; end if;
  update monthly_closings set status='reaberto', history = history || jsonb_build_object('em', now(), 'acao', 'reaberto', 'motivo', p_reason)
   where month = date_trunc('month', p_month)::date;
  insert into audit_logs (table_name, row_id, action, actor, actor_label, after)
    values ('monthly_closings', p_month::text, 'reopen', mb.id, mb.display_name, jsonb_build_object('motivo', p_reason));
end $$;

grant execute on function public.month_close_check(date) to authenticated;
grant execute on function public.close_month(date, text, boolean) to authenticated;
grant execute on function public.reopen_month(date, text) to authenticated;
grant select on public.v_alerts, public.v_card_bills to authenticated;

