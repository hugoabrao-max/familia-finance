// Teste da Fase 3 (Extrato — antes "Lançamentos" — por dia com totais e "carregar mais"; busca ao digitar; filtros rápidos; Revisão em lote) com Supabase simulado.
// Uso: node fase3.test.js <url_app> <dir_saida>   (requer sb.mjs; ver README.md)
const { chromium } = require('playwright');
const FORA = []; // chamadas que escaparam do simulado
const fs = require('fs');
const fontes = require('./fontes');
const APP = process.argv[2] || 'http://localhost:3999/';
const OUT = process.argv[3] || '.';
const SB = fs.readFileSync(__dirname + '/sb.mjs');
const reqs = [], rpcs = [];
const cats = [{ id: 'alimentacao', name: 'Alimentação', parent_id: null, sort: 0, kind: 'despesa' }, { id: 'padaria', name: 'Padaria', parent_id: 'alimentacao', sort: 1, kind: 'despesa' },
  { id: 'transporte', name: 'Transporte', parent_id: null, sort: 2, kind: 'despesa' }, { id: 'receitas', name: 'Receitas', parent_id: null, sort: 3, kind: 'receita' },
  { id: 'receitas_fixas', name: 'Receitas fixas', parent_id: 'receitas', sort: 4, kind: 'receita' }, { id: 'receita', name: 'Receita (ATMO)', parent_id: 'receitas_fixas', sort: 5, kind: 'receita' }];
