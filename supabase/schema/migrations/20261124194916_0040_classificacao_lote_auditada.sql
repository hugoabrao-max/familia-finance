-- 0040: reclassificação em lote reversível e registrada (CLAUDE.md regra 2) e correções da conciliação.
-- classify_transactions v2: não mexe em lançamento casado como transferência/estorno nem em mês fechado; só grava o que mudou;
--   cada mudança de categoria vai para audit_logs (antes/depois). Simulação em produção: 3.305 candidatos, 0 mudanças.
-- reconcile_all: troca de categoria por transferência/estorno registrada em audit_logs; duplicidade só entre origens diferentes.
-- detect_duplicates: duplicidade só entre origens diferentes (duas compras iguais no mesmo dia são legítimas); marcação registrada.
-- Nenhum dado alterado por esta migração.
CREATE OR REPLACE FUNCTION public.classify_transactions(p_only_unclassified boolean DEFAULT true)
 RETURNS TABLE(classified integer, pending integer)
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare v_classified int := 0; v_pending int := 0;
begin
  -- v2 (24/11/2026): não mexe em lançamento já casado como transferência/estorno (reconcile_all), nem em mês fechado;
  -- só grava o que mudou e registra cada mudança de categoria em audit_logs (reclassificação em lote reversível).
  with cand as (
    select t.id, norm_text(t.description) as nd, norm_text(coalesce(t.counterpart_name,'')) as nc,
           norm_text(t.description || ' ' || coalesce(t.counterpart_name,'')) as nall, t.operation_type,
           case when (r.payload->'creditCardMetadata'->>'payeeMCC') ~ '^\d+$' then (r.payload->'creditCardMetadata'->>'payeeMCC')::int end as mcc
    from transactions t left join raw_transactions r on r.id = t.raw_transaction_id
    where (not p_only_unclassified or t.category_id is null or t.category_source in ('regra_sistema','regra_estabelecimento','pluggy','padrao_operacao','pendente','mcc'))
      and coalesce(t.category_source,'') <> 'ajuste_usuario'
      and t.reconciliation is distinct from 'transfer_matched' and t.reconciliation is distinct from 'refund'
      and not exists (select 1 from monthly_closings mc where mc.status = 'fechado'
                      and mc.month = date_trunc('month', coalesce(t.competence_month, t.event_date))::date)
  ),
  matched as (
    select c.id, r.id as rule_id, r.category_id, r.confidence, r.rule_type, r.priority,
           row_number() over (partition by c.id order by r.priority, length(r.pattern) desc) as rn
    from cand c join classification_rules r on r.is_active and (
         (r.rule_type = 'payee_name' and (c.nc like r.pattern || '%' or c.nall like '%' || r.pattern || '%'))
      or (r.rule_type = 'description_regex' and c.nd ~ r.pattern)
      or (r.rule_type = 'merchant_contains' and c.nall like '%' || r.pattern || '%')
    )
  ),
  best as (select * from matched where rn = 1),
  fallback as (
    select c.id,
      case
        when c.operation_type = 'RENDIMENTO_APLIC_FINANCEIRA' then 'investimentos'
        when c.operation_type like 'ENCARGOS%' or c.nd like 'iof %' or c.nd like '%tarifa%' or c.nd like '%juros%' then 'despesas_financeiras'
        when c.nd like 'aplicacao%' or c.nd like 'resgate%' or c.nd like '%cdb%' then 'investimentos'
        when c.nd like 'pagamento de fatura%' or c.nd like 'deb autom de fatura%' or c.nd like 'pagto cartao%' then 'pagamento_cartao'
        when c.nd like 'transferencia entre contas%' or c.nd like '%transf entre contas%' then 'transferencia_entre_contas'
        else null end as category_id,
      m.category_id as mcc_category
    from cand c left join mcc_category_map m on m.mcc = c.mcc
    where c.id not in (select id from best)
  ),
  novo as (
    select c.id,
      coalesce(b.category_id, f.category_id, f.mcc_category) as category_id,
      case when b.id is not null then (case when b.rule_type = 'payee_name' then 'pessoa' when b.rule_type = 'description_regex' then 'regra_sistema' else 'regra_estabelecimento' end)
           when f.category_id is not null then 'padrao_operacao'
           when f.mcc_category is not null then 'mcc' else 'pendente' end as category_source,
      case when b.id is not null then b.confidence when f.category_id is not null then 0.800 when f.mcc_category is not null then 0.700 else null end as category_confidence,
      b.rule_id,
      case when b.id is not null or f.category_id is not null or f.mcc_category is not null then 'auto' else 'pending' end as review_status
    from cand c left join best b on b.id = c.id left join fallback f on f.id = c.id
  ),
  antes as (
    select t.id, t.category_id, t.category_source, t.category_confidence, t.rule_id, t.review_status
    from transactions t join novo n on n.id = t.id
    where (t.category_id, t.category_source, t.category_confidence, t.rule_id, t.review_status)
          is distinct from (n.category_id, n.category_source, n.category_confidence, n.rule_id, n.review_status)
  ),
  upd as (
    update transactions t set
      category_id = n.category_id, category_source = n.category_source, category_confidence = n.category_confidence,
      rule_id = n.rule_id, review_status = n.review_status
    from novo n join antes a on a.id = n.id
    where t.id = n.id
    returning t.id, t.category_id
  ),
  aud as (
    insert into audit_logs (table_name, row_id, action, actor_label, before, after)
    select 'transactions', a.id::text, 'reclassificacao_automatica', 'classify_transactions',
           jsonb_build_object('category_id', a.category_id, 'category_source', a.category_source, 'review_status', a.review_status),
           jsonb_build_object('category_id', n.category_id, 'category_source', n.category_source, 'review_status', n.review_status)
    from antes a join novo n on n.id = a.id
    where a.category_id is distinct from n.category_id
    returning 1
  )
  select (select count(*) from upd where category_id is not null), (select count(*) from novo where category_id is null)
    into v_classified, v_pending;
  return query select v_classified, v_pending;
