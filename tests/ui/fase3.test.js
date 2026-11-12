// Teste da Fase 3 (Lançamentos por dia com totais e "carregar mais"; busca ao digitar; Revisão em lote) com Supabase simulado.
// Uso: node fase3.test.js <url_app> <dir_saida>   (requer sb.mjs; ver README.md)
const { chromium } = require('playwright');
const fs = require('fs');
const APP = process.argv[2] || 'http://localhost:3999/';
const OUT = process.argv[3] || '.';
const SB = fs.readFileSync(__dirname + '/sb.mjs');
const reqs = [], rpcs = [];
const cats = [{ id: 'alimentacao', name: 'Alimentação', parent_id: null, sort: 0, kind: 'despesa' }, { id: 'padaria', name: 'Padaria', parent_id: 'alimentacao', sort: 1, kind: 'despesa' },
  { id: 'transporte', name: 'Transporte', parent_id: null, sort: 2, kind: 'despesa' }, { id: 'receita', name: 'Receita', parent_id: null, sort: 3, kind: 'receita' }];
// 250 lançamentos em nov/26: 2 por dia em média, do dia 12 para trás; 1 receita de 10.000 a cada 50
const TX = Array.from({ length: 250 }, (_, i) => { const d = 12 - Math.floor(i / 25); const inc = i % 50 === 0;
  return { id: 'x' + String(1000 - i), event_date: '2026-11-' + String(d).padStart(2, '0'), amount: inc ? 10000 : -(10 + (i % 7)), description: i % 3 ? 'PADARIA PAO BOM' : 'POSTO SHELL',
    counterpart_name: i % 3 ? 'Padaria Pão Bom' : null, category_id: inc ? 'receita' : 'alimentacao', category_name: inc ? 'Receita' : 'Alimentação', review_status: 'reviewed', account_name: 'Conta', source: 'pluggy' }; });
const PEND = [
  { id: 'p1', event_date: '2026-11-11', amount: -32.5, description: 'PADARIA PAO BOM', counterpart_name: 'Padaria Pão Bom', category_id: null },
  { id: 'p2', event_date: '2026-11-09', amount: -18, description: 'PADARIA PAO BOM', counterpart_name: 'Padaria Pão Bom', category_id: null },
  { id: 'p3', event_date: '2026-11-02', amount: -21, description: 'PAD PAO BOM', counterpart_name: 'PADARIA PÃO  BOM', category_id: null },
  { id: 'p4', event_date: '2026-11-10', amount: -25.9, description: 'UBER *TRIP', counterpart_name: null, category_id: 'transporte' },
  { id: 'p5', event_date: '2026-11-04', amount: -14.1, description: 'Uber *Trip', counterpart_name: null, category_id: 'transporte' },
  { id: 'p6', event_date: '2026-10-30', amount: -700, description: 'PIX ENVIADO', counterpart_name: 'Fulano de Tal', category_id: null }].map(r => ({ ...r, review_status: 'pending', account_name: 'Conta', source: 'pluggy', category_name: null }));
