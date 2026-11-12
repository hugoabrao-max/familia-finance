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
