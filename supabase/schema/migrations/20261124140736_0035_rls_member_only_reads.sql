-- 0035: leitura só para membros da família.
-- Antes: ~30 tabelas liberavam SELECT para qualquer usuário logado (using true / auth.uid() is not null),
-- mesmo sem vínculo em household_members. Agora exige que o usuário seja membro (my_household() não nulo).
-- Só troca regras de acesso (policies); nenhum dado é alterado. Nomes das policies mantidos.
do $$
declare r record; n int := 0;
begin
  for r in
    select tablename, policyname from pg_policies
    where schemaname = 'public' and cmd = 'SELECT'
      and qual in ('true', '(auth.uid() IS NOT NULL)', '(( SELECT auth.uid() AS uid) IS NOT NULL)')
  loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
    execute format('create policy %I on public.%I as permissive for select to authenticated using ((select public.my_household()) is not null)', r.policyname, r.tablename);
    n := n + 1;
  end loop;
  raise notice 'policies de leitura restritas a membros: %', n;
  if exists (select 1 from pg_policies where schemaname = 'public'
             and (qual in ('true', '(auth.uid() IS NOT NULL)', '(( SELECT auth.uid() AS uid) IS NOT NULL)')
                  or with_check in ('true', '(auth.uid() IS NOT NULL)'))) then
    raise exception 'sobrou policy aberta';
  end if;
end $$;
