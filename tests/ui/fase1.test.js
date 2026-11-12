// Teste da Fase 1 com Supabase simulado. Uso: node fase1.test.js <url_app> <dir_saida>
const { chromium } = require('playwright');
const fs = require('fs');
const APP = process.argv[2] || 'http://localhost:3999/';
const OUT = process.argv[3] || '.';
const SB = fs.readFileSync(__dirname + '/sb.mjs');
let FAIL = null;            // tabela que deve responder 500
const calls = [];           // rpc chamadas
const G = Array.from({ length: 24 }, (_, i) => ({ id: 'g' + i, name: 'Grupo ' + (i + 1) }));
const cats = [{ id: 'alimentacao', name: 'Alimentação', parent_id: null, sort: 1, kind: 'despesa' }, { id: 'mercado', name: 'Mercado', parent_id: 'alimentacao', sort: 2, kind: 'despesa' },
  ...G.map((g, i) => ({ id: g.id, name: g.name, parent_id: null, sort: 10 + i, kind: 'despesa' }))];
const tx = [
  { id: 't1', event_date: '2026-11-10', amount: -120.5, description: 'BIG LAR', counterpart_name: 'Big Lar', category_id: 'mercado', category_name: 'Mercado', category_source: 'regra_estabelecimento', review_status: 'auto', account_name: 'Unique', source: 'pluggy', card_last4: '8305', holder_name: 'Hugo', month: '2026-11-01' },
  { id: 't2', event_date: '2026-11-09', amount: -45, description: 'PAGAR.ME', counterpart_name: null, category_id: null, category_name: null, category_source: 'pendente', review_status: 'pending', account_name: 'Conta', source: 'pluggy', month: '2026-11-01' }];