// 250 lançamentos em nov/26: 2 por dia em média, do dia 12 para trás; 1 receita de 10.000 a cada 50
const TX = Array.from({ length: 250 }, (_, i) => { const d = 12 - Math.floor(i / 25); const inc = i % 50 === 0;
  return { group_id: inc ? 'receitas_fixas' : 'alimentacao', id: 'x' + String(1000 - i), event_date: '2026-11-' + String(d).padStart(2, '0'), amount: inc ? 10000 : -(10 + (i % 7)), description: i % 3 ? 'PADARIA PAO BOM' : 'POSTO SHELL',
    counterpart_name: i % 3 ? 'Padaria Pão Bom' : null, category_id: inc ? 'receita' : i === 4 ? null : 'alimentacao', category_name: inc ? 'Receita' : i === 4 ? null : 'Alimentação', review_status: i === 4 ? 'pending' : 'reviewed',
    account_name: i % 2 ? 'Cartão' : 'Conta', account_subtype: i % 2 ? 'CREDIT_CARD' : 'CHECKING_ACCOUNT', holder_name: i % 2 ? (i % 4 === 1 ? 'Hugo' : 'Juliana') : null, source: 'pluggy' }; });
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
  const or = g('or'); const busca = or && or.match(/ilike\.\*([^*]*)\*/); if (busca) { const t = busca[1].toLowerCase(); rows = rows.filter(r => (r.description + ' ' + (r.counterpart_name || '')).toLowerCase().includes(t)); }
  const ci = g('category_id'); if (ci && ci.startsWith('eq.')) rows = rows.filter(r => r.category_id === ci.slice(3));
  if (ci && ci.startsWith('in.')) { const ids = ci.slice(4, -1).split(','); rows = rows.filter(r => ids.includes(r.category_id)); }
  if (g('group_id')) rows = rows.filter(r => r.group_id === g('group_id').slice(3));
  const am = g('amount'); if (am === 'lt.0') rows = rows.filter(r => r.amount < 0); if (am === 'gt.0') rows = rows.filter(r => r.amount > 0);
  const sub = g('account_subtype'); if (sub === 'eq.CREDIT_CARD') rows = rows.filter(r => r.account_subtype === 'CREDIT_CARD'); if (sub === 'neq.CREDIT_CARD') rows = rows.filter(r => r.account_subtype !== 'CREDIT_CARD');
  const off = +(g('offset') || 0), lim = g('limit') ? +g('limit') : rows.length;
  let page = rows.slice(off, off + lim); if (g('select') === 'amount') page = page.map(r => ({ amount: r.amount }));
  const h = { 'access-control-expose-headers': 'content-range', 'access-control-allow-origin': '*', 'content-range': off + '-' + (off + page.length - 1) + '/' + ((req.headers()['prefer'] || '').includes('count=exact') ? rows.length : '*') };
  return { page, h };
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
      const req = r.request(); const u = new URL(req.url()); const t = u.pathname.split('/rest/v1/')[1]; reqs.push(t + '?' + u.searchParams.toString());
      if (t.startsWith('rpc/')) { if (t === 'rpc/set_transaction_category') rpcs.push(JSON.parse(req.postData())); return r.fulfill({ status: 200, contentType: 'application/json', body: 'null' }); }
      if (req.method() === 'HEAD') return r.fulfill({ status: 200, headers: { 'content-range': '0-5/6', 'access-control-expose-headers': 'content-range', 'access-control-allow-origin': '*' }, body: '' });
      if (t === 'v_tx') { const { page, h } = vtx(u, req); return r.fulfill({ status: 200, contentType: 'application/json', headers: h, body: JSON.stringify(page) }); }
      const rows = { household_members: [{ id: 'm1', role: 'owner', display_name: 'Hugo', auth_user_id: 'u1' }], categories: cats,
        accounts: [{ id: 'a1', name: 'Conta', subtype: 'CHECKING_ACCOUNT', number: '1', balance: 1000 }] }[t] || [];
      return r.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(rows) });
    });
    if (dsf) await fontes(p);
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
  ok('título "Extrato" e aba "Extrato"', (await p.locator('h1').textContent()) === 'Extrato' && (await p.locator('.tabs a[href="#lancamentos"]').textContent()) === 'Extrato');
  const tot = await p.$$eval('#lxtot .tot > div', es => es.map(e => e.textContent));
  ok('totais em linha: entrou, saiu, ficou', JSON.stringify(tot) === JSON.stringify(['Entrou+50.000', 'Saiu3.185', 'Ficou46.815']), JSON.stringify(tot));
  ok('totais cobrem os 250, não só a página', nb(await p.locator('#lxtot p').textContent()).startsWith('250 lançamentos'));
  ok('explicação das transferências virou "?"', !(await p.locator('#app').textContent()).includes('transferências entre contas') && await p.locator('#lxtot .ajuda').count() === 1);
  ok('primeira página: 100 itens', await p.locator('#lxlist .item').count() === 100);
  const dh = await p.$$eval('.dayh span:first-child', es => es.map(e => e.textContent));
  ok('agrupado por dia com Hoje/Ontem', dh[0] === 'Hoje, 12 de novembro' && dh[1] === 'Ontem, 11 de novembro' && dh[2] === 'ter, 10 de novembro', dh.slice(0, 3).join(' | '));
  const day12 = TX.filter(r => r.event_date === '2026-11-12').reduce((s, r) => s + r.amount, 0), day11 = TX.filter(r => r.event_date === '2026-11-11').reduce((s, r) => s + r.amount, 0);
  const sub = await p.$$eval('.dayh span:last-child', es => es.map(e => e.textContent));
  ok('subtotal do dia (sem "R$"; negativo com "−")', sub[0] === Math.round(day12).toLocaleString('pt-BR') && sub[1] === '−' + Math.round(-day11).toLocaleString('pt-BR'), sub.slice(0, 2).join(' | ') + ' esperado ' + day12 + ' / ' + day11);
  const r0 = await p.$$eval('#lxlist .item', es => es.slice(0, 6).map(e => [e.querySelector('.av').textContent, e.querySelector('.av').style.background, e.querySelector('.t').textContent, e.querySelector('.s').textContent, e.querySelector('.a').textContent, e.querySelector('.a').className]));
  ok('entrada: verde com "+" e sem "R$"', r0[0][4] === '+10.000,00' && r0[0][5].includes('pos'), JSON.stringify(r0[0]));
  ok('gasto: sem sinal e sem "R$"', r0[1][4] === '11,00' && !r0[1][5].includes('pos'), JSON.stringify(r0[1]));
  ok('linha sem a data repetida', !r0.some(r => r[3].includes('12/11')));
  ok('bolinha com a inicial e cor do grupo (estável)', r0[1][0] === 'P' && r0[2][0] === 'P' && r0[1][1] === r0[2][1] && r0[0][1] !== r0[1][1], JSON.stringify(r0.map(r => r[0] + ' ' + r[1])));
  ok('inicial de quem gastou num círculo (H/J)', r0[1][3] === 'AlimentaçãoH' && r0[3][3] === 'AlimentaçãoJ' && await p.locator('#lxlist .item').nth(1).locator('abbr.who').getAttribute('title') === 'Hugo', JSON.stringify(r0.map(r => r[3])));
  ok('pendente sem categoria: "?" cinza e convite em âmbar', r0[4][0] === '?' && r0[4][3] === 'sem categoria · toque para classificar' && await p.locator('#lxlist .item').nth(4).locator('.pend').count() === 1, JSON.stringify(r0[4]));
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
  // filtro de categoria pega a árvore inteira (Receitas › Receitas fixas › Receita)
  await p.goto(APP + '#lancamentos?month=2026-11'); await idle(p); reqs.length = 0;
  ok('"+ filtro" começa recolhido', await p.locator('#fx').isHidden() && await p.locator('#fmore').getAttribute('aria-expanded') === 'false');
  await p.locator('#fmore').click(); ok('"+ filtro" abre categoria e conta', await p.locator('#fg').isVisible() && await p.locator('#fa').isVisible() && await p.locator('#fmore').getAttribute('aria-expanded') === 'true');
  await p.selectOption('#fg', 'receitas'); await idle(p);
  ok('filtro Receitas consulta a árvore (3 níveis)', reqs.some(r => decodeURIComponent(r).includes('category_id=in.(receitas,receitas_fixas,receita)')) && (await p.evaluate(() => location.hash)).includes('tree=receitas'), reqs.filter(r => r.startsWith('v_tx')).map(decodeURIComponent).join(' || ').slice(0, 300));
  ok('filtro Receitas mostra as 5 receitas', (await p.locator('#lxlist .item').count()) === 5 && (await p.locator('#lxtot .tot > div').first().textContent()) === 'Entrou+50.000' && (await p.locator('#lxtot .tot > div').nth(1).textContent()) === 'Saiu0');
  ok('menu continua mostrando Receitas (filtro aberto)', await p.$eval('#fg', s => s.value) === 'receitas' && await p.locator('#fg').isVisible());
  // filtros rápidos (chips)
  await p.goto(APP + '#lancamentos?month=2026-11'); await idle(p);
  ok('chip "Tudo" marcado sem filtro rápido', await p.locator('.chip.on').count() === 1 && (await p.locator('.chip.on').textContent()) === 'Tudo' && await p.locator('.chip.on').getAttribute('aria-pressed') === 'true');
  reqs.length = 0; await p.locator('.chip', { hasText: 'Receitas' }).click(); await idle(p);
  ok('chip Receitas: só entradas (amount > 0)', reqs.some(r => r.startsWith('v_tx?') && r.includes('amount=gt.0')) && await p.locator('#lxlist .item').count() === 5 && (await p.evaluate(() => location.hash)).includes('kind=in'));
  await p.locator('.chip', { hasText: 'Cartão' }).click(); await idle(p);
  ok('chips combinam: Receitas + Cartão', (await p.evaluate(() => location.hash)).includes('kind=in') && (await p.evaluate(() => location.hash)).includes('via=cartao') && (await p.locator('#lxlist').textContent()).includes('Nada encontrado') && nb(await p.locator('#lxtot p').textContent()).startsWith('0 lançamentos') && await p.locator('.chip.on').count() === 2);
  await p.locator('.chip', { hasText: 'Gastos' }).click(); await idle(p);
  const nOutCard = TX.filter(r => r.amount < 0 && r.account_subtype === 'CREDIT_CARD').length;
  ok('chip Gastos troca Receitas; Cartão continua', nb(await p.locator('#lxtot p').textContent()).startsWith(nOutCard + ' lançamentos') && reqs.some(r => r.includes('amount=lt.0') && r.includes('account_subtype=eq.CREDIT_CARD')), nOutCard);
  await p.locator('.chip', { hasText: 'Conta' }).click(); await idle(p);
  ok('chip Conta: account_subtype ≠ cartão', reqs.some(r => r.includes('account_subtype=neq.CREDIT_CARD')) && !(await p.evaluate(() => location.hash)).includes('via=cartao'));
  await p.locator('.chip', { hasText: 'Tudo' }).click(); await idle(p);
  ok('chip Tudo limpa os filtros rápidos', nb(await p.locator('#lxtot p').textContent()).startsWith('250 lançamentos') && !(await p.evaluate(() => location.hash)).includes('kind='));
  await p.goto(APP + '#lancamentos?month=2026-11&kind=<x>&via=1'); await idle(p);
  ok('filtro rápido inválido no endereço é ignorado', await p.locator('#lxlist .item').count() === 100 && (await p.locator('.chip.on').textContent()) === 'Tudo');
  reqs.length = 0; await p.locator('button[aria-label="Mês anterior"]').click(); await idle(p);
  ok('"Mês anterior" leva a outubro mantendo a tela', (await p.evaluate(() => location.hash)).includes('month=2026-10') && await p.locator('#mp').inputValue() === '2026-10' && reqs.some(r => r.startsWith('v_tx?') && r.includes('month=eq.2026-10-01')));
  await p.goto(APP + '#lancamentos?month=2026-11&group=receitas_fixas'); await idle(p);
  ok('link do Início (grupo) mostra o nome e mantém o critério', (await p.locator('.pill', { hasText: 'Receitas fixas' }).count()) === 1 && (await p.locator('#lxlist .item').count()) === 5 && await p.$eval('#fg', s => s.value) === 'receitas');
  ok('sem erros de JS (Extrato)', errs.length === 0, errs.join(' | '));

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

  for (const sc of ['light', 'dark']) { // capturas do redesenho (390×844, escala 2)
    ({ ctx, p, errs } = await page({ width: 390, height: 844 }, sc, 2));
    await p.goto(APP + '#lancamentos?month=2026-11'); await idle(p); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(200);
    await p.screenshot({ path: OUT + '/redesenho-extrato-' + (sc === 'light' ? 'claro' : 'escuro') + '.png' });
    ok('sem erros de JS (captura ' + sc + ')', errs.length === 0, errs.join(' | ')); await ctx.close();
  }
  ({ ctx, p, errs } = await page({ width: 1366, height: 900 }, 'dark'));
  await p.goto(APP + '#lancamentos?month=2026-11'); await idle(p); await p.screenshot({ path: OUT + '/f3-desk-escuro.png' });
  await p.goto(APP + '#revisao'); await idle(p); await p.screenshot({ path: OUT + '/f3-revisao-desk.png' });
  ok('sem erros de JS (notebook escuro)', errs.length === 0, errs.join(' | '));
  await ctx.close(); await b.close();
  for (const r of results) console.log(r.join('  '));
  { const okF = FORA.length === 0; results.push([okF ? 'OK ' : 'FALHA', 'nenhuma chamada saiu do simulado', FORA.slice(0, 3).join(' ')]); if (!okF) console.log('FALHA', 'nenhuma chamada saiu do simulado', FORA.slice(0, 3).join(' ')); }
  console.log(results.filter(r => r[0] !== 'OK ').length ? 'RESULTADO: HÁ FALHAS' : 'RESULTADO: TUDO OK (' + results.length + ' verificações)');
  process.exitCode = results.some(r => r[0] !== 'OK ') ? 1 : 0;
})().catch(e => { console.error('ERRO NO TESTE', e); process.exit(1); });
