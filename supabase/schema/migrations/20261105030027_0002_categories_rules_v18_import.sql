-- 0002: categorias, regras de classificação, feedback, auditoria, importações (v18)

create table categories (
  id text primary key,                 -- slug estável (ex.: alimentacao_fora)
  parent_id text references categories(id),
  name text not null,
  kind text not null check (kind in ('receita','despesa','transferencia','investimento','divida')),
  sort int not null default 100,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table classification_rules (
  id uuid primary key default gen_random_uuid(),
  rule_type text not null check (rule_type in ('merchant_contains','payee_name','description_regex','system')),
  pattern text not null,               -- normalizado: minúsculas, sem acento, sem dígitos soltos
  category_id text not null references categories(id),
  origin text not null check (origin in ('usuario','sugestao_ia','sistema','v18_usuario','v18_sugestao_ia')),
  confidence numeric(4,3) not null default 0.800,
  priority int not null default 100,   -- menor = aplica antes
  example text,
  is_active boolean not null default true,
  history jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (rule_type, pattern)
);
create trigger trg_classification_rules_updated before update on classification_rules for each row execute function set_updated_at();

create table classification_feedback (
  id bigserial primary key,
  transaction_id uuid not null references transactions(id) on delete cascade,
  previous_category_id text references categories(id),
  new_category_id text references categories(id),
  previous_source text,
  changed_by uuid references household_members(id),
  reason text,
  created_at timestamptz not null default now()
);

create table audit_logs (
  id bigserial primary key,
  table_name text not null,
  row_id text not null,
  action text not null,                -- insert | update | delete | import | reclassify
  actor uuid references household_members(id),
  actor_label text,                     -- 'sistema', 'pluggy-sync', 'claude', nome do membro
  before jsonb,
  after jsonb,
  created_at timestamptz not null default now()
);

create table import_jobs (
  id uuid primary key default gen_random_uuid(),
  source text not null,                 -- pdf_v18 | ofx | csv
  source_ref text not null unique,      -- docId da v18 / sha do arquivo
  file_name text,
  doc_type text,                        -- extrato | fatura
  period text,                          -- aaaa-mm
  account_id uuid references accounts(id),
  reconciliation jsonb,
  status text not null default 'IMPORTED',
  rows_imported int default 0,
  imported_at timestamptz not null default now()
);

-- transactions: classificação, portador, competência
alter table transactions
  add column category_id text references categories(id),
  add column category_source text,      -- ajuste_usuario | pessoa | regra_sistema | regra_estabelecimento | pluggy | pendente
  add column category_confidence numeric(4,3),
  add column rule_id uuid references classification_rules(id),
  add column review_status text not null default 'auto' check (review_status in ('auto','pending','reviewed','ignored')),
  add column card_last4 text,
  add column holder_name text,
  add column competence_month date,     -- 1º dia do mês de competência gerencial
  add column import_job_id uuid references import_jobs(id),
  add column counterpart_name text;     -- nome do pagador/recebedor (PIX, boleto)
create index on transactions (category_id);
create index on transactions (competence_month);
create index on transactions (review_status) where review_status = 'pending';

-- card_statements: ligação com documento importado
alter table card_statements add column import_job_id uuid references import_jobs(id);

do $$ declare t text;
begin
  foreach t in array array['categories','classification_rules','classification_feedback','audit_logs','import_jobs']
  loop execute format('alter table %I enable row level security', t);
  end loop;
end $$;

-- Estrutura inicial de categorias (item 8 do Prompt Mestre) com os slugs da v18 como subcategorias
insert into categories (id, parent_id, name, kind, sort) values
 ('receitas', null, 'Receitas', 'receita', 1),
 ('receitas_fixas', 'receitas', 'Receitas fixas', 'receita', 2),
 ('receita', 'receitas_fixas', 'Receita (ATMO / Abrão Serviços Médicos)', 'receita', 3),
 ('receitas_variaveis', 'receitas', 'Receitas variáveis', 'receita', 4),
 ('outras_entradas', 'receitas_variaveis', 'Outras entradas', 'receita', 5),
 ('moradia', null, 'Moradia', 'despesa', 10),
 ('moradia_contas', 'moradia', 'Contas da casa (água, luz, gás, internet)', 'despesa', 11),
 ('condominio', 'moradia', 'Condomínio', 'despesa', 12),
 ('casa', 'moradia', 'Casa (manutenção, itens)', 'despesa', 13),
 ('financiamento_imobiliario', 'moradia', 'Financiamento imobiliário', 'despesa', 14),
 ('alimentacao', null, 'Alimentação', 'despesa', 20),
 ('mercado', 'alimentacao', 'Supermercado', 'despesa', 21),
 ('alimentacao_fora', 'alimentacao', 'Restaurantes e alimentação fora', 'despesa', 22),
 ('educacao', null, 'Educação', 'despesa', 30),
 ('reforco_escolar', 'educacao', 'Reforço escolar', 'despesa', 31),
 ('saude', null, 'Saúde', 'despesa', 40),
 ('bem_estar', 'saude', 'Bem-estar', 'despesa', 41),
 ('personal_trainer', 'saude', 'Personal trainer', 'despesa', 42),
 ('transporte', null, 'Transporte', 'despesa', 50),
 ('combustiveis', 'transporte', 'Combustíveis', 'despesa', 51),
 ('veiculos', 'transporte', 'Veículos', 'despesa', 52),
 ('manutencao_veiculo', 'veiculos', 'Manutenção de veículo', 'despesa', 53),
 ('financiamento_bradesco', 'veiculos', 'Financiamento do carro (Bradesco)', 'despesa', 54),
 ('lazer', null, 'Lazer', 'despesa', 60),
 ('viagens_lazer', 'lazer', 'Viagens e lazer', 'despesa', 61),
 ('presentes_eventos', 'lazer', 'Presentes e eventos', 'despesa', 62),
 ('filhos', null, 'Filhos', 'despesa', 70),
 ('equipe_domestica', null, 'Funcionários domésticos', 'despesa', 80),
 ('apoio_familiar', null, 'Apoio familiar', 'despesa', 85),
 ('seguros', null, 'Seguros', 'despesa', 90),
 ('impostos_taxas', null, 'Impostos e taxas', 'despesa', 95),
 ('assinaturas', null, 'Assinaturas', 'despesa', 100),
 ('compras', null, 'Compras', 'despesa', 110),
 ('vestuario_beleza', 'compras', 'Vestuário e beleza', 'despesa', 111),
 ('servicos', 'compras', 'Serviços', 'despesa', 112),
 ('despesas_financeiras', null, 'Despesas financeiras', 'despesa', 120),
 ('investimentos', null, 'Investimentos', 'investimento', 130),
 ('dividas', null, 'Dívidas', 'divida', 140),
 ('transferencias_internas', null, 'Transferências internas', 'transferencia', 150),
 ('pagamento_cartao', 'transferencias_internas', 'Pagamento de fatura do cartão', 'transferencia', 151),
 ('transferencia_entre_contas', 'transferencias_internas', 'Transferência entre contas próprias', 'transferencia', 152),
 ('transferencia_familia_saida', 'transferencias_internas', 'Transferência para familiar (saída)', 'transferencia', 153),
 ('outros', null, 'Outros / a classificar', 'despesa', 999);

-- Regras do sistema (premissas confirmadas na v18)
insert into classification_rules (rule_type, pattern, category_id, origin, confidence, priority, example) values
 ('payee_name', 'atmo engenharia', 'receita', 'sistema', 1.000, 10, 'PIX/TED de ATMO ENGENHARIA'),
 ('payee_name', 'abrao servicos medicos', 'receita', 'sistema', 1.000, 10, 'PIX/TED de ABRAO SERVICOS MEDICOS'),
 ('payee_name', 'juliana danielle costa ol', 'receita', 'sistema', 0.950, 15, 'PIX recebido de Juliana = renda da família (premissa confirmada 06/10/2026)'),
 ('payee_name', 'noelma marrye sales de sa', 'reforco_escolar', 'sistema', 1.000, 10, null),
 ('payee_name', 'amelly tallyta de arruda', 'personal_trainer', 'sistema', 1.000, 10, 'personal da Juliana'),
 ('payee_name', 'raul santos jabras ramos', 'personal_trainer', 'sistema', 1.000, 10, 'personal do Hugo'),
 ('payee_name', 'edneusa da costa oliveira', 'apoio_familiar', 'sistema', 1.000, 10, 'mãe da Juliana'),
 ('payee_name', 'ana fatima sampaio martin', 'equipe_domestica', 'sistema', 1.000, 10, null),
 ('payee_name', 'elizeu dos santos almeida', 'equipe_domestica', 'sistema', 1.000, 10, null),
 ('payee_name', 'juscelina de oliveira', 'equipe_domestica', 'sistema', 1.000, 10, null),
 ('payee_name', 'leila aparecida da rocha', 'equipe_domestica', 'sistema', 1.000, 10, null),
 ('payee_name', 'marilene galdino delgado', 'equipe_domestica', 'sistema', 1.000, 10, null),
 ('description_regex', 'partnerbank', 'condominio', 'sistema', 1.000, 20, 'boletos de condomínio: apto Cuiabá e casa Chapada'),
 ('description_regex', 'bradesco financiamentos', 'financiamento_bradesco', 'sistema', 1.000, 20, 'boleto do carro, termina 11/2026'),
 ('description_regex', '^(pagamento de fatura|deb autom de fatura|pagto cartao)', 'pagamento_cartao', 'sistema', 1.000, 5, 'pagamento de fatura só na visão de caixa');

insert into app_settings (key, value) values
 ('premissas_v18', '{"julianaComoRenda":true,"limites":{"alimentacao_fora":8,"educacao":10,"equipe_domestica":10,"financiamento_imobiliario":10,"mercado":10,"vestuario_beleza":6}}'),
 ('pendencias_v18', '["Pagamento ao Aylton (personal da Edneusa) não localizado","Boletos Itaú Unibanco: outro cartão ou empréstimo?","Boletos Condominio Edificio Ameri: o que são?","Revisar sugestões de categoria e PIX sem categoria","Confirmar rótulos do resumo do CDB"]')
on conflict (key) do nothing;

