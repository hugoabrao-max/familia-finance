#!/usr/bin/env python3
"""Relatório mensal da Família Finance AI — planilha (xlsx) e PDF.

Entrada: diretório com os dados exportados por scripts/relatorio_mensal.sql
  dados.json            objeto com resumo, categorias, orçamento, faturas, fixas, checagem de fechamento
  lanc_*.json           páginas de lançamentos (arrays na ordem de COLS_LANC)
Saída: <saida>/relatorio_<aaaa-mm>.xlsx e .pdf

Regras: totais vêm do banco (views do app) e são só reorganizados aqui; a planilha recalcula as
conferências com fórmulas para que qualquer pessoa possa auditar. Patrimônio fica fora (sem destaque).
Uso: python3 scripts/relatorio_mensal.py <dir_dados> <dir_saida>
"""
import json, sys, glob, os
from decimal import Decimal
from datetime import date

COLS_LANC = ["data", "conta", "descricao", "contraparte", "valor", "categoria", "grupo", "tipo", "origem_categoria",
             "revisao", "cartao", "titular", "parcela", "parcelas", "fatura", "conciliacao", "moeda_original",
             "valor_original", "id"]
MESES = ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro",
         "novembro", "dezembro"]
MES_CURTO = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]
ORIGEM = {"ajuste_usuario": "ajuste do usuário", "pessoa": "pessoa", "regra_sistema": "regra do sistema",
          "regra_estabelecimento": "estabelecimento", "padrao_operacao": "tipo de operação", "mcc": "ramo (MCC, sugestão)",
          "lote_historico": "lote histórico", "pendente": "pendente", None: "pendente"}


def D(x):
    return Decimal(str(x)) if x is not None else Decimal(0)


def brl(v, sinal=False):
    v = D(v)
    s = f"{abs(v):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    if v < 0:
        return "−R$ " + s
    return ("+R$ " if sinal and v > 0 else "R$ ") + s


def mes_nome(m, curto=False):
    y, mm = int(m[:4]), int(m[5:7])
    return f"{MES_CURTO[mm-1]}/{str(y)[2:]}" if curto else f"{MESES[mm-1]}/{y}"


def data_br(s):
    return f"{s[8:10]}/{s[5:7]}/{s[:4]}" if s else ""


def carregar(d):
    dados = json.load(open(os.path.join(d, "dados.json"), encoding="utf-8"))
    lanc = []
    for f in sorted(glob.glob(os.path.join(d, "lanc_*.json")), key=lambda p: int(p.rsplit("_", 1)[1].split(".")[0])):
        lanc += [dict(zip(COLS_LANC, r)) for r in json.load(open(f, encoding="utf-8"))]
    soma = sum(D(l["valor"]) for l in lanc)
    assert len(lanc) == dados["n_lancamentos"], f"lançamentos: {len(lanc)} != {dados['n_lancamentos']}"
    assert soma == D(dados["soma_lancamentos"]), f"soma: {soma} != {dados['soma_lancamentos']}"
    return dados, lanc


def status_mes(dados):
    chk = dados["checagem_fechamento"]; fech = dados.get("fechamento")
    if fech and fech.get("status") == "closed":
        return "FECHADO", []
    motivos = []
    if chk.get("pendentes_categoria"):
        motivos.append(f"{chk['pendentes_categoria']} lançamentos sem categoria ({brl(chk['valor_pendente'])})")
    if chk.get("duplicidades_abertas"):
        motivos.append(f"{chk['duplicidades_abertas']} possíveis duplicidades em aberto")
    if not chk.get("mes_encerrado"):
        motivos.append("o mês ainda não terminou")
    motivos.append("mês ainda não fechado no app")
    return "PRELIMINAR", motivos


def grupos_despesa(dados):
    g = {}
    for c in dados["categorias"] or []:
        if c["category_kind"] in ("despesa", None):
            k = c["group_name"] or "Sem categoria"
            g[k] = g.get(k, Decimal(0)) + D(c["total"])
    return sorted(g.items(), key=lambda kv: kv[1])


