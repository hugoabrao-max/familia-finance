CREATE OR REPLACE FUNCTION public.set_transaction_category(p_tx uuid, p_category text, p_create_rule boolean DEFAULT false, p_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare m household_members; t transactions; v_pattern text;
begin
  m := current_member();
  if m.id is null or m.role not in ('owner','admin','member') then raise exception 'sem permissão'; end if;
  select * into t from transactions where id = p_tx;
  if t.id is null then raise exception 'lançamento não encontrado'; end if;
  insert into classification_feedback (transaction_id, previous_category_id, new_category_id, previous_source, changed_by, reason)
    values (p_tx, t.category_id, p_category, t.category_source, m.id, p_reason);
  insert into audit_logs (table_name, row_id, action, actor, actor_label, before, after)
    values ('transactions', p_tx::text, 'reclassify', m.id, m.display_name,
            jsonb_build_object('category_id', t.category_id, 'source', t.category_source),
            jsonb_build_object('category_id', p_category, 'source', 'ajuste_usuario'));
  update transactions set category_id = p_category, category_source = 'ajuste_usuario', category_confidence = 1.0,
         review_status = 'reviewed', rule_id = null where id = p_tx;
  if p_create_rule then
    v_pattern := norm_text(coalesce(nullif(btrim(t.counterpart_name), ''), nullif(btrim(split_part(t.description, '   ', 2)), ''), t.description));
    -- sem nome de estabelecimento, uma descrição que começa com termo de operação (pix, boleto, pagamento...) geraria regra ampla demais
    if length(v_pattern) >= 4 and not (nullif(btrim(t.counterpart_name), '') is null and v_pattern ~ '^(pix|ted|doc|pagamento|pagto|pag|boleto|transferencia|transf|saque|deposito|dep|tarifa|debito|deb|credito|cred|compra|estorno|resgate|aplicacao|rendimento)( |$)') then
      insert into classification_rules (rule_type, pattern, category_id, origin, confidence, priority, example)
        values ('merchant_contains', v_pattern, p_category, 'usuario', 0.900, 90, t.description)
      on conflict (rule_type, pattern) do update set category_id = excluded.category_id, origin = 'usuario', confidence = 0.900,
        history = classification_rules.history || jsonb_build_object('em', now(), 'de', classification_rules.category_id, 'para', excluded.category_id);
      perform classify_transactions(true);
    end if;
  end if;
end $function$
;
