CREATE OR REPLACE FUNCTION public.reopen_month(p_month date, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare mb household_members;
begin
  mb := current_member();
  if mb.id is null or mb.role not in ('owner','admin') then raise exception 'sem permissão'; end if;
  update monthly_closings set status='reaberto', history = history || jsonb_build_object('em', now(), 'acao', 'reaberto', 'motivo', p_reason)
   where month = date_trunc('month', p_month)::date;
  insert into audit_logs (table_name, row_id, action, actor, actor_label, after)
    values ('monthly_closings', p_month::text, 'reopen', mb.id, mb.display_name, jsonb_build_object('motivo', p_reason));
end $function$
;
