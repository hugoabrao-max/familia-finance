
insert into categories (id, parent_id, name, kind, sort, is_active) values
 ('cartao_itau','compras','Cartão Itaú (pequenas compras do mês)','despesa', 55, true),
 ('compras_online','compras','Compras on-line (Mercado Livre)','despesa', 56, true),
 ('nao_identificado','outros','Não identificado (histórico)','despesa', 990, true)
on conflict (id) do nothing;

-- Itaú: boleto do cartão extra = despesa do mês (o cartão não está conectado)
update classification_rules set category_id='cartao_itau', origin='usuario', confidence=1.0,
  history = history || jsonb_build_object('em', now(), 'de', 'pagamento_cartao', 'para', 'cartao_itau', 'motivo', 'Hugo 06/11: cartão extra para pequenas compras, até R$ 1,5 mil')
 where id='d447b04e-6e26-4a4c-ba16-7c638d452d55';

-- Mercado Livre = compras on-line (vence as regras antigas de prioridade 100)
insert into classification_rules (rule_type, pattern, category_id, origin, confidence, priority, example)
values ('merchant_contains','mercadolivre','compras_online','usuario',0.95,50,'MERCADOLIVRE*...'),
       ('merchant_contains','mercado livre','compras_online','usuario',0.95,50,'MERCADO LIVRE ...')
on conflict (rule_type, pattern) do update set category_id=excluded.category_id, origin='usuario', priority=50, confidence=0.95;

-- Teto do cartão Itaú para alerta
insert into alert_settings values ('cartao_itau_teto', 1500, 'valor máximo mensal combinado para o cartão Itaú') on conflict (key) do nothing;

alter view public.v_alerts rename to v_alerts_base;
create view public.v_alerts with (security_invoker = true) as
select * from v_alerts_base
union all
select 'cartao_itau_teto', 'media',
  'Cartão Itaú acima do teto de R$ ' || to_char(alert_param('cartao_itau_teto'),'FM999G999'),
  'Último boleto: R$ ' || to_char(-t.amount,'FM999G999D00') || ' em ' || to_char(t.event_date,'DD/MM'),
  -t.amount, t.event_date
from (select amount, event_date from transactions where category_id='cartao_itau' order by event_date desc limit 1) t
where -t.amount > alert_param('cartao_itau_teto');
grant select on public.v_alerts to authenticated;

