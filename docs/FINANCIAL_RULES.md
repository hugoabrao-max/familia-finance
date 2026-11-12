1. Receita: ATMO Engenharia, Abrão Serviços Médicos, PIX da Juliana (premissa confirmada 06/10/2026).
2. Transferências internas (pagamento de fatura, PIX entre contas do Hugo, transferência para familiar) não entram em receita/despesa gerencial.
3. Cartão: competência = mês do fechamento; pagamento da fatura só na visão de caixa.
4. PartnerBank = condomínios (moradia); Bradesco boleto = financiamento do carro até 11/2026.
5. Pessoas: correspondência por nome completo normalizado, nunca só primeiro nome.
6. Precedência: ajuste do usuário > pessoa > regra do sistema > estabelecimento > tipo de operação > pendente.
7. Nenhum lançamento é apagado; alterações da origem ficam em raw_transactions.changed_count.
8. Cartão (Open Finance): competência = mês do fechamento em que o lançamento cai pela data de lançamento na fatura (billPostDate); parcela 2+ lançada no dia do fechamento vai para a fatura seguinte. Total oficial da fatura = débito na conta corrente; total por lançamentos é estimativa (±1%).
9. Titulares: cartões 5430 e 8305 = Hugo; 7297 e 3738 = Juliana (pela fatura PDF).
10. MCC só sugere (confiança 0,70); regra de estabelecimento, pessoa e ajuste do usuário têm precedência.
11. Boleto Itaú Unibanco = fatura do cartão extra (não conectado) → despesa do mês (cartao_itau), teto combinado R$ 1,5 mil.
12. MERCADOLIVRE* = compras on-line.
13. Lançamentos antigos sem identificação ficam em "Não identificado (histórico)"; podem ser reclassificados a qualquer momento.
14. Meta de sobra mensal fixa (R$ 10.000 proposta pelo Hugo). Corte não linear: categorias fixas (moradia, educação, funcionários, apoio familiar, impostos, seguros) não entram; essencial até 10%, ajustável até 30%, discricionária até 50% — tudo editável.
15. Despesas fixas são pagas em geral pela conta (PIX, transferência, boleto, débito); variáveis, em geral no cartão de crédito.
16. Big Lar = supermercado (mercado). Condomínio Edifício America Tower = condomínio (compromisso fixo). Avante Assessoria = escritório de contabilidade (Impostos e taxas › Contabilidade, fixo). MEP Colégio Unicus = lanche escolar da Alice (Educação).
17. Funcionários domésticos são pagos só pela conta: Juscelina (babá), Leila (doméstica seg–sex), Marilene (diarista fim de semana), Ana Fátima (diarista casa Chapada), Elizeu (jardineiro casa Chapada). Regras antigas que mandavam compras de cartão para essa categoria foram desativadas.
18. iFood (IFD*) = restaurante/alimentação fora; exceção: IFD*DROGARIA = saúde.
19. Natália Neres de Almeida = maquiadora; Perezi Beleza = salão → Compras › Salão de beleza e maquiagem.