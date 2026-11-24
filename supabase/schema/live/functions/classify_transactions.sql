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
