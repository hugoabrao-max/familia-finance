create or replace view public.v_sim_base with (security_invoker = on) as
 WITH meses AS (
         SELECT (generate_series((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '6 mons'::interval), (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval), '1 mon'::interval))::date AS mes
        ), rec AS (
         SELECT percentile_cont((0.5)::double precision) WITHIN GROUP (ORDER BY ((COALESCE(s.receitas, (0)::numeric))::double precision)) AS v,
            jsonb_agg(jsonb_build_object('mes', m.mes, 'receitas', COALESCE(s.receitas, (0)::numeric), 'despesas', (- COALESCE(s.despesas, (0)::numeric))) ORDER BY m.mes) AS hist
           FROM (meses m
             LEFT JOIN v_month_summary s ON ((s.month = m.mes)))
        ), grp AS (
         SELECT g.group_id,
            max(c2.name) AS nome,
            percentile_cont((0.5)::double precision) WITHIN GROUP (ORDER BY ((COALESCE(x.gasto, (0)::numeric))::double precision)) AS mediana
           FROM (((( SELECT DISTINCT v_category_month.group_id
                   FROM v_category_month
                  WHERE (v_category_month.category_kind = 'despesa'::text)) g
             CROSS JOIN meses m)
             LEFT JOIN ( SELECT v_category_month.month,
                    v_category_month.group_id,
                    (- sum(v_category_month.total)) AS gasto
                   FROM v_category_month
                  WHERE (v_category_month.category_kind = 'despesa'::text)
                  GROUP BY v_category_month.month, v_category_month.group_id) x ON (((x.month = m.mes) AND (x.group_id = g.group_id))))
             LEFT JOIN categories c2 ON ((c2.id = g.group_id)))
          GROUP BY g.group_id
        ), fat AS (
         SELECT COALESCE(sum(v_card_bills.total_lancamentos), (0)::numeric) AS v
           FROM v_card_bills
          WHERE (v_card_bills.status = 'fechada'::text)
        )
 SELECT ( SELECT rec.v
           FROM rec) AS receita_mensal,
    ( SELECT rec.hist
           FROM rec) AS historico,
    ( SELECT jsonb_agg(jsonb_build_object('group_id', grp.group_id, 'nome', grp.nome, 'mediana', round((grp.mediana)::numeric, 2)) ORDER BY grp.mediana DESC) AS jsonb_agg
           FROM grp
          WHERE (grp.mediana > (0)::double precision)) AS despesas_grupo,
    ( SELECT jsonb_agg(jsonb_build_object('id', commitments.id, 'nome', commitments.name, 'tipo', commitments.kind, 'categoria', commitments.category_id, 'parcela', commitments.monthly_amount, 'fim', commitments.end_date, 'saldo_devedor', commitments.outstanding_balance)) AS jsonb_agg
           FROM commitments
          WHERE commitments.is_active) AS compromissos,
    ( SELECT jsonb_agg(jsonb_build_object('mes', f.competence_month, 'valor', f.v)) AS jsonb_agg
           FROM ( SELECT v_card_future_installments.competence_month,
                    sum(v_card_future_installments.valor) AS v
                   FROM v_card_future_installments
                  GROUP BY v_card_future_installments.competence_month) f) AS parcelas_cartao,
    (conta_corrente + poupanca) AS liquidez_imediata,
    investimentos,
    cartao_utilizado,
    financiamentos_saldo,
    ( SELECT fat.v
           FROM fat) AS fatura_fechada_a_pagar,
    ( SELECT jsonb_agg(jsonb_build_object('nome', v_goals.name, 'alvo', v_goals.target_amount, 'progresso', v_goals.progresso, 'status', v_goals.status)) AS jsonb_agg
           FROM v_goals) AS metas,
    (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date AS mes_base
   FROM v_net_worth n;
