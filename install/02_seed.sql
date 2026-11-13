-- Family Finance — dados iniciais de uma instalação NOVA (sem nenhum dado da família Abrão).
-- Antes de rodar, troque os marcadores:
--   {{FAMILIA}}           nome da família, ex.: Família Silva
--   {{TITULAR_NOME}}      nome de quem administra, ex.: Pedro
--   {{TITULAR_EMAIL}}     e-mail que ele vai usar para entrar no app
--   {{TITULAR_EXTRATO}}   nome completo como aparece no PIX, em minúsculas e sem acento, ex.: pedro henrique silva
-- Rodar uma vez, depois de 01_schema.sql.

begin;

-- família e administrador (o login dele é vinculado pelo e-mail quando ele criar a senha)
with h as (insert into households(id, name) values (gen_random_uuid(), '{{FAMILIA}}') returning id)
insert into household_members(household_id, display_name, role, email)
select id, '{{TITULAR_NOME}}', 'owner', lower('{{TITULAR_EMAIL}}') from h;

-- categorias (grupo → subcategoria). Os ids são usados pelas regras; os nomes podem ser trocados no banco.
insert into categories(id, parent_id, name, kind, sort) values
 ('receitas', null, 'Receitas', 'receita', 1),
 ('receitas_fixas', 'receitas', 'Receitas fixas', 'receita', 2),
 ('receita', 'receitas_fixas', 'Salário / pró-labore', 'receita', 3),
 ('receitas_variaveis', 'receitas', 'Receitas variáveis', 'receita', 4),
 ('outras_entradas', 'receitas_variaveis', 'Outras entradas', 'receita', 5),
 ('moradia', null, 'Moradia', 'despesa', 10),
 ('moradia_contas', 'moradia', 'Contas da casa (água, luz, gás, internet)', 'despesa', 11),
 ('condominio', 'moradia', 'Condomínio', 'despesa', 12),
 ('casa', 'moradia', 'Casa (manutenção, itens)', 'despesa', 13),
 ('financiamento_imobiliario', 'moradia', 'Financiamento imobiliário', 'despesa', 14),
 ('aluguel', 'moradia', 'Aluguel', 'despesa', 15),
 ('alimentacao', null, 'Alimentação', 'despesa', 20),
 ('mercado', 'alimentacao', 'Supermercado', 'despesa', 21),
 ('alimentacao_fora', 'alimentacao', 'Restaurantes e delivery', 'despesa', 22),
 ('educacao', null, 'Educação', 'despesa', 30),
 ('lanche_escolar', 'educacao', 'Lanche escolar', 'despesa', 31),
 ('reforco_escolar', 'educacao', 'Cursos e reforço', 'despesa', 32),
 ('saude', null, 'Saúde', 'despesa', 40),
 ('bem_estar', 'saude', 'Bem-estar e academia', 'despesa', 41),
 ('personal_trainer', 'saude', 'Personal trainer', 'despesa', 42),
 ('transporte', null, 'Transporte', 'despesa', 50),
 ('combustiveis', 'transporte', 'Combustíveis', 'despesa', 51),
 ('veiculos', 'transporte', 'Veículos', 'despesa', 52),
 ('manutencao_veiculo', 'veiculos', 'Manutenção de veículo', 'despesa', 53),
 ('financiamento_veiculo', 'veiculos', 'Financiamento de veículo', 'despesa', 54),
 ('lazer', null, 'Lazer', 'despesa', 60),
 ('viagens_lazer', 'lazer', 'Viagens e passeios', 'despesa', 61),
 ('presentes_eventos', 'lazer', 'Presentes e eventos', 'despesa', 62),
 ('filhos', null, 'Filhos', 'despesa', 70),
 ('equipe_domestica', null, 'Funcionários domésticos', 'despesa', 80),
 ('apoio_familiar', null, 'Apoio familiar', 'despesa', 85),
 ('seguros', null, 'Seguros', 'despesa', 90),
 ('impostos_taxas', null, 'Impostos e taxas', 'despesa', 95),
 ('contabilidade', 'impostos_taxas', 'Contabilidade', 'despesa', 96),
 ('assinaturas', null, 'Assinaturas', 'despesa', 100),
 ('compras', null, 'Compras', 'despesa', 110),
 ('vestuario_beleza', 'compras', 'Vestuário e beleza', 'despesa', 111),
 ('servicos', 'compras', 'Serviços', 'despesa', 112),
 ('compras_online', 'compras', 'Compras on-line', 'despesa', 113),
 ('salao_beleza', 'compras', 'Salão de beleza', 'despesa', 114),
 ('despesas_financeiras', null, 'Despesas financeiras (juros, tarifas)', 'despesa', 120),
 ('investimentos', null, 'Investimentos', 'investimento', 130),
 ('dividas', null, 'Dívidas', 'divida', 140),
 ('transferencias_internas', null, 'Transferências internas', 'transferencia', 150),
 ('pagamento_cartao', 'transferencias_internas', 'Pagamento de fatura do cartão', 'transferencia', 151),
 ('transferencia_entre_contas', 'transferencias_internas', 'Transferência entre contas próprias', 'transferencia', 152),
 ('transferencia_familia_saida', 'transferencias_internas', 'Transferência para familiar', 'transferencia', 153),
 ('outros', null, 'Outros / a classificar', 'despesa', 999);