# ---------------------------------------------------------------- planilha
def planilha(dados, lanc, path):
    from openpyxl import Workbook
    from openpyxl.styles import Font, PatternFill, Alignment
    from openpyxl.utils import get_column_letter
    BRL = '"R$" #,##0.00;[Red]-"R$" #,##0.00'
    H = Font(bold=True, color="FFFFFF"); HF = PatternFill("solid", fgColor="1A2B3C"); B = Font(bold=True)
    wb = Workbook()

    def tabela(ws, r0, cab, linhas, moeda=(), larg=None):
        for j, h in enumerate(cab, 1):
            c = ws.cell(r0, j, h); c.font = H; c.fill = HF; c.alignment = Alignment(wrap_text=True, vertical="top")
        for i, ln in enumerate(linhas, r0 + 1):
            for j, v in enumerate(ln, 1):
                c = ws.cell(i, j, float(v) if isinstance(v, Decimal) else v)
                if j - 1 in moeda: c.number_format = BRL
        if larg:
            for j, w in enumerate(larg, 1): ws.column_dimensions[get_column_letter(j)].width = w
        return r0 + len(linhas)

    m = dados["mes"]; st, motivos = status_mes(dados); chk = dados["checagem_fechamento"]
    res = next((r for r in dados["resumo_13m"] if r["month"] == m), {})

    ws = wb.active; ws.title = "Resumo"
    ws["A1"] = f"Família Abrão — relatório de {mes_nome(m)}"; ws["A1"].font = Font(bold=True, size=14)
    ws["A2"] = f"Situação: {st}" + (" — " + "; ".join(motivos) if motivos else ""); ws["A2"].font = B
    ws["A3"] = "Valores por competência (cartão pelo mês de fechamento da fatura). Transferências internas e pagamento de fatura ficam fora de receitas/despesas."
    r = tabela(ws, 5, ["Indicador", "Valor"], [
        ["Receitas", D(res.get("receitas"))], ["Despesas", D(res.get("despesas"))],
        ["Resultado (receitas + despesas)", D(res.get("resultado"))],
        ["Investimentos (movimentação líquida)", D(res.get("investimentos"))],
        ["Lançamentos sem categoria", res.get("pendentes")], ["Valor sem categoria", D(res.get("valor_pendente"))]],
        moeda=(1,), larg=[44, 18, 16, 16, 16, 12, 14])
    for rr in (6, 7, 8, 9, 11): ws.cell(rr, 2).number_format = BRL
    ws.cell(r + 2, 1, "Últimos 13 meses").font = B
    tabela(ws, r + 3, ["Mês", "Receitas", "Despesas", "Resultado", "Investimentos", "Pendentes", "Valor pendente"],
           [[mes_nome(x["month"], True), D(x["receitas"]), D(x["despesas"]), D(x["resultado"]), D(x["investimentos"]),
             x["pendentes"], D(x["valor_pendente"])] for x in dados["resumo_13m"]], moeda=(1, 2, 3, 4, 6))

    ws = wb.create_sheet("Categorias")
    linhas = [[c["group_name"], c["category_name"], c["category_kind"], c["n"], D(c["total"])] for c in dados["categorias"] or []]
    n = tabela(ws, 1, ["Grupo", "Categoria", "Tipo", "Lançamentos", "Total"], linhas, moeda=(4,), larg=[26, 34, 14, 12, 16])
    ws.cell(n + 1, 3, "Soma (receitas + despesas + investimentos; transferências fora)").font = B
    c = ws.cell(n + 1, 5, f"=SUM(E2:E{n})"); c.number_format = BRL; c.font = B

    ws = wb.create_sheet("Orçamento")
    tabela(ws, 1, ["Grupo", "Orçado", "Gasto", "Saldo", "% usado", "Fonte do orçamento"],
           [[b["group_name"], D(b["orcado"]), D(b["gasto"]), D(b["saldo"]), (float(b["pct"]) / 100 if b["pct"] is not None else None),
             {"hugo": "definido pelo Hugo", "proposta": "proposta (mediana)"}.get(b["source"], b["source"])]
            for b in dados["orcamento"] or []], moeda=(1, 2, 3), larg=[26, 16, 16, 16, 10, 22])
    for row in ws.iter_rows(min_row=2, min_col=5, max_col=5):
        for c in row: c.number_format = "0%"

    ws = wb.create_sheet("Cartão")
    n = tabela(ws, 1, ["Fechamento", "Vencimento", "Origem do fechamento", "Total por lançamentos", "Débito na conta (oficial)",
                       "PDF", "Diferença (lanç. − débito)", "Status"],
               [[data_br(f["closing_date"]), data_br(f["due_date"]), f["source"], D(f["total_lancamentos"]),
                 D(f["paid_amount"]) if f["paid_amount"] is not None else None, D(f["pdf_total"]) if f["pdf_total"] is not None else None,
                 None, f["status"]] for f in dados["faturas"] or []], moeda=(3, 4, 5, 6), larg=[13, 13, 20, 18, 18, 14, 18, 10])
    for i in range(2, n + 1):
        c = ws.cell(i, 7, f'=IF(E{i}="","",D{i}-E{i})'); c.number_format = BRL
    ws.cell(n + 2, 1, "Por titular e cartão").font = B
    m2 = tabela(ws, n + 3, ["Fechamento", "Titular", "Cartão", "Lançamentos", "Total"],
                [[data_br(t["bill_closing_date"]), t["titular"], t["cartao"], t["n"], D(t["total"])] for t in dados["fatura_por_titular"] or []],
                moeda=(4,))
    ws.cell(m2 + 1, 4, "Soma").font = B; c = ws.cell(m2 + 1, 5, f"=SUM(E{n+4}:E{m2})"); c.number_format = BRL; c.font = B

    ws = wb.create_sheet("Fixas")
    n = tabela(ws, 1, ["Despesa fixa", "Grupo", "Canal", "Devido", "Pago", "Diferença"],
               [[f["name"], f["group_id"], f["channel"], D(f["devido"]), D(f["pago"]), None] for f in dados["fixas"] or []],
               moeda=(3, 4, 5), larg=[34, 18, 12, 16, 16, 16])
    for i in range(2, n + 1):
        c = ws.cell(i, 6, f"=E{i}-D{i}"); c.number_format = BRL
    ws.cell(n + 1, 3, "Soma").font = B
    for col in "DEF":
        c = ws[f"{col}{n+1}"]; c.value = f"=SUM({col}2:{col}{n})"; c.number_format = BRL; c.font = B

    ws = wb.create_sheet("Lançamentos")
    cab = ["Data", "Conta", "Descrição", "Contraparte", "Valor", "Categoria", "Grupo", "Tipo", "Origem da categoria", "Revisão",
           "Cartão", "Titular", "Parcela", "De", "Fatura (fechamento)", "Conciliação", "Moeda original", "Valor original", "ID"]
    n = tabela(ws, 1, cab, [[data_br(l["data"]), {"CREDIT_CARD": "cartão", "CHECKING_ACCOUNT": "conta corrente",
                                                   "SAVINGS_ACCOUNT": "poupança"}.get(l["conta"], l["conta"]),
                             l["descricao"], l["contraparte"], D(l["valor"]), l["categoria"], l["grupo"], l["tipo"],
                             ORIGEM.get(l["origem_categoria"], l["origem_categoria"]), l["revisao"], l["cartao"], l["titular"],
                             l["parcela"], l["parcelas"], data_br(l["fatura"]), l["conciliacao"], l["moeda_original"],
                             D(l["valor_original"]) if l["valor_original"] is not None else None, l["id"]] for l in lanc],
               moeda=(4,), larg=[11, 14, 38, 26, 14, 26, 20, 12, 20, 10, 8, 10, 8, 6, 14, 14, 10, 12, 10])
    ws.freeze_panes = "A2"; ws.auto_filter.ref = f"A1:S{n}"

    ws = wb.create_sheet("Conciliação")
    fat = chk.get("fatura") or {}
    itens = [
        ["Lançamentos do mês (linhas)", len(lanc), "=COUNTA(Lançamentos!A2:A%d)" % n, "=IF(B2=C2,\"ok\",\"DIVERGE\")"],
        ["Soma dos lançamentos (banco × planilha)", D(dados["soma_lancamentos"]), "=SUM(Lançamentos!E2:E%d)" % n,
         "=IF(ROUND(B3-C3,2)=0,\"ok\",\"DIVERGE\")"],
        ["Fatura: total por lançamentos", D(fat.get("lancamentos")), None, None],
        ["Fatura: débito na conta (oficial)", D(fat.get("pago")), None, None],
        ["Fatura: diferença (lanç. − débito)", None, "=B4-B5", "=IF(ABS(C6)<=1,\"ok (≤ R$ 1)\",\"conferir\")"],
        ["Lançamentos sem categoria", chk.get("pendentes_categoria"), None, "=IF(B7=0,\"ok\",\"pendente\")"],
        ["Valor sem categoria", D(chk.get("valor_pendente")), None, None],
        ["Possíveis duplicidades em aberto", chk.get("duplicidades_abertas"), None, "=IF(B9=0,\"ok\",\"pendente\")"],
        ["Última sincronização OK", (chk.get("sincronizacao_ok") or "")[:16].replace("T", " ") + " UTC", None, None],
        ["Mês fechado no app", "sim" if st == "FECHADO" else "não", None, None],
    ]
    tabela(ws, 1, ["Conferência", "Valor do banco", "Recalculado na planilha", "Resultado"], itens, moeda=(1, 2), larg=[40, 20, 22, 16])
    ws.cell(14, 1, "Origem dos dados: Open Finance (Santander via Meu Pluggy). Total oficial da fatura = débito na conta; o total por "
                   "lançamentos é estimativa. Parcelas de compras com mais de 12 meses não vêm da Pluggy (diferença conhecida).")
    wb.save(path)


