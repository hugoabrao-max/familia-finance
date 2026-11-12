-- Dados do relatório mensal (somente leitura). Substituir {{MES}} por 'aaaa-mm-01'.
-- Saída: um jsonb. Partes grandes (lançamentos) podem ser lidas em páginas com a consulta do final.
-- Usa as mesmas views do app, então os números batem com o que aparece na tela.
with p as (select date '{{MES}}' as m)
select jsonb_build_object(
  'mes', (select m from p),
  'gerado_em', now(),
  'checagem_fechamento', (select month_close_check(m) from p),
  'fechamento', (select to_jsonb(c) - 'snapshot' from monthly_closings c, p where c.month = p.m),
  'resumo_13m', (select jsonb_agg(to_jsonb(s) order by s.month) from v_month_summary s, p
                 where s.month between (p.m - interval '12 months')::date and p.m),
  'categorias', (select jsonb_agg(to_jsonb(c) order by c.total) from v_category_month c, p where c.month = p.m),
  'orcamento', (select jsonb_agg(to_jsonb(b) order by b.gasto) from v_budget_month b, p where b.month = p.m),
  'faturas', (select jsonb_agg(to_jsonb(f) - 'account_id' - 'paid_transaction_id' order by f.closing_date) from v_card_bills f, p
              where f.competence_month = p.m),
  'fatura_por_titular', (select jsonb_agg(x) from (
        select t.bill_closing_date, coalesce(t.holder_name,'?') titular, t.card_last4 cartao, count(*) n, -sum(t.amount) total
        from v_tx t, p where t.account_subtype = 'CREDIT_CARD' and t.month = p.m and not t.is_deleted_at_source
          and t.category_kind is distinct from 'transferencia' and t.reconciliation is distinct from 'duplicate_suspect'
        group by 1,2,3 order by 1,2,3) x),
  'fixas', (select jsonb_agg(to_jsonb(f) - 'fixed_expense_id' order by f.name) from v_fixed_month f, p where f.month = p.m),
  'n_lancamentos', (select count(*) from v_tx t, p where t.month = p.m and not t.is_deleted_at_source),
  'soma_lancamentos', (select sum(amount) from v_tx t, p where t.month = p.m and not t.is_deleted_at_source)
) as dados;

-- Lançamentos do mês (página: OFFSET/LIMIT), ordem estável por data, conta, id:
-- with p as (select date '{{MES}}' as m)
-- select jsonb_agg(jsonb_build_object(
--   'id', t.id, 'data', t.event_date, 'conta', t.account_subtype, 'descricao', t.description,
--   'contraparte', t.counterpart_name, 'valor', t.amount, 'categoria', t.category_name, 'grupo', t.group_name,
--   'tipo', t.category_kind, 'origem_categoria', t.category_source, 'revisao', t.review_status,
--   'cartao', t.card_last4, 'titular', t.holder_name, 'parcela', t.installment_number, 'parcelas', t.installment_total,
--   'fatura', t.bill_closing_date, 'conciliacao', t.reconciliation, 'moeda_original', t.original_currency,
--   'valor_original', t.original_amount) order by t.event_date, t.account_subtype, t.id)
-- from (select t.*, x.original_currency, x.original_amount from v_tx t join transactions x on x.id = t.id, p
--       where t.month = p.m and not t.is_deleted_at_source
--       order by t.event_date, t.account_subtype, t.id offset {{OFFSET}} limit {{LIMIT}}) t;