function vtx(u, req) {
  const g = (k) => u.searchParams.get(k);
  let rows = g('review_status') === 'eq.pending' ? PEND : TX;
  const or = g('or'); if (or) { const t = (or.match(/ilike\.\*([^*]*)\*/) || [])[1].toLowerCase(); rows = rows.filter(r => (r.description + ' ' + (r.counterpart_name || '')).toLowerCase().includes(t)); }
  if (g('category_id')) rows = rows.filter(r => r.category_id === g('category_id').slice(3));
  const off = +(g('offset') || 0), lim = g('limit') ? +g('limit') : rows.length;
  let page = rows.slice(off, off + lim); if (g('select') === 'amount') page = page.map(r => ({ amount: r.amount }));
  const h = { 'access-control-expose-headers': 'content-range', 'access-control-allow-origin': '*', 'content-range': off + '-' + (off + page.length - 1) + '/' + ((req.headers()['prefer'] || '').includes('count=exact') ? rows.length : '*') };
  return { page, h };
}
(async () => {
  const b = await chromium.launch(); const results = []; const ok = (n, c, x) => results.push([c ? 'OK ' : 'FALHA', n, x || '']);
  async function page(vp, scheme) {
    const ctx = await b.newContext({ viewport: vp, serviceWorkers: 'block', colorScheme: scheme || 'light' }); const p = await ctx.newPage();
    const errs = []; p.on('pageerror', e => errs.push(e.message));
    await p.clock.setFixedTime(new Date('2026-11-12T15:00:00-04:00'));
    await p.route('https://cdn.jsdelivr.net/**', r => r.fulfill({ status: 200, contentType: 'application/javascript', body: SB }));
    await p.route('https://fonts.googleapis.com/**', r => r.abort());
    await p.route('**/auth/v1/**', r => r.fulfill({ status: 200, contentType: 'application/json', body: '{}' }));
    await p.route('**/rest/v1/**', r => {
      const req = r.request(); const u = new URL(req.url()); const t = u.pathname.split('/rest/v1/')[1]; reqs.push(t + '?' + u.searchParams.toString());
      if (t.startsWith('rpc/')) { if (t === 'rpc/set_transaction_category') rpcs.push(JSON.parse(req.postData())); return r.fulfill({ status: 200, contentType: 'application/json', body: 'null' }); }
      if (req.method() === 'HEAD') return r.fulfill({ status: 200, headers: { 'content-range': '0-5/6', 'access-control-expose-headers': 'content-range', 'access-control-allow-origin': '*' }, body: '' });
      if (t === 'v_tx') { const { page, h } = vtx(u, req); return r.fulfill({ status: 200, contentType: 'application/json', headers: h, body: JSON.stringify(page) }); }
      const rows = { household_members: [{ id: 'm1', role: 'owner', display_name: 'Hugo', auth_user_id: 'u1' }], categories: cats,
        accounts: [{ id: 'a1', name: 'Conta', subtype: 'CHECKING_ACCOUNT', number: '1', balance: 1000 }] }[t] || [];
      return r.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(rows) });
    });
    await p.addInitScript(() => { const exp = Math.floor(Date.now() / 1000) + 86400 * 365; localStorage.setItem('sb-hrsinekxrfiphlhpoewp-auth-token', JSON.stringify({ access_token: 'a.' + btoa(JSON.stringify({ sub: 'u1', exp })) + '.x', token_type: 'bearer', expires_at: exp, refresh_token: 'r', user: { id: 'u1', aud: 'authenticated' } })) });
    return { ctx, p, errs };
  }
  const idle = async (p) => { await p.waitForFunction(() => !document.body.classList.contains('loading'), null, { timeout: 8000 }); await p.waitForTimeout(150); };
  const nb = (s) => s.replace(/ /g, ' ');
  const exp = TX.reduce((a, r) => (r.amount > 0 ? a[0] += r.amount : a[1] += r.amount, a), [0, 0]);
  const brl = (v) => v.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' }).replace(/ /g, ' ');

  let { ctx, p, errs } = await page({ width: 390, height: 844 });
  await p.goto(APP + '#lancamentos?month=2026-11'); await idle(p);
  await p.screenshot({ path: OUT + '/f3-lancamentos.png' });
  const tot = await p.$$eval('#lxtot .card', es => es.map(e => e.textContent.replace(/ /g, ' ')));
  ok('totais separados: entradas, saídas, líquido', tot.length === 3 && tot[0].includes('R$ 50.000') && tot[1].includes('R$ 3.185') && tot[2].includes('R$ 46.815'), JSON.stringify(tot));
  ok('totais cobrem os 250, não só a página', nb(await p.locator('#lxtot p').textContent()).startsWith('250 lançamentos'));
  ok('primeira página: 100 itens', await p.locator('#lxlist .item').count() === 100);
  const dh = await p.$$eval('.dayh span:first-child', es => es.map(e => e.textContent));
  ok('agrupado por dia com Hoje/Ontem', dh[0] === 'Hoje · 12/11' && dh[1] === 'Ontem · 11/11' && dh[2] === 'Ter · 10/11', dh.slice(0, 3).join(' | '));
  const day12 = TX.filter(r => r.event_date === '2026-11-12').reduce((s, r) => s + r.amount, 0);
  ok('subtotal do dia', nb(await p.locator('.dayh').first().textContent()).includes(brl(day12)));
  ok('botão mostra quantos faltam', nb(await p.locator('#lxmore').textContent()) === 'Carregar mais 100 · faltam 150');
  await p.locator('#lxmore').click(); await p.waitForFunction(() => document.querySelectorAll('#lxlist .item').length === 200);
  ok('carregar mais: 200 itens, faltam 50', nb(await p.locator('#lxmore').textContent()) === 'Carregar mais 50 · faltam 50');
  ok('carregar mais pede offset 100', reqs.some(r => r.startsWith('v_tx?') && r.includes('offset=100') && r.includes('limit=100')));
  await p.locator('#lxmore').click(); await p.waitForFunction(() => document.querySelectorAll('#lxlist .item').length === 250);
  ok('fim da lista', (await p.locator('#lxlist').textContent()).includes('Fim da lista · 250 lançamentos'));
  ok('dia não se repete entre páginas', new Set(await p.$$eval('.dayh span:first-child', es => es.map(e => e.textContent))).size === await p.locator('.dayh').count());
  // voltar mantém o que já foi carregado
  await p.evaluate(() => scrollTo(0, 6000)); await p.waitForTimeout(80); const y0 = await p.evaluate(() => scrollY);
  await p.evaluate(() => { location.hash = 'inicio' }); await idle(p); await p.goBack(); await idle(p);
  ok('voltar: mantém os 250 carregados e a rolagem', await p.locator('#lxlist .item').count() === 250 && Math.abs((await p.evaluate(() => scrollY)) - y0) <= 2, 'y0=' + y0);
  // busca ao digitar
  await p.evaluate(() => scrollTo(0, 0)); reqs.length = 0; const navLen = await p.evaluate(() => history.length);
  await p.locator('#fs').pressSequentially('shell', { delay: 60 }); await p.waitForTimeout(500); await idle(p);
  const n = TX.filter(r => r.description.includes('SHELL')).length;
  ok('busca ao digitar filtra sem Enter', nb(await p.locator('#lxtot p').textContent()).startsWith(n + ' lançamentos') && await p.locator('#lxlist .item').count() === Math.min(100, n), n);
  ok('busca procura em descrição e estabelecimento', reqs.some(r => decodeURIComponent(r).includes('or=(description.ilike.*shell*,counterpart_name.ilike.*shell*)')));
  ok('busca com espera: 1 consulta para 5 letras', reqs.filter(r => r.startsWith('v_tx?') && r.includes('select=*')).length === 1, reqs.filter(r => r.startsWith('v_tx?')).length);
  ok('campo continua focado', await p.evaluate(() => document.activeElement && document.activeElement.id === 'fs'));
  ok('endereço guarda a busca sem empilhar histórico', (await p.evaluate(() => location.hash)).includes('search=shell') && await p.evaluate(() => history.length) === navLen);
  await p.evaluate(() => { location.hash = 'inicio' }); await idle(p); await p.goBack(); await idle(p);
  ok('voltar reabre a busca', (await p.locator('#fs').inputValue()) === 'shell' && (await p.evaluate(() => location.hash)).includes('search=shell'));
  await p.locator('#fs').fill(''); await p.waitForTimeout(500); await idle(p);
  ok('limpar a busca volta a tudo', nb(await p.locator('#lxtot p').textContent()).startsWith('250 lançamentos'));
  await p.locator('#fs').fill('a,b(c)'); await p.waitForTimeout(500); await idle(p);
  ok('caracteres especiais não quebram a busca', errs.length === 0 && reqs.some(r => decodeURIComponent(r.replace(/\+/g, ' ')).includes('ilike.*a b c*')));
  ok('sem erros de JS (Lançamentos)', errs.length === 0, errs.join(' | '));

  // Revisão em lote
  await p.goto(APP + '#revisao'); await idle(p);
  await p.screenshot({ path: OUT + '/f3-revisao.png', fullPage: true });
  const gn = await p.$$eval('.grp .row b', es => es.map(e => e.textContent));
  ok('agrupa por estabelecimento (acentos/maiúsculas/espaços)', JSON.stringify(gn) === JSON.stringify(['Padaria Pão Bom', 'UBER *TRIP', 'Fulano de Tal']), gn.join(' | '));
  ok('resumo: 6 lançamentos em 3 estabelecimentos', (await p.locator('.wrap > p.small').textContent()).includes('6 lançamentos sem categoria') && (await p.locator('.wrap > p.small').textContent()).includes('3 estabelecimentos'));
  ok('sugestão pré-selecionada quando o grupo concorda', await p.locator('#gc1').inputValue() === 'transporte' && await p.locator('#gc0').inputValue() === '');
  ok('criar regra vem marcado', await p.locator('#gr0').isChecked());
  ok('botão diz quantos', (await p.locator('#gb0').textContent()) === 'Classificar os 3');
  rpcs.length = 0; await p.locator('#gb0').click(); await p.waitForTimeout(300);
  ok('sem categoria: pede para escolher e não grava', rpcs.length === 0 && (await p.locator('.toast').textContent()).includes('Escolha a categoria'));
  await p.locator('#gc0').selectOption('padaria'); await p.locator('#gb0').click(); await idle(p);
  ok('lote: 3 gravações, regra só na primeira', rpcs.length === 3 && rpcs.every(x => x.p_category === 'padaria') && rpcs[0].p_create_rule === true && !rpcs[1].p_create_rule && !rpcs[2].p_create_rule && rpcs.map(x => x.p_tx).join() === 'p1,p2,p3', JSON.stringify(rpcs));
  ok('aviso: "3 lançamentos em Padaria · regra criada"', (await p.locator('.toast').textContent()).includes('3 lançamentos em Padaria · regra criada'));
  rpcs.length = 0; await p.locator('#gr2').uncheck(); await p.locator('#gc2').selectOption('alimentacao'); await p.locator('#gb2').click(); await idle(p);
  ok('regra desmarcada: não cria regra', rpcs.length === 1 && rpcs[0].p_create_rule === false);
  await p.locator('.grp').nth(1).locator('summary').click();
  await p.locator('.grp').nth(1).locator('.item').first().click(); await p.waitForTimeout(200);
  ok('um a um continua possível (abre a janela da categoria)', await p.locator('#sheet.on #cx').count() === 1);
  await p.keyboard.press('Escape');
  ok('sem erros de JS (Revisão)', errs.length === 0, errs.join(' | '));
  await ctx.close();

  ({ ctx, p, errs } = await page({ width: 1366, height: 900 }, 'dark'));
  await p.goto(APP + '#lancamentos?month=2026-11'); await idle(p); await p.screenshot({ path: OUT + '/f3-desk-escuro.png' });
  await p.goto(APP + '#revisao'); await idle(p); await p.screenshot({ path: OUT + '/f3-revisao-desk.png' });
  ok('sem erros de JS (notebook escuro)', errs.length === 0, errs.join(' | '));
  await ctx.close(); await b.close();
  for (const r of results) console.log(r.join('  '));
  console.log(results.filter(r => r[0] !== 'OK ').length ? 'RESULTADO: HÁ FALHAS' : 'RESULTADO: TUDO OK (' + results.length + ' verificações)');
})().catch(e => { console.error('ERRO NO TESTE', e); process.exit(1); });
