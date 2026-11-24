-- 0041: v_fixed_month — quando um pagamento casa com o padrão de texto de duas contas fixas, vence o padrão mais longo
-- (mais específico). Ex.: 'incendio res' (Seguro incêndio) vence 'mensalidade de seguro' (Seguro parcelado) quando o banco
-- manda o pagamento sem o nome do favorecido. Mesmas colunas; nenhum dado alterado.
do $$
declare d text;
begin
  d := pg_get_viewdef('public.v_fixed_month'::regclass);
  if position('END, b_1.id) x' in d) = 0 then raise exception 'trecho não encontrado'; end if;
  d := replace(d, 'END, b_1.id) x', 'END, (length(b_1.match_pattern)) DESC NULLS LAST, b_1.id) x');
  execute 'create or replace view public.v_fixed_month with (security_invoker = on) as ' || d;
end $$;
-- Dado (fora da migração, com audit_logs): fixed_expenses 'Seguro incêndio residencial'.match_pattern = 'seguro parc incendio res'.
