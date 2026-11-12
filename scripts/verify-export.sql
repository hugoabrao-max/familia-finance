-- Conferência do repositório contra o banco de produção (somente leitura).
-- Rode cada bloco no Supabase (execute_sql) e compare com `md5sum` dos arquivos locais.
-- Ver scripts/verify.sh para o lado local.

-- 1. Migrações: supabase/schema/migrations/<version>_<name>.sql
select version || '_' || name || '.sql' as file,
       md5(array_to_string(statements, E'\n;\n') || E'\n') as md5
from supabase_migrations.schema_migrations
order by version;

-- 2. Documentos: docs/<name>.md
select name || '.md' as file, md5(content) as md5
from public.project_docs
order by name;

-- 3. Views vivas: supabase/schema/live/views/<view>.sql (ver README em live/ para o formato exato)
select c.relname || '.sql' as file, md5(pg_get_viewdef(c.oid)) as viewdef_md5
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'v'
order by 1;
