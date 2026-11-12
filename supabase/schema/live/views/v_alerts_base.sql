create or replace view public.v_alerts_base with (security_invoker = on) as
 WITH hoje AS (
         SELECT ((now() AT TIME ZONE 'America/Cuiaba'::text))::date AS d
        ), mes AS (
         SELECT (date_trunc('month'::text, (hoje.d)::timestamp with time zone))::date AS m,
            hoje.d,
            EXTRACT(day FROM hoje.d) AS dia,
            EXTRACT(day FROM (date_trunc('month'::text, (hoje.d)::timestamp with time zone) + '1 mon -1 days'::interval)) AS dias
           FROM hoje
        ), cc AS (
         SELECT COALESCE(sum(accounts.balance), (0)::numeric) AS saldo
           FROM accounts
          WHERE ((accounts.type = 'BANK'::text) AND (accounts.subtype = 'CHECKING_ACCOUNT'::text) AND accounts.is_active)
        ), aberta AS (
         SELECT v_card_bills.account_id,
            v_card_bills.closing_date,
            v_card_bills.due_date,
            v_card_bills.source,
            v_card_bills.competence_month,
            v_card_bills.total_lancamentos,
            v_card_bills.n_lancamentos,
            v_card_bills.pdf_total,
            v_card_bills.paid_amount,
            v_card_bills.paid_transaction_id,
            v_card_bills.status
           FROM v_card_bills
          WHERE (v_card_bills.status = ANY (ARRAY['aberta'::text, 'fechada'::text]))
          ORDER BY v_card_bills.closing_date
         LIMIT 1
        ), media_fatura AS (
         SELECT avg(COALESCE(x.paid_amount, x.total_lancamentos)) AS v
           FROM ( SELECT v_card_bills.account_id,
                    v_card_bills.closing_date,
                    v_card_bills.due_date,
                    v_card_bills.source,
                    v_card_bills.competence_month,
                    v_card_bills.total_lancamentos,
                    v_card_bills.n_lancamentos,
                    v_card_bills.pdf_total,
                    v_card_bills.paid_amount,
                    v_card_bills.paid_transaction_id,
                    v_card_bills.status
                   FROM v_card_bills
                  WHERE (v_card_bills.status = 'paga'::text)
                  ORDER BY v_card_bills.closing_date DESC
                 LIMIT 6) x
        ), cat_mes AS (
         SELECT v_tx.group_id,
            v_tx.group_name,
            (- sum(v_tx.amount)) AS v
           FROM v_tx,
            mes
          WHERE ((v_tx.month = mes.m) AND (v_tx.amount < (0)::numeric) AND (v_tx.category_kind IS DISTINCT FROM 'transferencia'::text) AND (v_tx.category_kind IS DISTINCT FROM 'investimento'::text))
          GROUP BY v_tx.group_id, v_tx.group_name
        ), cat_media AS (
         SELECT v_tx.group_id,
            ((- sum(v_tx.amount)) / 6.0) AS v
           FROM v_tx,
            mes
          WHERE ((v_tx.month >= (mes.m - '6 mons'::interval)) AND (v_tx.month < mes.m) AND (v_tx.amount < (0)::numeric) AND (v_tx.category_kind IS DISTINCT FROM 'transferencia'::text) AND (v_tx.category_kind IS DISTINCT FROM 'investimento'::text))
          GROUP BY v_tx.group_id
        )
 SELECT 'fatura_vencimento'::text AS kind,
        CASE
            WHEN (a.total_lancamentos > ( SELECT cc.saldo
               FROM cc)) THEN 'alta'::text
            ELSE 'media'::text
        END AS severity,
    ('Fatura do cartão vence em '::text || fmt_br((a.due_date)::timestamp with time zone, 'DD/MM'::text)) AS title,
    ((('Valor estimado R$ '::text || fmt_br(a.total_lancamentos, 'FM999G999D00'::text)) || '; saldo em conta R$ '::text) || fmt_br(( SELECT cc.saldo
           FROM cc), 'FM999G999D00'::text)) AS detail,
    a.total_lancamentos AS amount,
    a.due_date AS ref_date
   FROM aberta a,
    hoje
  WHERE ((a.status = 'fechada'::text) AND (((a.due_date - hoje.d) >= 0) AND (((a.due_date - hoje.d))::numeric <= alert_param('fatura_vence_dias'::text))))