-- quanto dá para cortar de cada grupo na Meta de sobra (o usuário muda na tela)
insert into category_flex(group_id, classe, max_cut_pct, source) values
 ('alimentacao','essencial',10,'proposta'),('apoio_familiar','fixa',0,'proposta'),('assinaturas','ajustavel',30,'proposta'),
 ('compras','ajustavel',30,'proposta'),('despesas_financeiras','fixa',0,'proposta'),('educacao','fixa',0,'proposta'),
 ('equipe_domestica','fixa',0,'proposta'),('impostos_taxas','fixa',0,'proposta'),('lazer','discricionaria',30,'proposta'),
 ('moradia','fixa',0,'proposta'),('outros','ajustavel',30,'proposta'),('saude','essencial',10,'proposta'),
 ('seguros','fixa',0,'proposta'),('transporte','essencial',10,'proposta'),('veiculos','fixa',0,'proposta');

-- limites dos alertas (o usuário pode ajustar depois)
insert into alert_settings(key, value, note) values
 ('fatura_acima_media_pct', 15, 'fatura aberta projetada acima da média dos últimos 6 meses'),
 ('categoria_acima_media_pct', 25, 'gasto da categoria no mês acima do ritmo médio'),
 ('categoria_minimo_reais', 500, 'diferença mínima em R$ para alertar categoria'),
 ('compra_grande_reais', 3000, 'compra individual no cartão a destacar (últimos 7 dias)'),
 ('fatura_vence_dias', 5, 'dias de antecedência para avisar vencimento'),
 ('sync_atraso_horas', 26, 'horas sem sincronização bem-sucedida');

