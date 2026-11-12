create or replace view public.v_card_bills with (security_invoker = on) as
 SELECT account_id,
    closing_date,
    due_date,
    source,
    (date_trunc('month'::text, (closing_date)::timestamp with time zone))::date AS competence_month,
    COALESCE(( SELECT (- sum(t.amount))
           FROM transactions t
          WHERE ((t.account_id = c.account_id) AND (t.bill_closing_date = c.closing_date) AND (NOT t.is_deleted_at_source) AND (t.reconciliation IS DISTINCT FROM 'duplicate_suspect'::text))), (0)::numeric) AS total_lancamentos,
    ( SELECT count(*) AS count
           FROM transactions t
          WHERE ((t.account_id = c.account_id) AND (t.bill_closing_date = c.closing_date) AND (NOT t.is_deleted_at_source))) AS n_lancamentos,
    pdf_total,
    paid_amount,
    paid_transaction_id,
        CASE
            WHEN (paid_transaction_id IS NOT NULL) THEN 'paga'::text
            WHEN (closing_date < CURRENT_DATE) THEN 'fechada'::text
            ELSE 'aberta'::text
        END AS status
   FROM card_bill_cycles c
  WHERE (NOT superseded);