UNION ALL
 SELECT 'fatura_acima_media'::text AS kind,
    'media'::text AS severity,
    ('Fatura em aberto já soma R$ '::text || fmt_br(b.total_lancamentos, 'FM999G999D00'::text)) AS title,
    (((('Média das últimas 6 faturas: R$ '::text || fmt_br(m.v, 'FM999G999D00'::text)) || ' ('::text) || round(((100)::numeric * ((b.total_lancamentos / m.v) - (1)::numeric)))) || '% acima)'::text) AS detail,
    b.total_lancamentos AS amount,
    b.closing_date AS ref_date
   FROM v_card_bills b,
    media_fatura m
  WHERE ((b.status = 'aberta'::text) AND (b.closing_date = ( SELECT min(v_card_bills.closing_date) AS min
           FROM v_card_bills
          WHERE (v_card_bills.status = 'aberta'::text))) AND (m.v > (0)::numeric) AND (b.total_lancamentos > (m.v * ((1)::numeric + (alert_param('fatura_acima_media_pct'::text) / (100)::numeric)))))
UNION ALL
 SELECT 'categoria_ritmo'::text AS kind,
    'media'::text AS severity,
    (c.group_name || ' acima do ritmo'::text) AS title,
    ((('No mês: R$ '::text || fmt_br(c.v, 'FM999G999D00'::text)) || '; ritmo médio até hoje: R$ '::text) || fmt_br(((cm.v * mes.dia) / mes.dias), 'FM999G999D00'::text)) AS detail,
    (c.v - ((cm.v * mes.dia) / mes.dias)) AS amount,
    mes.d AS ref_date
   FROM (cat_mes c
     JOIN cat_media cm USING (group_id)),
    mes
  WHERE ((mes.dia >= (7)::numeric) AND (c.v > (((cm.v * mes.dia) / mes.dias) * ((1)::numeric + (alert_param('categoria_acima_media_pct'::text) / (100)::numeric)))) AND ((c.v - ((cm.v * mes.dia) / mes.dias)) > alert_param('categoria_minimo_reais'::text)))
UNION ALL
 SELECT 'compra_grande'::text AS kind,
    'baixa'::text AS severity,
    ((('Compra de R$ '::text || fmt_br((- t.amount), 'FM999G999D00'::text)) || ' em '::text) || t.description) AS title,
    (((COALESCE(t.holder_name, ''::text) || ' · '::text) || fmt_br((t.event_date)::timestamp with time zone, 'DD/MM'::text)) || COALESCE((((' · '::text || t.installment_number) || '/'::text) || t.installment_total), ''::text)) AS detail,
    (- t.amount) AS amount,
    t.event_date AS ref_date
   FROM v_tx t,
    hoje
  WHERE ((t.account_subtype = 'CREDIT_CARD'::text) AND ((- t.amount) >= alert_param('compra_grande_reais'::text)) AND (t.event_date >= (hoje.d - 7)) AND (COALESCE(t.installment_number, 1) = 1))
UNION ALL
 SELECT 'revisao_pendente'::text AS kind,
        CASE
            WHEN (count(*) > 30) THEN 'media'::text
            ELSE 'baixa'::text
        END AS severity,
    (count(*) || ' lançamentos aguardando categoria'::text) AS title,
    ('Valor envolvido: R$ '::text || fmt_br(sum(abs(v_tx.amount)), 'FM999G999D00'::text)) AS detail,
    sum(abs(v_tx.amount)) AS amount,
    NULL::date AS ref_date
   FROM v_tx
  WHERE (v_tx.category_id IS NULL)
 HAVING (count(*) > 0)
UNION ALL
 SELECT 'sincronizacao'::text AS kind,
    'alta'::text AS severity,
    'Sincronização com o banco atrasada'::text AS title,
    ('Última sincronização ok: '::text || COALESCE(fmt_br((s.last_ok_sync AT TIME ZONE 'America/Cuiaba'::text), 'DD/MM HH24:MI'::text), 'nunca'::text)) AS detail,
    NULL::numeric AS amount,
    NULL::date AS ref_date
   FROM v_sync_status s
  WHERE ((s.last_ok_sync IS NULL) OR (s.last_ok_sync < (now() - ((alert_param('sync_atraso_horas'::text) || ' hours'::text))::interval)))
UNION ALL
 SELECT 'consentimento'::text AS kind,
    'alta'::text AS severity,
    'Autorização Open Finance vence em breve'::text AS title,
    (('Vence em '::text || fmt_br(s.consent_expires_at, 'DD/MM/YYYY'::text)) || ' — renovar no Meu Pluggy'::text) AS detail,
    NULL::numeric AS amount,
    (s.consent_expires_at)::date AS ref_date
   FROM v_sync_status s
  WHERE s.consent_warning
UNION ALL
 SELECT 'duplicidade'::text AS kind,
    'media'::text AS severity,
    (count(*) || ' possíveis duplicidades'::text) AS title,
    'Ocultas dos totais até confirmação'::text AS detail,
    NULL::numeric AS amount,
    NULL::date AS ref_date
   FROM data_quality_issues
  WHERE ((data_quality_issues.kind = 'duplicate_suspect'::text) AND (data_quality_issues.status = 'open'::text))
 HAVING (count(*) > 0);
