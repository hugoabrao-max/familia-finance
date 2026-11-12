CREATE OR REPLACE FUNCTION public.reconcile_all()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n_transfer int; n_card int; n_refund int; n_dup int;
begin
  -- 1. Transferências entre contas próprias: mesmo valor absoluto, sentidos opostos, contas diferentes, até 2 dias
  with pairs as (
    select a.id as out_id, b.id as in_id,
      row_number() over (partition by a.id order by abs(b.event_date - a.event_date)) rn_a,
      row_number() over (partition by b.id order by abs(b.event_date - a.event_date)) rn_b
    from transactions a join transactions b
      on b.account_id <> a.account_id and b.amount = -a.amount and a.amount < 0
     and abs(b.event_date - a.event_date) <= 2
    where (a.category_id in ('transferencia_entre_contas') or b.category_id in ('transferencia_entre_contas')
           or norm_text(a.description) ~ '^(pix enviado|ted|transferencia)' and norm_text(b.description) ~ '^(pix recebido|ted|transferencia)')
      and not exists (select 1 from transaction_links l where l.kind='transfer' and (l.tx_a = a.id or l.tx_b = b.id))
  ), ins as (
    insert into transaction_links (kind, tx_a, tx_b, confidence, method)
    select 'transfer', out_id, in_id, 0.95, 'amount_opposite_2d' from pairs where rn_a = 1 and rn_b = 1
    on conflict do nothing returning tx_a, tx_b
  ), upd as (
    update transactions t set category_id = 'transferencia_entre_contas', category_source = coalesce(nullif(t.category_source,'pendente'), 'regra_sistema'), reconciliation = 'transfer_matched', review_status = 'auto'
    from ins where t.id in (ins.tx_a, ins.tx_b) and coalesce(t.category_source,'') <> 'ajuste_usuario' returning 1
  ) select count(*) into n_transfer from ins;

  -- 2. Pagamento de fatura: débito automático/pagamento na CC ↔ fatura do cartão (valor igual ±1, até 5 dias do vencimento)
  with cand as (
    select t.id as tx_id, s.id as st_id,
      row_number() over (partition by s.id order by abs(t.event_date - s.due_date)) rn
    from card_statements s join transactions t
      on t.category_id = 'pagamento_cartao' and t.amount < 0 and abs(-t.amount - s.total_amount) <= 1.00
     and abs(t.event_date - s.due_date) <= 5
    where s.paid_transaction_id is null
  ), ins as (
    insert into transaction_links (kind, tx_a, statement_id, confidence, method)
    select 'card_payment', tx_id, st_id, 0.95, 'amount_due_5d' from cand where rn = 1
    on conflict do nothing returning tx_a, statement_id
  ), u1 as (update card_statements s set paid_transaction_id = ins.tx_a from ins where s.id = ins.statement_id returning 1),
  u2 as (update transactions t set reconciliation = 'card_payment_matched' from ins where t.id = ins.tx_a returning 1)
  select count(*) into n_card from ins;

  -- 3. Estornos no cartão: crédito com mesmo valor e mesma contraparte/descrição de um débito até 60 dias antes
  with cand as (
    select d.id as debit_id, c.id as credit_id,
      row_number() over (partition by c.id order by c.event_date - d.event_date) rn
    from transactions c join transactions d
      on d.account_id = c.account_id and d.amount = -c.amount and d.amount < 0 and c.amount > 0
     and c.event_date between d.event_date and d.event_date + 60
     and norm_text(d.description) = norm_text(c.description)
    join accounts a on a.id = c.account_id and a.type = 'CREDIT'
    where not exists (select 1 from transaction_links l where l.kind = 'refund' and l.tx_b = c.id)
  ), ins as (
    insert into transaction_links (kind, tx_a, tx_b, confidence, method)
    select 'refund', debit_id, credit_id, 0.90, 'same_merchant_amount_60d' from cand where rn = 1
    on conflict do nothing returning tx_a, tx_b
  ), upd as (
    update transactions t set reconciliation = 'refund', category_id = d.category_id, category_source = 'regra_sistema'
    from ins join transactions d on d.id = ins.tx_a where t.id = ins.tx_b and coalesce(t.category_source,'') <> 'ajuste_usuario' returning 1
  ) select count(*) into n_refund from ins;

  -- 4. Duplicidades suspeitas: mesma conta, data, valor e descrição, origens diferentes (nunca apaga; só sinaliza)
  with dup as (
    select b.id
    from transactions a join transactions b
      on b.account_id = a.account_id and b.event_date = a.event_date and b.amount = a.amount
     and norm_text(b.description) = norm_text(a.description) and b.id <> a.id
     and (a.source <> b.source or a.provider_code is distinct from b.provider_code)
     and a.created_at < b.created_at
  ), ins as (
    insert into data_quality_issues (kind, severity, transaction_id, detail)
    select 'duplicate_suspect', 'high', id, jsonb_build_object('rule','same_account_date_amount_desc') from dup
    on conflict do nothing returning 1
  ) select count(*) into n_dup from ins;

  -- 5. Pendentes antigos (status PENDING há mais de 7 dias)
  insert into data_quality_issues (kind, severity, transaction_id, detail)
  select 'pending_stale', 'low', id, jsonb_build_object('since', event_date) from transactions
  where status = 'PENDING' and event_date < current_date - 7
  on conflict do nothing;

  return jsonb_build_object('transfers', n_transfer, 'card_payments', n_card, 'refunds', n_refund, 'duplicates', n_dup);
end $function$
;
