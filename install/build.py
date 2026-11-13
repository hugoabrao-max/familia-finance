"""Monta install/01_schema.sql a partir de supabase/schema/live (fonte de verdade).
Ordena funções e views por tentativa contra um Postgres local limpo (stubs do Supabase).
Uso: python3 build.py   (requer Postgres local com papel kit; ver README)"""
import re, glob, os, subprocess, sys
ROOT = os.path.dirname(os.path.abspath(__file__)); LIVE = os.path.join(ROOT, '..', 'supabase', 'schema', 'live')
SKIP_TABLES = {'backup_ids_20261106'}            # cópia de segurança pontual do Hugo, não faz parte do sistema
DB = 'kitbuild'
def psql(sql, db=DB):
    r = subprocess.run(['psql', '-v', 'ON_ERROR_STOP=1', '-qX', '-h', 'localhost', '-U', 'kit', '-d', db], input=sql, text=True, capture_output=True, env={**os.environ, 'PGPASSWORD': 'kit'})
    return r.returncode == 0, r.stderr.strip()
def read(p): return open(os.path.join(LIVE, p), encoding='utf-8').read()

# --- tabelas: separa FKs, cria sequências
tsql = read('tables.sql'); blocks = re.split(r'\n(?=create table public\.)', tsql)
seqs, tables, fks, idx = set(), [], [], []
for b in blocks:
    m = re.match(r'create table public\.(\w+) \(', b.strip())
    if not m: continue
    name = m.group(1)
    if name in SKIP_TABLES: continue
    body, *rest = b.strip().split('\n);', 1)
    lines = body.split('\n'); keep = []
    for ln in lines:
        mm = re.match(r'\s*constraint (\w+) (FOREIGN KEY .*?),?$', ln)
        if mm: fks.append(f'alter table public.{name} add constraint {mm.group(1)} {mm.group(2).rstrip(",")};'); continue
        for s in re.findall(r"nextval\('(\w+)'::regclass\)", ln): seqs.add((s, name, ln.strip().split()[0]))
        keep.append(ln)
    keep[-1] = keep[-1].rstrip(',')
    tables.append('\n'.join(keep) + '\n);')
    for r_ in rest:
        idx += [x.strip() for x in r_.split('\n') if x.strip().upper().startswith('CREATE INDEX') or x.strip().upper().startswith('CREATE UNIQUE INDEX')]
seq_sql = '\n'.join(f'create sequence if not exists public.{s};' for s, _, _ in sorted(seqs))
own_sql = '\n'.join(f'alter sequence public.{s} owned by public.{t}.{c};' for s, t, c in sorted(seqs))

# --- funções e views: arquivos individuais (fmt_br tem 4 overloads num arquivo)
funcs = []
for f in sorted(glob.glob(os.path.join(LIVE, 'functions', '*.sql'))):
    txt = open(f, encoding='utf-8').read()
    parts = [p.strip() for p in re.split(r'\n(?=CREATE OR REPLACE FUNCTION)', txt) if p.strip()]
    funcs += [(os.path.basename(f), p if p.endswith(';') else p + ';') for p in parts]
views = [(os.path.basename(f), open(f, encoding='utf-8').read().strip()) for f in sorted(glob.glob(os.path.join(LIVE, 'views', '*.sql')))]

# --- banco limpo
subprocess.run(['psql', '-qX', '-h', 'localhost', '-U', 'kit', '-d', 'postgres', '-c', f'drop database if exists {DB}', '-c', f'create database {DB}'], env={**os.environ, 'PGPASSWORD': 'kit'}, check=True, capture_output=True)
ok, err = psql(open(os.path.join(ROOT, 'stubs_local.sql')).read()); assert ok, err
ok, err = psql('set check_function_bodies=on;\n' + seq_sql + '\n' + '\n\n'.join(tables) + '\n' + own_sql + '\n' + '\n'.join(fks) + '\n' + '\n'.join(idx)); assert ok, err

def order(items, label):
    done, pend, rounds = [], list(items), 0
    while pend:
        rounds += 1; nxt = []
        for n, s in pend:
            ok, err = psql(s)
            (done if ok else nxt).append((n, s) if ok else (n, s, err))
        if len(nxt) == len(pend):
            for x in nxt: print('FALHA', label, x[0], x[2][:300])
            sys.exit(1)
        pend = [(x[0], x[1]) for x in nxt]
    print(label, len(done), 'em', rounds, 'rodadas'); return done
# funções sem checar corpo primeiro não acusam dependências; views precisam das funções SQL
allx = order([('f:'+n, x) for n, x in funcs] + [('v:'+n, x) for n, x in views], 'funções+views')
fdone = [(n, x) for n, x in allx if n.startswith('f:')]; vdone = [(n, x) for n, x in allx if n.startswith('v:')]
# re-cria funções com checagem de corpo agora que views existem (valida tudo)
for n, s in fdone:
    ok, err = psql('set check_function_bodies=on;\n' + s); assert ok, (n, err)
rest = []
for p in ['policies.sql', 'triggers.sql', 'grants.sql']:
    s = '\n'.join(l for l in read(p).split('\n') if not any(t in l for t in SKIP_TABLES)); ok, err = psql(s); assert ok, (p, err); rest.append(f'-- {p}\n' + s)
auth_trg = "create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_auth_user();"
ok, err = psql(auth_trg); assert ok, err

out = ['-- Family Finance — esquema completo para um projeto Supabase NOVO (gerado por install/build.py a partir de supabase/schema/live).',
       '-- Rodar uma vez, como postgres (SQL editor do Supabase ou apply_migration). Não contém dados.',
       'create extension if not exists unaccent with schema extensions;', 'create extension if not exists pg_cron;', 'create extension if not exists pg_net with schema extensions;', '',
       '-- sequências', seq_sql, '', '-- tabelas', '\n\n'.join(tables), '', own_sql, '', '-- chaves estrangeiras', '\n'.join(fks), '', '-- índices', '\n'.join(idx), '',
       '-- funções e views (ordem de dependência)', '\n\n'.join(s for _, s in allx), '',
       '\n\n'.join(rest).replace('backup_ids_20261106', '__nao_usar__') if False else '\n\n'.join(rest), '', '-- login novo vira membro pelo e-mail cadastrado', auth_trg, '']
txt = '\n'.join(out)
txt = '\n'.join(l for l in txt.split('\n') if 'backup_ids_20261106' not in l)
open(os.path.join(ROOT, '01_schema.sql'), 'w', encoding='utf-8').write(txt)
print('01_schema.sql', len(txt.encode()), 'bytes;', len(tables), 'tabelas,', len(fdone), 'funções,', len(vdone), 'views')
