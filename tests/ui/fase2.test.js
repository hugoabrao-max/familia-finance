// Teste da Fase 2 (Início + detalhe de categoria; desde a v0.26 no visual de caderno: linhas em vez de cards) com Supabase simulado.
// Uso: node fase2.test.js <url_app> <dir_saida>   (requer sb.mjs; ver README.md)
const { chromium } = require('playwright');
const FORA = []; // chamadas que escaparam do simulado
const fs = require('fs');
const fontes = require('./fontes');
const APP = process.argv[2] || 'http://localhost:3999/';
const OUT = process.argv[3] || '.';
const SB = fs.readFileSync(__dirname + '/sb.mjs');
const reqs = [];
const G = [['alimentacao', 'Alimentação', 2200, 2000], ['lazer', 'Lazer', 1800, 1000], ['moradia', 'Moradia', 3000, 5000], ['saude', 'Saúde', 400, null]];
const cats = [...G.map(([id, name], i) => ({ id, name, parent_id: null, sort: i, kind: 'despesa' })),
  { id: 'mercado', name: 'Mercado', parent_id: 'alimentacao', sort: 10, kind: 'despesa' }, { id: 'restaurantes', name: 'Restaurantes', parent_id: 'alimentacao', sort: 11, kind: 'despesa' },
  { id: 'receita', name: 'Receita', parent_id: null, sort: 20, kind: 'receita' }];