function data(table, url) {
  const m = url.searchParams;
  switch (table) {
    case 'household_members': return [{ id: 'm1', role: 'owner', display_name: 'Hugo', auth_user_id: 'u1', email: 'hugo@example.invalid' }];
    case 'categories': return cats;
    case 'accounts': return [{ id: 'a1', name: 'Conta Santander', subtype: 'CHECKING_ACCOUNT', number: '1', balance: 20143.76 }, { id: 'a2', name: 'Unique', subtype: 'CREDIT_CARD', number: '5430', balance: -33081.13 }];
    case 'v_month_summary': return [{ month: '2026-11-01', receitas: 30000, despesas: -25000, investimentos: 0, resultado: 5000, pendentes: 4, valor_pendente: 300 }, { month: '2026-10-01', receitas: 73182.87, despesas: -93332.25, investimentos: 20008.5, resultado: -20149.38, pendentes: 7, valor_pendente: 543.62 }];
    case 'v_category_month': return G.map((g, i) => ({ month: '2026-11-01', group_id: g.id, group_name: g.name, category_id: g.id, category_name: g.name, category_kind: 'despesa', n: 3, total: -(1000 + i * 37) }));
    case 'v_budget_month': return G.map((g, i) => ({ month: '2026-11-01', group_id: g.id, group_name: g.name, orcado: 1500, source: 'hugo', gasto: 1000 + i * 37, saldo: 500, pct: 66 }));
    case 'v_daily_flow': return Array.from({ length: 12 }, (_, i) => ({ event_date: '2026-11-' + String(i + 1).padStart(2, '0'), saidas: -800, entradas: 0 }));
    case 'v_sync_status': return [{ connector_name: 'MeuPluggy', status: 'UPDATED', provider_updated_at: '2026-11-12T01:07:34Z', consent_warning: false, last_job_status: 'SUCCESS' }];
    case 'v_alerts': return [];
    case 'monthly_closings': return [];
    case 'v_tx': return tx;
    default: return [];
  }
}
(async () => {
  const b = await chromium.launch();
  const results = []; const ok = (name, cond, extra) => { results.push([cond ? 'OK ' : 'FALHA', name, extra || '']); };
  async function newPage(vp, clockIso) {
    const ctx = await b.newContext({ viewport: vp, serviceWorkers: 'block' });
    const p = await ctx.newPage();
    const errs = []; p.on('pageerror', e => errs.push(e.message)); p.on('console', m => { if (m.type() === 'error' && !/Failed to load resource/.test(m.text())) errs.push(m.text()); });
    if (clockIso) await p.clock.setFixedTime(new Date(clockIso));
    await p.route('https://cdn.jsdelivr.net/**', r => r.fulfill({ status: 200, contentType: 'application/javascript', body: SB }));
    await p.route('https://fonts.googleapis.com/**', r => r.abort());
    await p.route('**/auth/v1/**', r => r.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ id: 'u1', aud: 'authenticated' }) }));
    await p.route('**/rest/v1/**', async r => {
      const u = new URL(r.request().url()); const parts = u.pathname.split('/rest/v1/')[1];
      if (parts.startsWith('rpc/')) {
        const fn = parts.slice(4); calls.push({ fn, body: r.request().postDataJSON() });
        if (fn === 'month_close_check') return r.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ mes: '2026-11-01', mes_encerrado: true, pronto: false, pendentes_categoria: 4, valor_pendente: 300, duplicidades_abertas: 0, fatura: { status: 'paga', fechamento: '2026-10-29', lancamentos: 100, pago: 100, fonte_fechamento: 'pdf' } }) });
        return r.fulfill({ status: 200, contentType: 'application/json', body: 'null' });
      }
      if (FAIL && parts === FAIL) return r.fulfill({ status: 500, contentType: 'application/json', body: JSON.stringify({ message: 'erro simulado' }) });
      if (r.request().method() === 'HEAD') return r.fulfill({ status: 200, headers: { 'content-range': '0-3/4' }, body: '' });
      const rows = data(parts, u);
      const acc = r.request().headers()['accept'] || '';
      if (acc.includes('vnd.pgrst.object')) return r.fulfill({ status: rows.length ? 200 : 406, contentType: 'application/json', body: JSON.stringify(rows[0] || {}) });
      return r.fulfill({ status: 200, contentType: 'application/json', headers: { 'content-range': '0-' + (rows.length - 1) + '/' + rows.length }, body: JSON.stringify(rows) });
    });
    await p.addInitScript(() => {
      const exp = Math.floor(Date.now() / 1000) + 86400 * 365;
      const tok = 'eyJhbGciOiJIUzI1NiJ9.' + btoa(JSON.stringify({ sub: 'u1', exp, role: 'authenticated' })) + '.x';
      localStorage.setItem('sb-hrsinekxrfiphlhpoewp-auth-token', JSON.stringify({ access_token: tok, token_type: 'bearer', expires_in: 3600, expires_at: exp, refresh_token: 'r', user: { id: 'u1', email: 'hugo@example.invalid', aud: 'authenticated', role: 'authenticated' } }));
    });
    return { p, ctx, errs };
  }
  const idle = async (p) => { await p.waitForFunction(() => !document.body.classList.contains('loading'), null, { timeout: 8000 }); await p.waitForTimeout(150); };

  // 1) Início + voltar devolve o lugar
  let { p, ctx, errs } = await newPage({ width: 390, height: 844 }, '2026-11-12T15:00:00-04:00');
  await p.goto(APP + '#inicio'); await idle(p);
  ok('Início renderiza', await p.locator('h1', { hasText: 'Início' }).count() === 1);
  await p.screenshot({ path: OUT + '/f1-inicio.png' });
  await p.evaluate(() => scrollTo(0, 900)); await p.waitForTimeout(100);
  const y0 = await p.evaluate(() => scrollY);
  const link = p.locator('a.item[href^="#categoria?"]').nth(10); await link.scrollIntoViewIfNeeded(); await p.evaluate(() => scrollTo(0, 900));
  await p.evaluate(() => { location.hash = document.querySelectorAll('a.item[href^="#categoria?"]')[10].getAttribute('href').slice(1) }); await idle(p);
  ok('drill-down abre o detalhe da categoria no topo', (await p.locator('.crumb', { hasText: 'Início' }).count()) === 1 && (await p.evaluate(() => scrollY)) === 0);
  await p.goBack(); await p.waitForTimeout(60);
  const yInstant = await p.evaluate(() => scrollY); const hInstant = await p.locator('h1', { hasText: 'Início' }).count();
  await idle(p); const y1 = await p.evaluate(() => scrollY);
  ok('Voltar mostra Início na hora (sem esperar o banco)', hInstant === 1, 'scroll imediato=' + yInstant);
  ok('Voltar restaura a rolagem', Math.abs(y1 - y0) <= 2, 'antes=' + y0 + ' depois=' + y1);

  // 2) Janela de categoria: regra desmarcada, Esc, Voltar do Android, Desfazer
  await p.evaluate(() => { location.hash = 'lancamentos?month=2026-11' }); await idle(p);
  await p.locator('.item', { hasText: 'Big Lar' }).click(); await p.waitForTimeout(100);
  ok('janela abre como diálogo', await p.locator('#sheet.on #sheetBody[role=dialog]').count() === 1);
  ok('"criar regra" vem desmarcado', !(await p.locator('#rule').isChecked()));
  ok('foco vai para a janela', await p.evaluate(() => document.getElementById('sheetBody').contains(document.activeElement)));
  await p.keyboard.press('Escape'); await p.waitForTimeout(150);
  ok('Esc fecha a janela', await p.locator('#sheet.on').count() === 0);
  await p.locator('.item', { hasText: 'Big Lar' }).click(); await p.waitForTimeout(100);
  await p.goBack(); await p.waitForTimeout(200);
  ok('Voltar (Android) fecha a janela e fica na tela', (await p.locator('#sheet.on').count()) === 0 && (await p.locator('h1', { hasText: 'Lançamentos' }).count()) === 1);
  await p.locator('.item', { hasText: 'Big Lar' }).click(); await p.waitForTimeout(100);
  await p.selectOption('#cx', 'g3'); calls.length = 0;
  await p.getByRole('button', { name: 'Salvar categoria' }).click(); await p.waitForTimeout(300);
  ok('salvar mostra "Desfazer"', await p.locator('#toast button', { hasText: 'Desfazer' }).isVisible());
  await p.screenshot({ path: OUT + '/f1-desfazer.png' });
  await p.locator('#toast button', { hasText: 'Desfazer' }).click(); await p.waitForTimeout(300);
  const undo = calls.filter(c => c.fn === 'set_transaction_category');
  ok('Desfazer restaura a categoria anterior sem criar regra', undo.length === 2 && undo[1].body.p_category === 'mercado' && undo[1].body.p_create_rule === false, JSON.stringify(undo.map(u => u.body)));
  ok('tela continua em Lançamentos após salvar', (await p.locator('h1', { hasText: 'Lançamentos' }).count()) === 1 && (await p.locator('#sheet.on').count()) === 0);

  // 3) Fechar o mês: confirmação própria, ressalva obrigatória
  await p.evaluate(() => { location.hash = 'inicio' }); await idle(p);
  await p.locator('#closeBtn').scrollIntoViewIfNeeded(); await p.locator('#closeBtn').click(); await p.waitForTimeout(150);
  ok('Fechar mês pede confirmação', await p.locator('#sheet.on', { hasText: 'Fechar' }).count() === 1);
  calls.length = 0; await p.locator('#sheetBody').getByRole('button', { name: 'Fechar com ressalva' }).click(); await p.waitForTimeout(200);
  ok('sem ressalva não fecha', calls.filter(c => c.fn === 'close_month').length === 0);
  await p.fill('#cnotes', '4 lançamentos sem categoria'); await p.locator('#sheetBody').getByRole('button', { name: 'Fechar com ressalva' }).click(); await p.waitForTimeout(300);
  const cl = calls.filter(c => c.fn === 'close_month');
  ok('com ressalva fecha', cl.length === 1 && cl[0].body.p_notes === '4 lançamentos sem categoria' && cl[0].body.p_force === true, JSON.stringify(cl.map(c => c.body)));
  ok('sem erros de JS (celular)', errs.length === 0, errs.join(' | '));
  await ctx.close();

  // 4) Falha de dados: tela escondida com "Tentar de novo"
  FAIL = 'v_category_month';
  ({ p, ctx, errs } = await newPage({ width: 390, height: 844 }, '2026-11-12T15:00:00-04:00'));
  await p.goto(APP + '#inicio'); await idle(p);
  ok('falha mostra aviso em vez de números', await p.locator('.errbox', { hasText: 'Não consegui carregar' }).count() === 1);
  await p.screenshot({ path: OUT + '/f1-erro.png' });
  await p.getByRole('button', { name: 'Ver o que carregou' }).click(); await p.waitForTimeout(100);
  ok('"Ver o que carregou" mostra a tela com alerta', await p.locator('.failnote').count() === 1 && await p.locator('h1', { hasText: 'Início' }).count() === 1);
  FAIL = null; await p.locator('.failnote a').click(); await idle(p);
  ok('"Tentar de novo" recupera', await p.locator('.errbox, .failnote').count() === 0 && await p.locator('h1', { hasText: 'Início' }).count() === 1);
  await ctx.close();

  // 5) Fuso: 30/11 às 23h30 em Cuiabá (já 01/12 em UTC) deve continuar em novembro
  ({ p, ctx, errs } = await newPage({ width: 390, height: 844 }, '2026-11-30T23:30:00-04:00'));
  await p.goto(APP + '#inicio'); await idle(p);
  const sel = await p.$eval('#mp', s => s.value);
  ok('mês atual em Cuiabá às 23h30 do dia 30', sel === '2026-11', 'selecionado=' + sel);
  await ctx.close();

  // 6) Notebook: sem erros e layout em colunas preservado
  ({ p, ctx, errs } = await newPage({ width: 1366, height: 900 }, '2026-11-12T15:00:00-04:00'));
  await p.goto(APP + '#inicio'); await idle(p);
  ok('notebook: colunas aplicadas', await p.locator('#app .secs').count() === 1);
  await p.screenshot({ path: OUT + '/f1-desk.png' });
  ok('sem erros de JS (notebook)', errs.length === 0, errs.join(' | '));
  await ctx.close(); await b.close();
  for (const r of results) console.log(r.join('  '));
  console.log(results.filter(r => r[0] !== 'OK ').length ? 'RESULTADO: HÁ FALHAS' : 'RESULTADO: TUDO OK (' + results.length + ' verificações)');
})().catch(e => { console.error('ERRO NO TESTE', e); process.exit(1); });