end $function$
;
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
  ), antes as (
    select t.id, t.category_id, t.category_source from transactions t join ins on t.id in (ins.tx_a, ins.tx_b)
    where coalesce(t.category_source,'') <> 'ajuste_usuario'
  ), upd as (
    update transactions t set category_id = 'transferencia_entre_contas', category_source = coalesce(nullif(t.category_source,'pendente'), 'regra_sistema'), reconciliation = 'transfer_matched', review_status = 'auto'
    from antes a where t.id = a.id returning 1
  ), aud as (
    insert into audit_logs (table_name, row_id, action, actor_label, before, after)
    select 'transactions', a.id::text, 'conciliacao_transferencia', 'reconcile_all',
           jsonb_build_object('category_id', a.category_id, 'category_source', a.category_source),
           jsonb_build_object('category_id', 'transferencia_entre_contas', 'reconciliation', 'transfer_matched')
    from antes a where a.category_id is distinct from 'transferencia_entre_contas' returning 1
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
  ), antes as (
    select t.id, t.category_id, t.category_source, d.category_id as nova from ins join transactions t on t.id = ins.tx_b join transactions d on d.id = ins.tx_a
    where coalesce(t.category_source,'') <> 'ajuste_usuario'
  ), upd as (
    update transactions t set reconciliation = 'refund', category_id = a.nova, category_source = 'regra_sistema'
    from antes a where t.id = a.id returning 1
  ), aud as (
    insert into audit_logs (table_name, row_id, action, actor_label, before, after)
    select 'transactions', a.id::text, 'conciliacao_estorno', 'reconcile_all',
           jsonb_build_object('category_id', a.category_id, 'category_source', a.category_source),
           jsonb_build_object('category_id', a.nova, 'reconciliation', 'refund')
    from antes a where a.category_id is distinct from a.nova returning 1
  ) select count(*) into n_refund from ins;

  -- 4. Duplicidades suspeitas: mesma conta, data, valor e descrição, origens diferentes (nunca apaga; só sinaliza)
  with dup as (
    select b.id
    from transactions a join transactions b
      on b.account_id = a.account_id and b.event_date = a.event_date and b.amount = a.amount
     and norm_text(b.description) = norm_text(a.description) and b.id <> a.id
     and a.source <> b.source   -- v2 (24/11/2026): só entre origens diferentes (ex.: Pluggy × PDF); duas compras iguais no mesmo dia são legítimas
     and a.created_at < b.created_at
  ), ins as (
    insert into data_quality_issues (kind, severity, transaction_id, detail)
    select 'duplicate_suspect', 'high', id, jsonb_build_object('rule','same_account_date_amount_desc') from dup
    on conflict do nothing returning 1
  ) select count(*) into n_dup from ins;

  -- 5. Pendentes antigos (status PENDING há mais de 7 dias)
  insert into data_quality_issues (kind, severity, transaction_id, detail)
  select 'pending_stale', 'low', id, jsonb_build_object('since', event_date) from transactions
  where status = 'PENDING' and event_date < (now() at time zone 'America/Cuiaba')::date - 7
  on conflict do nothing;

  return jsonb_build_object('transfers', n_transfer, 'card_payments', n_card, 'refunds', n_refund, 'duplicates', n_dup);
end $function$
;
CREATE OR REPLACE FUNCTION public.detect_duplicates()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n int;
begin
  with dup as (
    select b.id
    from transactions a join transactions b
      on b.account_id = a.account_id and b.event_date = a.event_date and b.amount = a.amount
     and norm_text(b.description) = norm_text(a.description) and b.id <> a.id
     and a.source <> b.source   -- v2 (24/11/2026): só entre origens diferentes; duas compras iguais no mesmo dia (cada uma com seu id na Pluggy) são legítimas
     and (a.created_at, a.id) < (b.created_at, b.id)
  ), ins as (
    insert into data_quality_issues (kind, severity, transaction_id, detail)
    select 'duplicate_suspect', 'high', id, jsonb_build_object('rule','same_account_date_amount_desc') from dup
    on conflict do nothing returning 1
  ) select count(*) into n from ins;
  with marc as (
    update transactions t set reconciliation = 'duplicate_suspect' from data_quality_issues q where q.transaction_id = t.id and q.kind = 'duplicate_suspect' and q.status = 'open' and t.reconciliation is distinct from 'duplicate_suspect'
    returning t.id
  )
  insert into audit_logs (table_name, row_id, action, actor_label, after)
  select 'transactions', id::text, 'suspeita_duplicidade', 'detect_duplicates', jsonb_build_object('reconciliation', 'duplicate_suspect', 'efeito', 'oculto dos totais até confirmação') from marc;
  return n;
end $function$
;
