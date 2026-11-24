-- 0039: ajustes de cálculo (auditoria P2). Mesmas colunas; nenhum dado alterado.
-- v_month_summary: resultado não vira vazio quando o mês não tem receita (ou despesa) classificada.
-- v_card_bills: status usa a data de corte especial (cutoff_date) quando existe (regra 8); n_lancamentos ignora suspeitas de duplicidade, como o total.
-- v_card_future_installments: compras parceladas iguais (mesma loja, mesmo nº de parcelas) não se fundem mais; a compra é identificada também pelo mês de início.
-- v_fixed_month: cada pagamento conta em uma só conta fixa (prioridade: chave do favorecido > padrão do texto > categoria).
create or replace view public.v_month_summary with (security_invoker = on) as
 SELECT month,
    sum(amount) FILTER (WHERE (category_kind = 'receita'::text)) AS receitas,
    sum(amount) FILTER (WHERE ((category_kind = 'despesa'::text) OR (category_kind IS NULL))) AS despesas,
    sum(amount) FILTER (WHERE (category_kind = 'investimento'::text)) AS investimentos,
    (COALESCE(sum(amount) FILTER (WHERE (category_kind = 'receita'::text)), (0)::numeric) + COALESCE(sum(amount) FILTER (WHERE ((category_kind = 'despesa'::text) OR (category_kind IS NULL))), (0)::numeric)) AS resultado,
    count(*) FILTER (WHERE (review_status = 'pending'::text)) AS pendentes,
    sum(abs(amount)) FILTER (WHERE (review_status = 'pending'::text)) AS valor_pendente
   FROM v_tx
  WHERE (category_kind IS DISTINCT FROM 'transferencia'::text)
  GROUP BY month;
create or replace view public.v_card_bills with (security_invoker = on) as
 SELECT account_id,
    closing_date,
    due_date,
    source,
    (date_trunc('month'::text, (closing_date)::timestamp with time zone))::date AS competence_month,
    COALESCE(( SELECT (- sum(t.amount))
           FROM (transactions t
             LEFT JOIN categories k ON ((k.id = t.category_id)))
          WHERE ((t.account_id = c.account_id) AND (t.bill_closing_date = c.closing_date) AND (NOT t.is_deleted_at_source) AND (t.reconciliation IS DISTINCT FROM 'duplicate_suspect'::text) AND (k.kind IS DISTINCT FROM 'transferencia'::text))), (0)::numeric) AS total_lancamentos,
    ( SELECT count(*) AS count
           FROM (transactions t
             LEFT JOIN categories k ON ((k.id = t.category_id)))
          WHERE ((t.account_id = c.account_id) AND (t.bill_closing_date = c.closing_date) AND (NOT t.is_deleted_at_source) AND (t.reconciliation IS DISTINCT FROM 'duplicate_suspect'::text) AND (k.kind IS DISTINCT FROM 'transferencia'::text))) AS n_lancamentos,
    pdf_total,
    paid_amount,
    paid_transaction_id,
        CASE
            WHEN (paid_transaction_id IS NOT NULL) THEN 'paga'::text
            WHEN (COALESCE(cutoff_date, closing_date) < ((now() AT TIME ZONE 'America/Cuiaba'::text))::date) THEN 'fechada'::text
            ELSE 'aberta'::text
        END AS status
   FROM card_bill_cycles c
  WHERE (NOT superseded);
create or replace view public.v_card_future_installments with (security_invoker = on) as
 WITH s AS (
         SELECT t.account_id,
            norm_text(t.description) AS chave,
            t.installment_total AS tt,
            max(t.installment_number) AS n,
            (array_agg(t.description ORDER BY t.installment_number DESC))[1] AS description,
            (array_agg(t.holder_name ORDER BY t.installment_number DESC))[1] AS holder_name,
            (array_agg((- t.amount) ORDER BY t.installment_number DESC))[1] AS valor,
            (array_agg(t.category_id ORDER BY t.installment_number DESC))[1] AS category_id,
            max(t.bill_closing_date) AS ult_fechamento
           FROM (transactions t
             JOIN accounts a ON (((a.id = t.account_id) AND (a.type = 'CREDIT'::text))))
          WHERE ((t.installment_total > 1) AND (NOT t.is_deleted_at_source))
          GROUP BY t.account_id, (norm_text(t.description)), t.installment_total, ((date_trunc('month'::text, (COALESCE(t.bill_closing_date, t.event_date))::timestamp with time zone) - (((t.installment_number - 1) || ' month'::text))::interval))
        )
 SELECT s.description,
    s.holder_name,
    s.n AS parcela_atual,
    s.tt AS total_parcelas,
    s.valor,
    ((date_trunc('month'::text, (COALESCE(s.ult_fechamento, ((now() AT TIME ZONE 'America/Cuiaba'::text))::date))::timestamp with time zone) + ((g.i || ' month'::text))::interval))::date AS competence_month,
    s.category_id,
    COALESCE(c.parent_id, c.id, 'outros'::text) AS group_id,
    (s.n + g.i) AS parcela_no_mes
   FROM (s
     LEFT JOIN categories c ON ((c.id = s.category_id))),
    generate_series(1, 36) g(i)
  WHERE ((s.n < s.tt) AND (g.i <= (s.tt - s.n)) AND (((date_trunc('month'::text, (COALESCE(s.ult_fechamento, ((now() AT TIME ZONE 'America/Cuiaba'::text))::date))::timestamp with time zone) + ((g.i || ' month'::text))::interval))::date >= (date_trunc('month'::text, (((now() AT TIME ZONE 'America/Cuiaba'::text))::date)::timestamp with time zone))::date));
