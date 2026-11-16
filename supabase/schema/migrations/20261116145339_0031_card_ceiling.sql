-- Teto da fatura do cartão: por mês de fatura (da aberta até +6), quanto já está comprometido em parcelas
-- (lançadas e a lançar), quanto já foi gasto à vista/1ª parcela, e quanto sobra do teto para gastos variáveis.
-- Teto em plan_settings('teto_fatura'), definido pelo usuário. Contas fixas no cartão NÃO entram no comprometido
-- (uma delas pode ser a própria parcela, e contaria duas vezes): aparecem como gasto quando lançadas.
create or replace view public.v_card_teto with (security_invoker = on) as
with teto as (select value from plan_settings where key = 'teto_fatura'),
m0 as (select coalesce(min(competence_month), date_trunc('month', current_date)::date) as m from v_card_bills where status = 'aberta'),
meses as (select (m0.m + (g.i || ' month')::interval)::date as mes, g.i from m0, generate_series(0, 6) g(i)),
lanc as (
  select date_trunc('month', t.bill_closing_date)::date as mes,
         sum(-t.amount) filter (where coalesce(t.installment_number, 1) >= 2) as parc,
         sum(-t.amount) filter (where coalesce(t.installment_number, 1) < 2) as avista
  from v_tx t
  where t.account_subtype = 'CREDIT_CARD' and t.bill_closing_date is not null and t.category_kind is distinct from 'transferencia'
  group by 1),
fut as (select competence_month as mes, sum(valor) as v from v_card_future_installments group by 1),
fech as (select competence_month as mes, min(closing_date) as fecha, min(due_date) as vence from v_card_bills where status <> 'paga' group by 1)
select ms.mes,
       f.fecha,
       f.vence,
       case when ms.i = 0 then 'aberta' else 'futura' end as situacao,
       (select value from teto) as teto,
       round(coalesce(l.parc, 0), 2) as parcelas_lancadas,
       round(coalesce(fu.v, 0), 2) as parcelas_a_lancar,
       round(coalesce(l.parc, 0) + coalesce(fu.v, 0), 2) as comprometido,
       round(coalesce(l.avista, 0), 2) as gasto_variavel,
       round((select value from teto) - coalesce(l.parc, 0) - coalesce(fu.v, 0) - coalesce(l.avista, 0), 2) as livre,
       case when f.fecha is not null and f.fecha >= (now() at time zone 'America/Cuiaba')::date
            then (f.fecha - (now() at time zone 'America/Cuiaba')::date) end as dias_ate_fechar
from meses ms
left join lanc l on l.mes = ms.mes
left join fut fu on fu.mes = ms.mes
left join fech f on f.mes = ms.mes
order by ms.mes;
