CREATE OR REPLACE FUNCTION public.month_close_check(p_month date)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  with m as (select date_trunc('month', p_month)::date m),
  b as (select * from v_card_bills, m where competence_month = m.m)
  select jsonb_build_object(
    'mes', (select m from m),
    'mes_encerrado', (select (m + interval '1 month')::date <= (now() at time zone 'America/Cuiaba')::date from m),
    'pendentes_categoria', (select count(*) from v_tx, m where month = m.m and category_id is null),
    'valor_pendente', (select coalesce(sum(abs(amount)),0) from v_tx, m where month = m.m and category_id is null),
    'duplicidades_abertas', (select count(*) from data_quality_issues q join transactions t on t.id=q.transaction_id, m
                              where q.kind='duplicate_suspect' and q.status='open' and coalesce(t.competence_month, date_trunc('month',t.event_date)::date)=m.m),
    'fatura', (select jsonb_build_object('fechamento', closing_date, 'status', status, 'lancamentos', total_lancamentos,
               'pago', paid_amount, 'pdf', pdf_total, 'diferenca', round(total_lancamentos - coalesce(pdf_total, paid_amount, total_lancamentos), 2),
               'fonte_fechamento', source) from b limit 1),
    'sincronizacao_ok', (select last_ok_sync from v_sync_status limit 1),
    'pronto', (select (m + interval '1 month')::date <= (now() at time zone 'America/Cuiaba')::date from m)
              and (select count(*) from v_tx, m where month = m.m and category_id is null) = 0
  );
$function$
;