-- ramo do estabelecimento (MCC, padrão das bandeiras) → categoria sugerida
insert into mcc_category_map(mcc, category_id, note) values
 (4111,'transporte','transporte público'),(4121,'transporte','táxi/app'),(4511,'viagens_lazer','aéreo'),(4582,'viagens_lazer','aeroporto'),
 (4722,'viagens_lazer','agência/hospedagem'),(4812,'compras','celulares/acessórios'),(4814,'viagens_lazer','telecom em viagem'),
 (4816,'assinaturas','serviços digitais'),(4899,'assinaturas','streaming'),(5200,'casa','casa e construção'),(5211,'casa','materiais'),
 (5309,'compras','duty free'),(5311,'compras','loja de departamento'),(5331,'compras','variedades'),(5399,'compras','varejo'),
 (5411,'mercado','supermercados'),(5422,'mercado','açougue'),(5441,'mercado','doces'),(5451,'mercado','laticínios'),(5462,'mercado','padaria'),
 (5499,'mercado','mercearia/conveniência'),(5533,'manutencao_veiculo','autopeças'),(5541,'combustiveis','posto'),(5542,'combustiveis','posto automático'),
 (5611,'vestuario_beleza','moda masculina'),(5621,'vestuario_beleza','moda feminina'),(5631,'vestuario_beleza','acessórios'),
 (5641,'vestuario_beleza','moda infantil'),(5651,'vestuario_beleza','roupas'),(5661,'vestuario_beleza','calçados'),(5691,'vestuario_beleza','roupas'),
 (5697,'vestuario_beleza','costura'),(5699,'vestuario_beleza','vestuário'),(5712,'casa','móveis'),(5719,'casa','casa'),(5722,'casa','eletrodomésticos'),
 (5732,'compras','eletrônicos'),(5734,'assinaturas','software'),(5811,'alimentacao_fora','bufê/café'),(5812,'alimentacao_fora','restaurante'),
 (5813,'alimentacao_fora','bar'),(5814,'alimentacao_fora','lanchonete'),(5815,'assinaturas','mídia digital'),(5818,'assinaturas','digital'),
 (5912,'saude','farmácia'),(5921,'mercado','bebidas'),(5940,'compras','bicicletas'),(5941,'compras','artigos esportivos'),(5942,'compras','livraria'),
 (5943,'compras','papelaria'),(5944,'vestuario_beleza','joias'),(5945,'compras','brinquedos'),(5963,'compras','venda direta'),
 (5964,'assinaturas','clube/assinatura'),(5968,'assinaturas','assinatura'),(5970,'compras','artesanato'),(5977,'vestuario_beleza','cosméticos'),
 (5994,'compras','banca/livraria'),(5995,'compras','pet shop'),(5999,'compras','varejo'),(7011,'viagens_lazer','hotel'),(7221,'servicos','fotografia'),
 (7230,'vestuario_beleza','salão/barbearia'),(7298,'bem_estar','spa/estética'),(7299,'servicos','serviços pessoais'),(7523,'transporte','estacionamento'),
 (7538,'manutencao_veiculo','oficina'),(7832,'viagens_lazer','cinema'),(7922,'viagens_lazer','ingressos'),(7996,'viagens_lazer','parque'),
 (7997,'bem_estar','clube/academia'),(7999,'viagens_lazer','lazer'),(8011,'saude','médico'),(8021,'saude','dentista'),(8062,'saude','hospital/clínica'),
 (8071,'saude','laboratório'),(8099,'saude','serviço de saúde'),(8211,'educacao','escola'),(8241,'educacao','curso'),(8299,'educacao','escola/curso'),
 (8999,'servicos','serviços profissionais');

