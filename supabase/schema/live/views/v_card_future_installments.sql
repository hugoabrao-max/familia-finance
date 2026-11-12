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
          GROUP BY t.account_id, (norm_text(t.description)), t.installment_total
        )
 SELECT s.description,
    s.holder_name,
    s.n AS parcela_atual,
    s.tt AS total_parcelas,
    s.valor,
    ((date_trunc('month'::text, (COALESCE(s.ult_fechamento, CURRENT_DATE))::timestamp with time zone) + ((g.i || ' month'::text))::interval))::date AS competence_month,
    s.category_id,
    COALESCE(c.parent_id, c.id, 'outros'::text) AS group_id,
    (s.n + g.i) AS parcela_no_mes
   FROM (s
     LEFT JOIN categories c ON ((c.id = s.category_id))),
    generate_series(1, 36) g(i)
  WHERE ((s.n < s.tt) AND (g.i <= (s.tt - s.n)) AND (((date_trunc('month'::text, (COALESCE(s.ult_fechamento, CURRENT_DATE))::timestamp with time zone) + ((g.i || ' month'::text))::interval))::date >= (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date));
