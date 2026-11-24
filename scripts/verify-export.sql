-- Conferência do repositório contra o banco de produção (somente leitura).
-- Rode no Supabase (execute_sql) e compare com a saída de `bash scripts/verify.sh` (mesmo formato: "arquivo md5").
-- Cada md5 é calculado no MESMO formato em que o arquivo foi exportado. v2 (24/11/2026): antes só havia views, e o md5
-- nunca batia porque não incluía o cabeçalho "create or replace view ..." nem a quebra de linha final.
select arquivo, md5 from (
  -- views: supabase/schema/live/views/<view>.sql
  select 'views/' || c.relname || '.sql' as arquivo,
         md5('create or replace view public.' || c.relname || ' with (security_invoker = on) as' || E'\n' || pg_get_viewdef(c.oid) || E'\n') as md5
  from pg_class c where c.relnamespace = 'public'::regnamespace and c.relkind = 'v'
  union all
  -- funções: supabase/schema/live/functions/<função>.sql (as 4 sobrecargas de fmt_br ficam num arquivo só e não entram aqui)
  select 'functions/' || p.proname || '.sql', md5(pg_get_functiondef(p.oid) || E';\n')
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.prokind = 'f' and p.proname <> 'fmt_br'
  union all
  -- políticas: supabase/schema/live/policies.sql (RLS ligada por tabela + todas as políticas, em ordem)
  select 'policies.sql', md5(
    (select string_agg('alter table public.' || relname || ' enable row level security;', E'\n' order by relname)
       from pg_class where relnamespace = 'public'::regnamespace and relkind = 'r' and relrowsecurity)
    || E'\n\n' ||
    (select string_agg(format(E'create policy %s on public.%s as %s for %s to %s', policyname, tablename, permissive, cmd, array_to_string(roles, ', '))
              || coalesce(E'\n  using (' || qual || ')', '') || coalesce(E'\n  with check (' || with_check || ')', '') || ';', E'\n\n' order by tablename, policyname)
       from pg_policies where schemaname = 'public')
    || E'\n')
  union all
  -- documentos: docs/<name>.md
  select 'docs/' || name || '.md', md5(content) from public.project_docs
) x order by 1;
