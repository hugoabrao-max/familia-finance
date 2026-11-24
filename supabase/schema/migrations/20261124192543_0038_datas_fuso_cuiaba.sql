-- 0038: datas no fuso de Cuiabá. CURRENT_DATE (UTC) trocado por (now() at time zone 'America/Cuiaba')::date em
-- 13 views e 2 funções: entre 20h e 24h de Cuiabá o "hoje" e o "mês atual" já viravam o dia/mês seguinte.
-- Aplicada lendo a definição viva de cada objeto e trocando só essa expressão; mesmas colunas; nenhum dado alterado.
-- Definições resultantes: supabase/schema/live/views/*.sql e functions/{reconcile_all,refresh_card_cycles}.sql.
do $$
declare v text; d text; f text; n int := 0;
begin
  foreach v in array array['v_budget_month','v_card_bills','v_card_future_installments','v_card_teto','v_financing','v_fixed_expenses','v_fixed_month','v_group_channel','v_group_items','v_meta_base','v_meta_items','v_month_commitments','v_sim_base'] loop
    d := pg_get_viewdef(('public.' || v)::regclass);
    if position('CURRENT_DATE' in d) = 0 then raise exception 'view % sem CURRENT_DATE', v; end if;
    d := replace(d, 'CURRENT_DATE', '((now() AT TIME ZONE ''America/Cuiaba''::text))::date');
    execute format('create or replace view public.%I with (security_invoker = on) as %s', v, d);
    n := n + 1;
  end loop;
  foreach f in array array['reconcile_all','refresh_card_cycles'] loop
    d := pg_get_functiondef(('public.' || f)::regproc);
    if (length(d) - length(replace(d, 'current_date', ''))) / length('current_date') <> 1 then raise exception 'função % não tem exatamente 1 current_date', f; end if;
    execute replace(d, 'current_date', '(now() at time zone ''America/Cuiaba'')::date');
    n := n + 1;
  end loop;
  raise notice 'objetos atualizados: %', n;
end $$;
