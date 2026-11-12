# Estado real — 12/11/2026 (frontend v0.19.0 · banco migração 0029)
Status: implementado → testado → validado (documentos reais) → publicado. Nada é "resolvido" só porque compila.

## Produção
- Frontend v0.19.0 no ar em 12/11 (redesenho completo, Fases 1–5: voltar devolve o lugar, carregando/erro, fuso de Cuiabá, confirmações, Desfazer; Início com cards e detalhe de categoria; Lançamentos por dia com totais e "carregar mais", busca ao digitar, Revisão em lote por estabelecimento criando regra; Plano em 4 cards, Orçamento com "só este mês/deste mês em diante", Contas fixas com financiamentos, Reservas; tema no app, notebook em grade, teclado/leitor de tela, vocabulário novo). Publicado pelo serviço web do Railway, construído do GitHub (limite de 96 KB das Functions); página servida idêntica à testada; /health 0.19.0.
- Banco: 33 migrações (0001–0029; numeração 0006–0009 repetida, use o version), 42 tabelas, 22 views security_invoker, RLS em todas.
- Sincronização: pg_cron 4×/dia (15 1,3,10,22 UTC) + pos-sync 10 min depois; últimas execuções SUCCESS.
- Backup diário 09:00 UTC → bucket Railway, hash por releitura; último SUCCESS 12/11 09:03 UTC (1,42 MB). restore-check semanal (domingo 10:00 UTC) desde 12/11, comparando o restaurado com o próprio backup (0028).
- Contas fixas: 30 ativas, R$ 50.300,14/mês — desde 12/11 incluem os financiamentos imobiliários (R$ 7.377,86, decisão do Hugo).
- Dados: 3.550 lançamentos (05/11/2025 → 11/11/2026); 638 regras; 49 categorias; 11 pendentes (7 out/26, 4 nov/26).
- Usuários: Hugo (owner) e Juliana (member), ambos vinculados ao Auth.

## Repositório (novo em 12/11/2026)
github.com/hugoabrao-max/familia-finance (privado). Conteúdo exportado da produção e conferido: app.ts/backup/restore-check byte a byte com o Railway; 29 migrações, 49 definições vivas e 12 docs por md5 com o banco; Edge Functions sem checksum (parse OK). Fonte de verdade do esquema: supabase/schema/live (prevalece sobre migrações).

## Validação
- Validado com documentos reais: conta corrente × 9 extratos; cartão × 10 faturas (jan–set ≤1,4%; corrigido em 12/11 pela migração 0026: dez/25–mar/26 −128,92, abr–set/26 −70,20, out/26 +0,02 — resíduo = parcelas de compras com mais de 12 meses que a Pluggy não traz); backup/restore.
- Testado, aguardando Hugo: v0.10–v0.14 (Início, Plano, Meta, Fixas, Cartão), simulações.
- Testado 12/11: RLS cruzada Juliana × Hugo (simulação no banco, rollback) — Juliana lê tudo igual, edita categorias/orçamento/metas, não fecha/reabre meses nem roda funções internas.
- Não testado: login real da Juliana e do Hugo no navegador/celular; fechamento de mês (nenhum fechado).

## Achados de segurança (12/11, revisão do código exportado — nada alterado)
- (corrigido 12/11) pluggy-sync v1.3.3 só aceita o token por header e compara em tempo constante; backup-export v1.2 idem; sync_token rotacionado. pluggy-diag ainda usa === (remoção pendente).
- (corrigido 12/11, 0029) handle_new_auth_user só vincula login pelo e-mail cadastrado.
- Funções SECURITY DEFINER: todas com search_path=public. anon executa só utilitárias inofensivas.

## Relatório mensal
scripts/relatorio_mensal.sql + .py geram PDF e planilha do mês (out/2026 entregue em 12/11, preliminar). Para gerar outro mês: exportar os dados com md5 conferido e rodar o script.

## Próxima ação
Hugo: abrir o app no celular e validar v0.10–v0.14; revisar 11 pendentes; decidir orçamento/meta. Técnica: ver ROADMAP.