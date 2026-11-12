create extension if not exists unaccent with schema extensions;

create or replace function norm_text(t text) returns text language sql immutable as $$
  select trim(regexp_replace(regexp_replace(lower(extensions.unaccent(coalesce(t,''))), '[0-9]', '', 'g'), '[^a-z*]+', ' ', 'g'))
$$;

create or replace function derive_counterpart(p_description text, p_payment jsonb) returns text language sql immutable as $$
  select coalesce(
    nullif(p_payment->'payer'->>'name',''),
    nullif(p_payment->'receiver'->>'name',''),
    nullif(trim(regexp_replace(split_part(p_description, '   ', 2), '^[0-9]{2}/[0-9]{2} ', '')), '')
  )
$$;

update transactions set counterpart_name = derive_counterpart(description, payment_data)
 where source = 'pluggy' and counterpart_name is null;

create or replace function classify_transactions(p_only_unclassified boolean default true) returns table(classified int, pending int) language plpgsql as $$
declare v_classified int := 0; v_pending int := 0;
begin
  with cand as (
    select t.id, norm_text(t.description) as nd, norm_text(coalesce(t.counterpart_name,'')) as nc,
           norm_text(t.description || ' ' || coalesce(t.counterpart_name,'')) as nall, t.operation_type
    from transactions t
    where (not p_only_unclassified or t.category_id is null or t.category_source in ('regra_sistema','regra_estabelecimento','pluggy','padrao_operacao','pendente'))
      and coalesce(t.category_source,'') <> 'ajuste_usuario'
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
        else null end as category_id
    from cand c where c.id not in (select id from best)
  ),
  upd as (
    update transactions t set
      category_id = coalesce(b.category_id, f.category_id),
      category_source = case when b.id is not null then (case when b.rule_type = 'payee_name' then 'pessoa' when b.rule_type = 'description_regex' then 'regra_sistema' else 'regra_estabelecimento' end)
                             when f.category_id is not null then 'padrao_operacao' else 'pendente' end,
      category_confidence = case when b.id is not null then b.confidence when f.category_id is not null then 0.800 else null end,
      rule_id = b.rule_id,
      review_status = case when b.id is not null or f.category_id is not null then 'auto' else 'pending' end
    from cand c left join best b on b.id = c.id left join fallback f on f.id = c.id
    where t.id = c.id
    returning t.category_id
  )
  select count(*) filter (where category_id is not null), count(*) filter (where category_id is null) into v_classified, v_pending from upd;
  return query select v_classified, v_pending;
end $$;