-- regras genéricas (texto já normalizado: minúsculo, sem acento, sem números). O app aprende o resto com as classificações do usuário.
insert into classification_rules(rule_type, pattern, category_id, origin, confidence, priority, example) values
 ('description_regex','^(pagamento de fatura|deb autom de fatura|debito aut fatura|pagto cartao|pagamento cartao)','pagamento_cartao','sistema',1.0,5,'pagamento da fatura'),
 ('description_regex','^pix (enviado|recebido) {{TITULAR_EXTRATO}}','transferencia_entre_contas','sistema',1.0,5,'PIX entre contas do próprio titular'),
 ('description_regex','(^| )(ted|doc|transf)[a-z ]* {{TITULAR_EXTRATO}}','transferencia_entre_contas','sistema',0.95,6,'transferência entre contas do próprio titular'),
 ('description_regex','pagamento darf|darf|tributo estadual|sefaz|receita federal|iptu|ipva|detran|licenciamento','impostos_taxas','sistema',1.0,20,'impostos'),
 ('description_regex','energia eletrica|enel|cemig|copel|light s|energisa|equatorial|cpfl|neoenergia|coelba|celesc|celpe|cosern','moradia_contas','sistema',0.95,20,'conta de luz'),
 ('description_regex','sabesp|saneago|copasa|sanepar|embasa|caesb|cagece|compesa|corsan|cedae|aguas de|agua e esgoto','moradia_contas','sistema',0.95,20,'conta de água'),
 ('description_regex','conta de telefone|vivo|claro|tim celular|oi movel','moradia_contas','sistema',0.9,25,'telefone/internet'),
 ('description_regex','operacoes credito imobiliario|financiamento habitacional|credito imobiliario','financiamento_imobiliario','sistema',1.0,10,'prestação do financiamento'),
 ('description_regex','mensalidade de seguro|seguro auto|porto seguro|bradesco seguros|sulamerica|allianz|tokio marine|mapfre','seguros','sistema',0.95,20,'seguros'),
 ('description_regex','^(rendimento|resgate|aplicacao) ','investimentos','sistema',0.9,30,'aplicações e resgates'),
 ('description_regex','tarifa|anuidade|juros|iof|encargos','despesas_financeiras','sistema',0.9,30,'tarifas e juros'),
 ('merchant_contains','ifood','alimentacao_fora','sistema',0.9,50,'iFood'),
 ('merchant_contains','rappi','alimentacao_fora','sistema',0.9,50,'Rappi'),
 ('merchant_contains','uber','transporte','sistema',0.85,50,'Uber'),
 ('merchant_contains','99app','transporte','sistema',0.85,50,'99'),
 ('merchant_contains','netflix','assinaturas','sistema',0.95,50,'Netflix'),
 ('merchant_contains','spotify','assinaturas','sistema',0.95,50,'Spotify'),
 ('merchant_contains','disney','assinaturas','sistema',0.9,50,'Disney+'),
 ('merchant_contains','globoplay','assinaturas','sistema',0.95,50,'Globoplay'),
 ('merchant_contains','youtube','assinaturas','sistema',0.9,50,'YouTube Premium'),
 ('merchant_contains','apple com bill','assinaturas','sistema',0.9,50,'Apple'),
 ('merchant_contains','google','assinaturas','sistema',0.7,60,'Google'),
 ('merchant_contains','amazon prime','assinaturas','sistema',0.9,45,'Amazon Prime'),
 ('merchant_contains','mercadolivre','compras_online','sistema',0.85,50,'Mercado Livre'),
 ('merchant_contains','mercado livre','compras_online','sistema',0.85,50,'Mercado Livre'),
 ('merchant_contains','amazon','compras_online','sistema',0.8,55,'Amazon'),
 ('merchant_contains','shopee','compras_online','sistema',0.85,50,'Shopee'),
 ('merchant_contains','magalu','compras_online','sistema',0.85,50,'Magalu'),
 ('merchant_contains','drogasil','saude','sistema',0.9,50,'Drogasil'),
 ('merchant_contains','droga raia','saude','sistema',0.9,50,'Droga Raia'),
 ('merchant_contains','drogaria','saude','sistema',0.85,55,'drogaria'),
 ('merchant_contains','pague menos','saude','sistema',0.9,50,'Pague Menos'),
 ('merchant_contains','panvel','saude','sistema',0.9,50,'Panvel'),
 ('merchant_contains','posto','combustiveis','sistema',0.8,60,'posto de combustível'),
 ('merchant_contains','shell','combustiveis','sistema',0.85,55,'Shell'),
 ('merchant_contains','ipiranga','combustiveis','sistema',0.85,55,'Ipiranga'),
 ('merchant_contains','petrobras','combustiveis','sistema',0.85,55,'Petrobras'),
 ('merchant_contains','carrefour','mercado','sistema',0.85,55,'Carrefour'),
 ('merchant_contains','assai','mercado','sistema',0.9,55,'Assaí'),
 ('merchant_contains','atacadao','mercado','sistema',0.9,55,'Atacadão'),
 ('merchant_contains','pao de acucar','mercado','sistema',0.9,55,'Pão de Açúcar'),
 ('merchant_contains','supermercado','mercado','sistema',0.85,60,'supermercado'),
 ('merchant_contains','smart fit','bem_estar','sistema',0.9,50,'Smart Fit'),
 ('merchant_contains','estacionamento','transporte','sistema',0.85,60,'estacionamento'),
 ('merchant_contains','sem parar','transporte','sistema',0.9,50,'Sem Parar'),
 ('merchant_contains','conectcar','transporte','sistema',0.9,50,'ConectCar');

-- token que o agendamento usa para chamar a sincronização (gerado aqui, nunca sai do banco)
insert into app_settings(key, value) values ('sync_token', encode(extensions.gen_random_bytes(32), 'hex'));

-- valores da Meta de sobra começam vazios: o usuário define na tela
commit;