function data(t, u) {
  const q = (k) => u.searchParams.get(k) || '';
  switch (t) {
    case 'household_members': return [{ id: 'm1', role: 'owner', display_name: 'Hugo', auth_user_id: 'u1', household_id: 'h1' }];
    case 'households': return q('id') === 'eq.h1' ? [{ name: 'Família Abrão' }] : [];
    case 'categories': return cats;
    case 'accounts': return [{ id: 'a1', name: 'Conta', subtype: 'CHECKING_ACCOUNT', number: '1', balance: 20143.76 }, { id: 'a3', name: 'Poup', subtype: 'SAVINGS_ACCOUNT', number: '2', balance: 1235.36 }, { id: 'a2', name: 'Unique', subtype: 'CREDIT_CARD', number: '5430', balance: -33081.13 }];
    case 'v_month_summary': return [{ month: '2026-11-01', receitas: 30000, despesas: -7400, investimentos: 0, resultado: 22600, pendentes: 4, valor_pendente: 300 }, { month: '2026-10-01', receitas: 73182.87, despesas: -93332.25, investimentos: 20008.5, resultado: -20149.38, pendentes: 7, valor_pendente: 543.62 }];
    case 'v_category_month':
      if (q('group_id')) { // detalhe: 7 meses do grupo, 2 subcategorias no mês
        const out = []; for (let k = 0; k < 7; k++) { const mm = ['2026-05', '2026-06', '2026-07', '2026-08', '2026-09', '2026-10', '2026-11'][k]; out.push({ month: mm + '-01', category_id: 'mercado', category_name: 'Mercado', n: 5, total: -(1000 + k * 100) }); out.push({ month: mm + '-01', category_id: 'restaurantes', category_name: 'Restaurantes', n: 3, total: -(500 + k * 20) }); }
        return out; }
      return [...G.map(([id, name, v]) => ({ month: '2026-11-01', group_id: id, group_name: name, category_id: id, category_name: name, category_kind: 'despesa', n: 4, total: -v })),
        { month: '2026-11-01', group_id: 'receita', group_name: 'Receita', category_id: 'receita', category_name: 'Receita', category_kind: 'receita', n: 2, total: 30000 }];
    case 'v_budget_month': return q('group_id') ? [{ orcado: 2000, source: 'hugo' }] : G.filter(g => g[3]).map(([id, name, , o]) => ({ group_id: id, group_name: name, orcado: o, source: 'hugo' }));
    case 'v_daily_flow': return Array.from({ length: 12 }, (_, i) => ({ event_date: '2026-11-' + String(i + 1).padStart(2, '0'), saidas: -600 }));
    case 'v_sync_status': return [{ provider_updated_at: '2026-11-12T01:07:34Z', consent_warning: false, last_job_status: 'SUCCESS' }];
    case 'v_alerts': return [{ kind: 'categoria_ritmo', severity: 'media', title: 'Lazer acima do ritmo', detail: 'x', ref_date: '2026-11-12' }, { kind: 'compra_grande', severity: 'baixa', title: 'Compra de R$ 1.305,84 em ASSAI ATACADISTA  LJ19', detail: 'Hugo', ref_date: '2026-11-10' }];
    case 'v_card_bills': return [{ closing_date: '2026-11-27', due_date: '2026-12-06', total_lancamentos: 33081.13, status: 'aberta' }];
    // outubro, para o ritmo (gastos por competência até o mesmo dia): até o dia 12 = 2.000 + 1.800 = 3.800
    case 'v_tx': if (u.searchParams.get('month') === 'eq.2026-10-01' && u.searchParams.get('select') === 'amount,event_date') return [
      { amount: -2000, event_date: '2026-10-05' }, { amount: -1800, event_date: '2026-10-12' }, { amount: -3000, event_date: '2026-10-20' }];
      return [
      { id: 't1', event_date: '2026-11-10', amount: -300, description: 'BIG LAR', counterpart_name: 'Big Lar', category_id: 'mercado', category_name: 'Mercado' },
      { id: 't2', event_date: '2026-11-08', amount: -200, description: 'BIG LAR', counterpart_name: 'Big Lar', category_id: 'mercado', category_name: 'Mercado' },
      { id: 't3', event_date: '2026-11-07', amount: -150, description: 'IFD*CUPIM', counterpart_name: null, category_id: 'restaurantes', category_name: 'Restaurantes' },
      { id: 't4', event_date: '2026-11-03', amount: -926, description: 'FORMULA 3', counterpart_name: null, category_id: 'mercado', category_name: 'Mercado', installment_number: 3, installment_total: 12, card_last4: '8305', holder_name: 'Hugo' }];
    default: return [];
  }
}
(async () => {
  const b = await chromium.launch(); const results = []; const ok = (n, c, x) => results.push([c ? 'OK ' : 'FALHA', n, x || '']);
  async function page(vp, scheme, dsf) {
    const ctx = await b.newContext({ viewport: vp, serviceWorkers: 'block', colorScheme: scheme || 'light', deviceScaleFactor: dsf || 1 }); const p = await ctx.newPage();
    const errs = []; p.on('pageerror', e => errs.push(e.message));
    await p.clock.setFixedTime(new Date('2026-11-12T15:00:00-04:00'));
    // barra tudo que não for simulado abaixo (nada chega ao Supabase real); rotas registradas depois têm prioridade
    await p.route(u => !u.href.startsWith(APP), r => { const h = new URL(r.request().url()).hostname; if (!/fonts\.(googleapis|gstatic)\.com$/.test(h)) FORA.push(r.request().url()); return r.abort(); });
    await p.route('https://cdn.jsdelivr.net/**', r => r.fulfill({ status: 200, contentType: 'application/javascript', body: SB }));
    await p.route('https://fonts.googleapis.com/**', r => r.abort());
    await p.route('**/auth/v1/**', r => r.fulfill({ status: 200, contentType: 'application/json', body: '{}' }));
    await p.route('**/rest/v1/**', r => {
      const u = new URL(r.request().url()); const t = u.pathname.split('/rest/v1/')[1]; reqs.push(t + '?' + u.searchParams.toString());
      if (t.startsWith('rpc/')) return r.fulfill({ status: 200, contentType: 'application/json', body: t === 'rpc/month_close_check' ? JSON.stringify({ mes_encerrado: false }) : 'null' });
      if (r.request().method() === 'HEAD') return r.fulfill({ status: 200, headers: { 'content-range': '0-3/4', 'access-control-expose-headers': 'content-range', 'access-control-allow-origin': '*' }, body: '' });
      const rows = data(t, u); return r.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(rows) });
    });
    if (dsf) await fontes(p);
    await p.addInitScript(() => { const exp = Math.floor(Date.now() / 1000) + 86400 * 365; localStorage.setItem('sb-hrsinekxrfiphlhpoewp-auth-token', JSON.stringify({ access_token: 'a.' + btoa(JSON.stringify({ sub: 'u1', exp })) + '.x', token_type: 'bearer', expires_at: exp, refresh_token: 'r', user: { id: 'u1', aud: 'authenticated' } })) });
    return { ctx, p, errs };
  }
  const idle = async (p) => { await p.waitForFunction(() => !document.body.classList.contains('loading'), null, { timeout: 8000 }); await p.waitForTimeout(150); };

  let { ctx, p, errs } = await page({ width: 390, height: 844 });
  await p.goto(APP + '#inicio'); await idle(p);
  await p.screenshot({ path: OUT + '/f2-inicio.png', fullPage: true });
  const nb = (x) => (x || '').replace(/\u00a0/g, ' ');
  ok('topo: nome da família e mês com setas', (await p.locator('.top .fam').textContent()) === 'Família Abrão' && await p.locator('#mp').inputValue() === '2026-11' && (await p.locator('.top .mes .ml > span').textContent()) === 'novembro');
  ok('destaque "Sobrou até hoje, dia 12"', (await p.locator('.lead .l').textContent()).includes('Sobrou até hoje, dia 12'));
  ok('Sobrou mostra o valor e o mês anterior', nb(await p.locator('.lead .big').textContent()) === 'R$ 22.600' && (await p.locator('.lead .s').textContent()).includes('Em outubro faltaram'));
  ok('um só número grande na tela', await p.locator('#app .big').count() === 1);
  const led = await p.$$eval('.ledger .lr', es => es.map(e => [e.querySelector('.k').firstChild.textContent, e.querySelector('.v').textContent]));
  ok('linhas: receitas, gastos, fatura (sem "R$" repetido)', JSON.stringify(led) === JSON.stringify([['Receitas', '30.000'], ['Gastos até hoje', '7.400'], ['Fatura aberta', '33.081']]), JSON.stringify(led));
  ok('linhas fecham com o destaque (30.000 − 7.400 = 22.600)', 30000 - 7400 === 22600 && led[1][1] === '7.400');
  ok('fatura aberta: vence 06/12', (await p.locator('.ledger .lr').nth(2).textContent()).includes('vence 06/12'));
  const need = await p.locator('.need').textContent();
  ok('"Precisa de você" junta pendentes, fixas e alertas', need.includes('4 lançamentos sem categoria') && need.includes('4 contas fixas para confirmar') && need.includes('Lazer acima do ritmo') && (await p.locator('h2', { hasText: 'Precisa de você' }).textContent()).includes('4'), JSON.stringify(need));
  ok('pendentes: ação "revisar" leva à Revisão', await p.locator('.need a', { hasText: 'sem categoria' }).getAttribute('href') === '#revisao' && (await p.locator('.need a', { hasText: 'sem categoria' }).locator('b').textContent()) === 'revisar');
  ok('alerta de categoria leva ao detalhe', await p.locator('.need a', { hasText: 'Lazer acima do ritmo' }).getAttribute('href') === '#categoria?id=lazer&month=2026-11');
  ok('alerta de compra grande leva à compra', (await p.locator('.need a', { hasText: 'ASSAI' }).getAttribute('href')).startsWith('#lancamentos?month=2026-11&search=ASSAI'));
  // ritmo: compara com o mês anterior até o mesmo dia (outubro até o dia 12 = 3.800; o dia 20 fica de fora); gasto 7.400 → 3.600 acima
  const rit = nb(await p.locator('.ritmo').textContent());
  ok('ritmo: barra única "Gasto × outubro até o dia 12"', rit.includes('Gasto 7.400') && rit.includes('outubro até o dia 12 3.800') && rit.includes('R$ 3.600 acima de outubro no mesmo dia') && await p.locator('svg.chart').count() === 0, rit);
  ok('ritmo: traço em outubro (3.800 de 7.400 = 51,4%) e gasto em 100%', Math.abs(parseFloat(await p.$eval('.ritmo .bar b', e => e.style.left)) - 51.4) < 0.05 && parseFloat(await p.$eval('.ritmo .bar i', e => e.style.width)) === 100);
  ok('cabeçalho do ritmo: dia 12 de 30', (await p.locator('h2', { hasText: 'Ritmo do mês' }).textContent()).includes('dia 12 de 30'));
  const order = await p.$$eval('#cats + .list a.item .t', es => es.map(e => e.textContent.trim()));
  ok('categorias: mais estouradas primeiro, sem orçamento no fim', JSON.stringify(order) === JSON.stringify(['Lazer', 'Alimentação', 'Moradia', 'Saúde']), order.join(', '));
  const lz = nb(await p.locator('#cats + .list a.item').first().textContent()); ok('Lazer mostra "passou R$ 800 de 1.000"', lz.includes('passou R$ 800 de 1.000'), JSON.stringify(lz));
  ok('explicação longa saiu da tela e virou "?"', !(await p.locator('#app').textContent()).includes('Mais estouradas primeiro') && await p.locator('#cats .ajuda').count() === 1);
  await p.locator('#cats .ajuda').click(); await p.waitForTimeout(100);
  ok('"?" mostra a explicação', (await p.locator('#toast').textContent()).includes('Mais estouradas primeiro'));
  ok('receitas leva aos lançamentos do grupo de receita', await p.locator('.ledger a.lr').first().getAttribute('href') === '#lancamentos?month=2026-11&group=receita');
  await p.locator('.ledger button.lr').click(); await p.waitForTimeout(600);
  const ct = await p.evaluate(() => [document.getElementById('cats').getBoundingClientRect().top, scrollY, document.documentElement.scrollHeight - innerHeight]); ok('linha Gastos rola até as categorias', Math.abs(ct[0]) < 80 || ct[1] >= ct[2] - 2, JSON.stringify(ct));
  // setas do mês
  ok('mês atual: "Próximo mês" desativado', await p.locator('button[aria-label="Próximo mês"]').isDisabled());
  await p.evaluate(() => scrollTo(0, 0)); reqs.length = 0;
  await p.locator('button[aria-label="Mês anterior"]').click(); await idle(p);
  ok('"Mês anterior" abre outubro', await p.locator('#mp').inputValue() === '2026-10' && (await p.locator('.top .mes .ml > span').textContent()) === 'outubro' && reqs.some(r => r.startsWith('v_category_month?') && r.includes('month=eq.2026-10-01')) && (await p.locator('.lead .l').textContent()).includes('Faltou em outubro'));
  await p.locator('button[aria-label="Próximo mês"]').click(); await idle(p);
  ok('"Próximo mês" volta a novembro', await p.locator('#mp').inputValue() === '2026-11');

  // drill-down: categoria → detalhe → voltar
  await p.evaluate(() => scrollTo(0, 500)); await p.waitForTimeout(80); const y0 = await p.evaluate(() => scrollY);
  await p.locator('#cats + .list a.item', { hasText: 'Alimentação' }).click(); await idle(p);
  await p.screenshot({ path: OUT + '/f2-categoria.png', fullPage: true });
  ok('detalhe abre com título da categoria', (await p.locator('h1').textContent()).trim() === 'Alimentação');
  ok('detalhe: 7 meses no histórico, atual destacado', await p.locator('.hist a').count() === 7 && (await p.locator('.hist a.on').textContent()).includes('nov'));
  ok('detalhe: subcategorias', (await p.locator('h2', { hasText: 'Por subcategoria' }).count()) === 1 && (await p.locator('a.item[href*="&cat=mercado"]').count()) === 1);
  const est = await p.$$eval('h2:has-text("Onde mais gastou") + .list .t', es => es.map(e => e.textContent));
  ok('detalhe: onde mais gastou agrega e exclui parcelas', JSON.stringify(est) === JSON.stringify(['Big Lar', 'IFD*CUPIM']), est.join(', '));
  ok('detalhe: parcelas separadas', (await p.locator('h2', { hasText: 'Parcelas que caem neste mês' }).count()) === 1 && (await p.locator('text=parcela 3/12').count()) === 1);
  ok('detalhe: "Ver todos os 4 lançamentos"', (await p.locator('a.card', { hasText: 'Ver todos os 4 lançamentos de Alimentação' }).count()) === 1);
  await p.locator('.crumb').click(); await idle(p);
  ok('"‹ Início" volta ao mesmo ponto', Math.abs((await p.evaluate(() => scrollY)) - y0) <= 2 && (await p.locator('h1').first().textContent()).trim() === 'Início', 'y0=' + y0);

  // mês no histórico e filtro de subcategoria
  await p.locator('#cats + .list a.item', { hasText: 'Alimentação' }).click(); await idle(p);
  await p.locator('.hist a').nth(5).click(); await idle(p);
  ok('tocar num mês do histórico abre aquele mês', (await p.evaluate(() => location.hash)).includes('month=2026-10'));
  reqs.length = 0; await p.locator('a.item[href*="&cat=mercado"]').click(); await idle(p);
  ok('subcategoria filtra Lançamentos por category_id', reqs.some(r => r.startsWith('v_tx?') && r.includes('category_id=eq.mercado')));
  ok('sem erros de JS (celular)', errs.length === 0, errs.join(' | '));
  await ctx.close();

  // tema escuro e notebook
  ({ ctx, p, errs } = await page({ width: 390, height: 844 }, 'dark'));
  await p.goto(APP + '#inicio'); await idle(p);
  const bg = await p.evaluate(() => [getComputedStyle(document.body).backgroundColor, getComputedStyle(document.querySelector('.need a')).color, getComputedStyle(document.querySelector('.lead .big')).color]);
  ok('tema escuro: papel escuro, texto claro e destaque verde claro', JSON.stringify(bg) === JSON.stringify(['rgb(21, 23, 19)', 'rgb(236, 234, 225)', 'rgb(141, 194, 156)']), JSON.stringify(bg));
  await p.screenshot({ path: OUT + '/f2-escuro.png' });
  await ctx.close();
  for (const sc of ['light', 'dark']) { // capturas do redesenho (390×844, escala 2)
    ({ ctx, p, errs } = await page({ width: 390, height: 844 }, sc, 2));
    await p.goto(APP + '#inicio'); await idle(p); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(200);
    await p.setViewportSize({ width: 390, height: Math.max(844, await p.evaluate(() => document.documentElement.scrollHeight)) }); await p.waitForTimeout(100);
    await p.screenshot({ path: OUT + '/redesenho-inicio-' + (sc === 'light' ? 'claro' : 'escuro') + '.png' });
    ok('sem erros de JS (captura ' + sc + ')', errs.length === 0, errs.join(' | ')); await ctx.close();
  }
  ({ ctx, p, errs } = await page({ width: 1366, height: 900 }));
  await p.goto(APP + '#inicio'); await idle(p); await p.screenshot({ path: OUT + '/f2-desk.png' });
  await p.goto(APP + '#categoria?id=alimentacao&month=2026-11'); await idle(p);
  ok('notebook: detalhe por link direto', (await p.locator('h1').textContent()).trim() === 'Alimentação');
  ok('sem erros de JS (notebook)', errs.length === 0, errs.join(' | '));
  await ctx.close(); await b.close();
  for (const r of results) console.log(r.join('  '));
  { const okF = FORA.length === 0; results.push([okF ? 'OK ' : 'FALHA', 'nenhuma chamada saiu do simulado', FORA.slice(0, 3).join(' ')]); if (!okF) console.log('FALHA', 'nenhuma chamada saiu do simulado', FORA.slice(0, 3).join(' ')); }
  console.log(results.filter(r => r[0] !== 'OK ').length ? 'RESULTADO: HÁ FALHAS' : 'RESULTADO: TUDO OK (' + results.length + ' verificações)');
  process.exitCode = results.some(r => r[0] !== 'OK ') ? 1 : 0;
})().catch(e => { console.error('ERRO NO TESTE', e); process.exit(1); });
