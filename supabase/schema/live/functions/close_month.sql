CREATE OR REPLACE FUNCTION public.close_month(p_month date, p_notes text DEFAULT NULL::text, p_force boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare mb household_members; chk jsonb; snap jsonb; mm date := date_trunc('month', p_month)::date;
begin
  mb := current_member();
  if mb.id is null or mb.role not in ('owner','admin') then raise exception 'sem permissão'; end if;
  chk := month_close_check(mm);
  if not (chk->>'mes_encerrado')::boolean then raise exception 'o mês ainda não terminou'; end if;
  if not (chk->>'pronto')::boolean and not p_force then
    raise exception 'há % lançamentos sem categoria; revise ou feche com ressalva', chk->>'pendentes_categoria';
  end if;
  snap := jsonb_build_object(
    'resumo', (select to_jsonb(s) from v_month_summary s where month = mm),
    'grupos', (select jsonb_agg(jsonb_build_object('grupo', group_name, 'tipo', category_kind, 'total', total, 'n', n) order by total)
               from (select group_name, category_kind, sum(total) total, sum(n) n from v_category_month where month = mm group by 1,2) g),
    'saldos', (select jsonb_agg(jsonb_build_object('conta', name, 'tipo', subtype, 'saldo', balance, 'em', balance_observed_at)) from accounts where is_active),
    'gerado_em', now());
  insert into monthly_closings (month, status, snapshot, checklist, notes, closed_by)
  values (mm, 'fechado', snap, chk, p_notes, mb.id)
  on conflict (month) do update set status='fechado', snapshot=excluded.snapshot, checklist=excluded.checklist,
    notes=excluded.notes, closed_at=now(), closed_by=excluded.closed_by,
    history = monthly_closings.history || jsonb_build_object('em', now(), 'acao', 'refechado', 'snapshot_anterior', monthly_closings.snapshot);
  insert into audit_logs (table_name, row_id, action, actor, actor_label, after)
    values ('monthly_closings', mm::text, 'close', mb.id, mb.display_name, jsonb_build_object('force', p_force, 'notes', p_notes));
  return jsonb_build_object('ok', true, 'mes', mm, 'checklist', chk);
end $function$
;