create or replace view public.v_fixed_month with (security_invoker = on) as
 WITH meses AS (
         SELECT (generate_series((date_trunc('month'::text, (((now() AT TIME ZONE 'America/Cuiaba'::text))::date)::timestamp with time zone) - '6 mons'::interval), (date_trunc('month'::text, (((now() AT TIME ZONE 'America/Cuiaba'::text))::date)::timestamp with time zone) + '1 year'::interval), '1 mon'::interval))::date AS mes
        ), tx AS MATERIALIZED (
         SELECT t.id AS tid,
            t.month,
            t.category_id,
            payee_key_of(t.counterpart_name, t.description) AS pk,
            norm_text(((COALESCE(t.counterpart_name, ''::text) || ' '::text) || t.description)) AS nt,
            (- t.amount) AS v
           FROM v_tx t
          WHERE ((t.amount < (0)::numeric) AND (t.category_kind = 'despesa'::text) AND (t.month >= ((date_trunc('month'::text, (((now() AT TIME ZONE 'America/Cuiaba'::text))::date)::timestamp with time zone) - '6 mons'::interval))::date))
        ), base AS MATERIALIZED (
         SELECT m.mes,
            f.id,
            f.name,
            f.category_id,
            f.channel,
            f.payee_key,
            f.match_pattern
           FROM (meses m
             JOIN fixed_expenses f ON ((f.is_active AND (m.mes >= date_trunc('month'::text, (f.start_month)::timestamp with time zone)) AND ((f.end_month IS NULL) OR (m.mes <= date_trunc('month'::text, (f.end_month)::timestamp with time zone))))))
        ), pagos AS (
         SELECT x.mes,
            x.id,
            sum(x.v) AS pago
           FROM ( SELECT DISTINCT ON (b_1.mes, t.tid) b_1.mes,
                    b_1.id,
                    t.v
                   FROM (base b_1
                     JOIN tx t ON (((t.month = b_1.mes) AND (((b_1.payee_key IS NOT NULL) AND (t.pk = b_1.payee_key)) OR ((b_1.match_pattern IS NOT NULL) AND (t.nt ~~ (('%'::text || b_1.match_pattern) || '%'::text))) OR ((b_1.payee_key IS NULL) AND (b_1.match_pattern IS NULL) AND (t.category_id = b_1.category_id))))))
                  ORDER BY b_1.mes, t.tid,
                        CASE
                            WHEN ((b_1.payee_key IS NOT NULL) AND (t.pk = b_1.payee_key)) THEN 1
                            WHEN ((b_1.match_pattern IS NOT NULL) AND (t.nt ~~ (('%'::text || b_1.match_pattern) || '%'::text))) THEN 2
                            ELSE 3
                        END, b_1.id) x
          GROUP BY x.mes, x.id
        )
 SELECT b.mes AS month,
    b.id AS fixed_expense_id,
    b.name,
    b.category_id,
    COALESCE(c.parent_id, c.id) AS group_id,
    b.channel,
    dv.amount AS devido,
    COALESCE(p.pago, (0)::numeric) AS pago
   FROM (((base b
     LEFT JOIN categories c ON ((c.id = b.category_id)))
     LEFT JOIN pagos p ON (((p.mes = b.mes) AND (p.id = b.id))))
     LEFT JOIN LATERAL ( SELECT v.amount
           FROM fixed_expense_values v
          WHERE ((v.fixed_expense_id = b.id) AND (v.valid_from <= b.mes))
          ORDER BY v.valid_from DESC
         LIMIT 1) dv ON (true));
