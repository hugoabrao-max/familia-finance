# install/ — kit para instalar o Family Finance para outra família

| Arquivo | O que é |
|---|---|
| `01_schema.sql` | esquema completo (41 tabelas, 25 funções, 22 views, permissões, gatilho de login), **gerado** por `build.py` a partir de `supabase/schema/live/` |
| `02_seed.sql` | dados iniciais genéricos (categorias, regras genéricas, MCC, alertas, família e dono com marcadores `{{...}}`) — nada da família Abrão |
| `03_cron.sql` | agendamentos da sincronização (marcador `{{PROJECT_REF}}`) |
| `LEIA-ME.md` | passo a passo para a nova família (vai como README do repositório dela) |
| `build.py` | regera `01_schema.sql` testando a ordem num Postgres local limpo |
| `stubs_local.sql` | imita papéis/auth/extensões do Supabase **só para o teste local** |
| `export_kit.sh` | monta a pasta limpa para o repositório da outra família e barra a entrega se achar dado pessoal |

Regerar e testar (Postgres local com papel `kit`/senha `kit`):
```bash
python3 install/build.py
```
Depois de mudar o esquema de produção (migração), rode `build.py` de novo para o kit acompanhar.