# ---------------------------------------------------------------- PDF
def pdf(dados, lanc, path):
    from reportlab.lib.pagesizes import A4
    from reportlab.lib import colors
    from reportlab.lib.units import mm
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.graphics.shapes import Drawing, String, Line
    from reportlab.graphics.charts.barcharts import VerticalBarChart
    pdfmetrics.registerFont(TTFont("DV", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"))
    pdfmetrics.registerFont(TTFont("DVB", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"))
    INK = colors.HexColor("#1A2B3C"); MUTED = colors.HexColor("#5F6E80"); LINE = colors.HexColor("#DDE2EA")
    TEAL = colors.HexColor("#0F7B6C"); RED = colors.HexColor("#B3261E"); AMBER = colors.HexColor("#B26B00"); SOFT = colors.HexColor("#F4F5F7")
    st = lambda **k: ParagraphStyle("x", fontName=k.pop("f", "DV"), fontSize=k.pop("s", 9), leading=k.pop("l", 12), textColor=k.pop("c", INK), **k)
    P = lambda t, **k: Paragraph(t, st(**k))

    m = dados["mes"]; status, motivos = status_mes(dados); chk = dados["checagem_fechamento"]
    res = next((r for r in dados["resumo_13m"] if r["month"] == m), {})
    story = [P(f"Família Abrão · relatório de {mes_nome(m)}", f="DVB", s=16, l=20),
             P("Competência (cartão pelo mês de fechamento da fatura). Fonte: Open Finance (Santander via Meu Pluggy).", s=8, c=MUTED),
             Spacer(1, 4 * mm)]
    cor = AMBER if status == "PRELIMINAR" else TEAL
    story.append(Table([[P(f"<b>{status}</b>" + (": " + "; ".join(motivos) + "." if motivos else ". Mês fechado e conferido."), c=colors.white)]],
                       colWidths=[180 * mm], style=[("BACKGROUND", (0, 0), (-1, -1), cor), ("BOX", (0, 0), (-1, -1), 0, cor),
                                                    ("LEFTPADDING", (0, 0), (-1, -1), 8), ("TOPPADDING", (0, 0), (-1, -1), 6),
                                                    ("BOTTOMPADDING", (0, 0), (-1, -1), 6)]))
    story.append(Spacer(1, 4 * mm))
    kp = [("Receitas", res.get("receitas")), ("Despesas", res.get("despesas")), ("Resultado", res.get("resultado"))]
    cells = [[P(k, s=8, c=MUTED) for k, _ in kp], [P(brl(v), f="DVB", s=14, l=17, c=(RED if D(v) < 0 and k == "Resultado" else INK)) for k, v in kp]]
    story.append(Table(cells, colWidths=[60 * mm] * 3, style=[("BACKGROUND", (0, 0), (-1, -1), SOFT), ("LEFTPADDING", (0, 0), (-1, -1), 8),
                                                              ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 1), (-1, 1), 8)]))
    story.append(P(f"Investimentos (movimentação líquida no mês): {brl(res.get('investimentos'), sinal=True)} — não entra no resultado.", s=8, c=MUTED))
    outros = [(c["category_name"], D(c["total"])) for c in dados["categorias"] or [] if c["category_kind"] not in ("despesa", "receita", "investimento", "transferencia", None)]
    if outros:
        story.append(P("Fora de receitas/despesas (tipo dívida): " + "; ".join(f"{k} {brl(v)}" for k, v in outros) + ".", s=8, c=MUTED))
    story.append(Spacer(1, 5 * mm))

    # gráfico 13 meses
    hist = dados["resumo_13m"]
    dr = Drawing(180 * mm, 62 * mm)
    bc = VerticalBarChart(); bc.x, bc.y, bc.width, bc.height = 14 * mm, 10 * mm, 162 * mm, 46 * mm
    bc.data = [[float(D(h["receitas"])) / 1000 for h in hist], [float(-D(h["despesas"])) / 1000 for h in hist]]
    bc.categoryAxis.categoryNames = [mes_nome(h["month"], True) for h in hist]
    bc.categoryAxis.labels.fontName = "DV"; bc.categoryAxis.labels.fontSize = 6.5
    bc.valueAxis.labels.fontName = "DV"; bc.valueAxis.labels.fontSize = 7; bc.valueAxis.valueMin = 0
    bc.valueAxis.strokeColor = LINE; bc.categoryAxis.strokeColor = LINE; bc.valueAxis.gridStrokeColor = LINE; bc.valueAxis.visibleGrid = 1
    bc.bars[0].fillColor = TEAL; bc.bars[1].fillColor = colors.HexColor("#9AA7B5"); bc.bars.strokeWidth = 0; bc.groupSpacing = 4
    dr.add(bc)
    dr.add(String(14 * mm, 58 * mm, "Receitas × despesas, últimos 13 meses (R$ mil)", fontName="DVB", fontSize=8, fillColor=INK))
    dr.add(String(120 * mm, 58 * mm, "■ receitas", fontName="DV", fontSize=7, fillColor=TEAL))
    dr.add(String(145 * mm, 58 * mm, "■ despesas", fontName="DV", fontSize=7, fillColor=colors.HexColor("#9AA7B5")))
    story += [dr, Spacer(1, 3 * mm)]

    def tab(cab, linhas, larg, alinhar_dir=(), total=None):
        data = [[P(f"<b>{h}</b>", s=7.5, c=colors.white, alignment=2 if j in alinhar_dir else 0) for j, h in enumerate(cab)]]
        for ln in linhas:
            data.append([P(str(v), s=8, alignment=2 if j in alinhar_dir else 0) for j, v in enumerate(ln)])
        if total:
            data.append([P(f"<b>{v}</b>", s=8, alignment=2 if j in alinhar_dir else 0) for j, v in enumerate(total)])
        ts = [("BACKGROUND", (0, 0), (-1, 0), INK), ("LINEBELOW", (0, 1), (-1, -1), 0.3, LINE), ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
              ("TOPPADDING", (0, 0), (-1, -1), 2), ("BOTTOMPADDING", (0, 0), (-1, -1), 2)]
        if total: ts.append(("BACKGROUND", (0, -1), (-1, -1), SOFT))
        return Table(data, colWidths=[w * mm for w in larg], style=ts, repeatRows=1)

    # despesas por grupo × orçamento
    orc = {b["group_name"]: b for b in dados["orcamento"] or []}
    gd = grupos_despesa(dados); tot = sum((v for _, v in gd), Decimal(0))
    linhas = []
    for g, v in gd:
        b = orc.get(g)
        linhas.append([g, brl(-v), brl(b["orcado"]) if b and b["orcado"] is not None else "—",
                       f"{float(b['pct']):.0f}%" if b and b["pct"] is not None else "—", f"{float(v / tot * 100):.1f}%" if tot else ""])
    story += [KeepTogether([P("<b>Despesas por grupo × orçamento</b>", s=10, l=14), Spacer(1, 1.5 * mm),
                            tab(["Grupo", "Gasto", "Orçado", "% do orçado", "% das despesas"], linhas, [62, 32, 32, 26, 28], (1, 2, 3, 4),
                                total=["Total", brl(-tot), "", "", "100%"])]), Spacer(1, 5 * mm)]

    # receitas
    rec = [(c["category_name"], D(c["total"])) for c in dados["categorias"] or [] if c["category_kind"] == "receita"]
    if rec:
        story += [KeepTogether([P("<b>Receitas</b>", s=10, l=14), Spacer(1, 1.5 * mm),
                                tab(["Origem", "Valor"], [[k, brl(v)] for k, v in sorted(rec, key=lambda x: -x[1])], [120, 60], (1,),
                                    total=["Total", brl(sum(v for _, v in rec))])]), Spacer(1, 5 * mm)]

    # cartão
    fat = chk.get("fatura") or {}
    linhas = [[t["titular"], t["cartao"], t["n"], brl(t["total"])] for t in dados["fatura_por_titular"] or []]
    story += [KeepTogether([P("<b>Cartão de crédito</b>", s=10, l=14),
                            P(f"Fatura com fechamento em {data_br(fat.get('fechamento'))}: total por lançamentos {brl(fat.get('lancamentos'))}; "
                              f"débito na conta (valor oficial) {brl(fat.get('pago'))}; diferença {brl(D(fat.get('lancamentos')) - D(fat.get('pago')))}.", s=8, c=MUTED),
                            Spacer(1, 1.5 * mm),
                            tab(["Titular", "Cartão", "Lançamentos", "Total"], linhas, [70, 30, 30, 50], (2, 3),
                                total=["Total", "", sum(t["n"] for t in dados["fatura_por_titular"] or []),
                                       brl(sum(D(t["total"]) for t in dados["fatura_por_titular"] or []))])]), Spacer(1, 5 * mm)]

    # fixas
    fx = dados["fixas"] or []
    dif = [f for f in fx if abs(D(f["pago"]) - D(f["devido"])) > Decimal("0.005")]
    story += [KeepTogether([P("<b>Despesas fixas</b>", s=10, l=14),
                            P(f"{len(fx)} despesas fixas: devido {brl(sum(D(f['devido']) for f in fx))}, pago {brl(sum(D(f['pago']) for f in fx))}. "
                              f"{len(dif)} com valor pago diferente do previsto:", s=8, c=MUTED), Spacer(1, 1.5 * mm),
                            tab(["Despesa", "Devido", "Pago", "Diferença"], [[f["name"], brl(f["devido"]), brl(f["pago"]),
                                 brl(D(f["pago"]) - D(f["devido"]), sinal=True)] for f in sorted(dif, key=lambda f: D(f["pago"]) - D(f["devido"]))],
                                [80, 32, 32, 36], (1, 2, 3))]), Spacer(1, 5 * mm)]

    # conciliação
    soma = sum(D(l["valor"]) for l in lanc)
    conc = [["Lançamentos do mês", f"{len(lanc)} (soma {brl(soma)})", "ok — confere com o banco"],
            ["Fatura × débito em conta", brl(D(fat.get("lancamentos")) - D(fat.get("pago"))),
             "ok" if abs(D(fat.get("lancamentos")) - D(fat.get("pago"))) <= 1 else "conferir"],
            ["Sem categoria", f"{chk.get('pendentes_categoria')} ({brl(chk.get('valor_pendente'))})", "ok" if not chk.get("pendentes_categoria") else "revisar no app"],
            ["Possíveis duplicidades", str(chk.get("duplicidades_abertas")), "ok" if not chk.get("duplicidades_abertas") else "revisar"],
            ["Última sincronização", (chk.get("sincronizacao_ok") or "")[:16].replace("T", " ") + " UTC", ""]]
    story += [KeepTogether([P("<b>Conciliação e qualidade</b>", s=10, l=14), Spacer(1, 1.5 * mm),
                            tab(["Item", "Valor", "Situação"], conc, [62, 62, 56])])]
    pend = [l for l in lanc if l["revisao"] == "pending"]
    if pend:
        story += [Spacer(1, 4 * mm), KeepTogether([P("<b>Lançamentos sem categoria</b>", s=10, l=14), Spacer(1, 1.5 * mm),
                  tab(["Data", "Descrição", "Valor"], [[data_br(l["data"]), (l["contraparte"] or l["descricao"])[:60], brl(l["valor"])] for l in pend],
                      [22, 118, 40], (2,))])]
    story += [Spacer(1, 6 * mm), P("Planilha anexa com todos os lançamentos, categorias, orçamento, cartão, fixas e as conferências recalculadas "
                                    "por fórmula. Total oficial da fatura = débito na conta; o total por lançamentos é estimativa (parcelas de "
                                    "compras com mais de 12 meses não vêm da Pluggy). Projeções não fazem parte deste relatório.", s=7.5, c=MUTED)]

    def rodape(cv, doc):
        cv.saveState(); cv.setFont("DV", 7); cv.setFillColor(MUTED)
        cv.drawString(15 * mm, 10 * mm, f"Família Finance AI · {mes_nome(m)} · gerado em {date.today().strftime('%d/%m/%Y')}")
        cv.drawRightString(195 * mm, 10 * mm, f"página {doc.page}"); cv.restoreState()
    SimpleDocTemplate(path, pagesize=A4, leftMargin=15 * mm, rightMargin=15 * mm, topMargin=14 * mm, bottomMargin=16 * mm,
                      title=f"Relatório {mes_nome(m)}", author="Família Finance AI").build(story, onFirstPage=rodape, onLaterPages=rodape)


if __name__ == "__main__":
    src, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    dados, lanc = carregar(src)
    base = os.path.join(out, f"relatorio_{dados['mes'][:7]}")
    planilha(dados, lanc, base + ".xlsx")
    pdf(dados, lanc, base + ".pdf")
    print(base + ".xlsx"); print(base + ".pdf")
