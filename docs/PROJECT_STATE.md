# Estado real — 12/11/2026 (frontend v0.14.0 · banco migração 0025)
Status: implementado → testado → validado (documentos reais) → publicado. Nada é "resolvido" só porque compila.

## Produção
- Frontend v0.14.0 publicado no Railway (serviço app) em 07/11; código conferido idêntico ao repositório.
- Banco: 29 migrações (0001–0025; numeração 0006–0009 repetida, use o version), 42 tabelas, 22 views security_invoker, RLS em todas.
- Sincronização: pg_cron 4×/dia (15 1,3,10,22 UTC) + pos-sync 10 min depois; últimas execuções SUCCESS.
- Backup diário 09:00 UTC → bucket Railway, hash por releitura; último SUCCESS 12/11 09:03 UTC (1,42 MB). restore-check semanal (domingo 10:00 UTC) desde 12/11.
- Dados: 3.550 lançamentos (05/11/2025 → 11/11/2026); 638 regras; 49 categorias; 11 pendentes (7 out/26, 4 nov/26).
- Usuários: Hugo (owner) e Juliana (member), ambos vinculados ao Auth.

## Repositório (novo em 12/11/2026)
github.com/hugoabrao-max/familia-finance (privado). Conteúdo exportado da produção e conferido: app.ts/backup/restore-check byte a byte com o Railway; 29 migrações, 49 definições vivas e 12 docs por md5 com o banco; Edge Functions sem checksum (parse OK). Fonte de verdade do esquema: supabase/schema/live (prevalece sobre migrações).

## Validação
- Validado com documentos reais: conta corrente × 9 extratos; cartão × 10 faturas (jan–set ≤1,4%; dez/25 +13% explicado em 12/11: bill_closing_date da Pluggy errado nas bordas do ciclo — ver TEST_REPORT; correção de competência aguarda ok); backup/restore.
- Testado, aguardando Hugo: v0.10–v0.14 (Início, Plano, Meta, Fixas, Cartão), simulações.
- Testado 12/11: RLS cruzada Juliana × Hugo (simulação no banco, rollback) — Juliana lê tudo igual, edita categorias/orçamento/metas, não fecha/reabre meses nem roda funções internas.
- Não testado: login real da Juliana e do Hugo no navegador/celular; fechamento de mês (nenhum fechado).

## Achados de segurança (12/11, revisão do código exportado — nada alterado)
- (corrigido 12/11) pluggy-sync v1.3.3 só aceita o token por header e compara em tempo constante; backup-export v1.2 idem; sync_token rotacionado. pluggy-diag ainda usa === (remoção pendente).
- handle_new_auth_user: se nenhum membro tiver auth_user_id, o primeiro cadastro vira owner com qualquer e-mail. Hoje sem risco (ambos vinculados); corrigir exigindo e-mail.
- Funções SECURITY DEFINER: todas com search_path=public. anon executa só utilitárias inofensivas.

## Próxima ação
Hugo: abrir o app no celular e validar v0.10–v0.14; revisar 11 pendentes; decidir orçamento/meta. Técnica: ver ROADMAP.