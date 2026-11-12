# Esquema vivo (exportado em 12/11/2026)

Definições lidas do banco de produção. Quando divergirem das migrações, **estas prevalecem**
(ex.: `v_fixed_month` foi reescrita via `execute_sql` depois da 0021).

| Arquivo | Conteúdo | Conferência |
|---|---|---|
| `views/*.sql` | 22 views, todas `security_invoker = on` | md5 de `create or replace view ... with (security_invoker = on) as\n` + `pg_get_viewdef` + `\n` |
| `functions/*.sql` | 25 funções em 22 arquivos (4 overloads de `fmt_br` juntos) | md5 de `pg_get_functiondef(oid) \|\| ';\n'` |
| `policies.sql` | 42 `enable row level security` + 53 políticas | md5 conferido |
| `triggers.sql` | 5 triggers `set_updated_at` em tabelas `public` | md5 conferido |
| `cron_jobs.sql` | `pluggy-sync-diario`, `pos-sync` (token lido de `app_settings`, nada literal) | md5 conferido |
| `grants.sql` | ACL de EXECUTE das funções | md5 conferido |
| `tables.sql` | 42 tabelas: colunas, constraints e 10 índices avulsos (os demais vêm de PK/UNIQUE) | md5 conferido |

## Fora do schema `public` (não exportado acima)

```sql
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();
```
