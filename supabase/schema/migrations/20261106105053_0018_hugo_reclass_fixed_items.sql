
insert into categories (id, parent_id, name, kind, sort, is_active) values
 ('contabilidade','impostos_taxas','Contabilidade (escritório)','despesa', 57, true),
 ('lanche_escolar','educacao','Lanche escolar (Alice)','despesa', 58, true)
on conflict (id) do nothing;

-- 1. Big Lar = supermercado
update classification_rules set category_id='mercado', origin='usuario', priority=50, confidence=0.95,
  history = history || jsonb_build_object('em', now(), 'de', category_id, 'para', 'mercado', 'motivo', 'Hugo 06/11: Big Lar é supermercado')
 where rule_type='merchant_contains' and pattern='big lar';
-- 2. Condomínio Edifício America Tower = condomínio
insert into classification_rules (rule_type, pattern, category_id, origin, confidence, priority, example)
values ('merchant_contains','condominio edificio america tower','condominio','usuario',0.98,40,'CONDOMINIO EDIFICIO AMERICA TOWER')
on conflict (rule_type, pattern) do update set category_id='condominio', origin='usuario', priority=40;
-- 3. Avante = escritório de contabilidade (fixo)
update classification_rules set category_id='contabilidade', origin='usuario', priority=40,
  history = history || jsonb_build_object('em', now(), 'de', category_id, 'para', 'contabilidade', 'motivo', 'Hugo 06/11: escritório de contabilidade')
 where id='a7c00fb5-a2d5-430a-8d4b-604264a06ce4';
insert into classification_rules (rule_type, pattern, category_id, origin, confidence, priority, example)
values ('merchant_contains','avante assessoria contabil','contabilidade','usuario',0.98,40,'AVANTE ASSESSORIA CONTABIL E EMPRESARIAL LTDA')
on conflict (rule_type, pattern) do update set category_id='contabilidade', origin='usuario', priority=40;
-- 5. Colégio Unicus = lanche escolar da Alice
update classification_rules set category_id='lanche_escolar', origin='usuario', priority=40,
  history = history || jsonb_build_object('em', now(), 'de', category_id, 'para', 'lanche_escolar', 'motivo', 'Hugo 06/11: lanche da Alice')
 where id='4945ebee-7e25-4aaf-8b1b-ec6e119d7dc9';
-- 6. Não há funcionário doméstico no cartão: desativa as regras antigas (sugestão IA v18) que mandavam compras de cartão para "Funcionários domésticos"
update classification_rules set is_active=false,
  history = history || jsonb_build_object('em', now(), 'acao', 'desativada', 'motivo', 'Hugo 06/11: não há funcionário doméstico pago no cartão')
 where category_id='equipe_domestica' and origin='v18_sugestao_ia';

-- Itens fixos confirmados pelo Hugo
insert into fixed_items (group_id, payee_key, is_fixed, note) values
 ('equipe_domestica','juscelina de oliveira dos',true,'babá'),
 ('equipe_domestica','leila aparecida da rocha',true,'doméstica seg–sex'),
 ('equipe_domestica','marilene galdino delgado',true,'diarista fim de semana'),
 ('equipe_domestica','ana fatima sampaio martins',true,'diarista casa Chapada'),
 ('equipe_domestica','elizeu dos santos almeida',true,'jardineiro casa Chapada')
on conflict (group_id, payee_key) do update set is_fixed=true, note=excluded.note;

