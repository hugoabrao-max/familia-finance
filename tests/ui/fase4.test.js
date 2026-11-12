// Teste da Fase 4 (Plano em 4 cards; Orçamento com "só este mês"/"deste mês em diante"; Contas fixas com financiamentos; Reservas) com Supabase simulado.
// Uso: node fase4.test.js <url_app> <dir_saida>   (requer sb.mjs; ver README.md)
const { chromium } = require('playwright');
const fs = require('fs');
const APP = process.argv[2] || 'http://localhost:3999/';
const OUT = process.argv[3] || '.';
const SB = fs.readFileSync(__dirname + '/sb.mjs');
const reqs = [], writes = [];
const cats = [{ id: 'alimentacao', name: 'Alimentação', parent_id: null, sort: 0, kind: 'despesa' }, { id: 'lazer', name: 'Lazer', parent_id: null, sort: 1, kind: 'despesa' }, { id: 'moradia', name: 'Moradia', parent_id: null, sort: 2, kind: 'despesa' }];
const BUD = [{ group_id: 'alimentacao', group_name: 'Alimentação', orcado: 2000, gasto: 1200, saldo: 800, source: 'hugo' }, { group_id: 'lazer', group_name: 'Lazer', orcado: 1000, gasto: 1300, saldo: -300, source: 'proposta' }, { group_id: 'moradia', group_name: 'Moradia', orcado: 5000, gasto: 3000, saldo: 2000, source: 'proposta' }];
const MC = [{ month: '2026-11-01', group_id: 'moradia', parcelas_cartao: 0, n_parcelas: 0, compromissos_pendentes: 1500, nomes: 'Condomínio' }, { month: '2026-11-01', group_id: 'alimentacao', parcelas_cartao: 300, n_parcelas: 2, compromissos_pendentes: 0, nomes: '' }];
const FE = [{ id: 'f1', name: 'Condomínio', valor_atual: 1500, pago_mes: 0, is_active: true, end_month: null, source: 'hugo', group_name: 'Moradia', category_name: 'Condomínio', channel: 'conta', commitment_id: 'c2' },
  { id: 'f2', name: 'Internet', valor_atual: 200, pago_mes: 200, is_active: true, end_month: null, source: 'sugerido', group_name: 'Moradia', category_name: 'Internet', channel: 'conta' },
  { id: 'f3', name: 'Escola', valor_atual: 3000, pago_mes: 3000, is_active: true, end_month: null, source: 'sugerido', group_name: 'Educação', category_name: 'Escola', channel: 'conta' }];
const COM = [{ id: 'c1', name: 'Financiamento casa', kind: 'financiamento', monthly_amount: 4399.12, installments_paid: 62, installments_total: 420, end_date: '2056-08-12', outstanding_balance: 500000 },
  { id: 'c2', name: 'Condomínio', kind: 'fixo', monthly_amount: 1500, end_date: null }];
function data(t, u) {
  const q = (k) => u.searchParams.get(k) || '';
  switch (t) {
    case 'household_members': return [{ id: 'm1', role: 'owner', display_name: 'Hugo', auth_user_id: 'u1' }];
    case 'categories': return cats;
    case 'accounts': return [{ id: 'a1', name: 'Conta', subtype: 'CHECKING_ACCOUNT', number: '1', balance: 1000 }];
    case 'v_budget_month': return BUD.map(b => ({ ...b, month: q('month').slice(3) }));
    case 'v_month_commitments': return q('month') === 'eq.2026-11-01' ? MC : [];
    case 'v_card_future_installments': return [{ competence_month: '2026-12-01', valor: 800 }, { competence_month: '2027-01-01', valor: 400 }];
    case 'v_net_worth': return { conta_corrente: 1000, poupanca: 200, investimentos: 5000, bens: 900000, cartao_utilizado: 30000, financiamentos_saldo: 600000, patrimonio_liquido: 276200, financiamentos_sem_saldo: 1 };
    case 'v_goals': return [{ id: 'g1', name: 'Viagem', status: 'ativa', pct: 40, progresso: 4000, target_amount: 10000, target_date: '2027-07-01', monthly_contribution: 500 }];
    case 'v_investments_latest': return [];
    case 'plan_settings': return { key: 'sobra_meta', value: 5000 };
    case 'v_sim_base': return { receita_mensal: 30000 };
    case 'v_fixed_expenses': return FE;
    case 'commitments': return COM;
    case 'budgets': return q('month') === 'eq.1900-01-01' ? { amount: 900, source: 'proposta' } : q('month') === 'eq.2026-11-01' ? { amount: 1000, source: 'proposta' } : null;
    default: return [];
  }
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
      const req = r.request(); const u = new URL(req.url()); const t = u.pathname.split('/rest/v1/')[1]; const m = req.method(); reqs.push(m + ' ' + t + '?' + u.searchParams.toString());
      const cors = { 'access-control-expose-headers': 'content-range', 'access-control-allow-origin': '*' };
      if (t.startsWith('rpc/')) return r.fulfill({ status: 200, contentType: 'application/json', body: 'null' });
      if (m === 'POST' || m === 'PATCH' || m === 'DELETE') { writes.push({ m, t, q: u.searchParams.toString(), prefer: req.headers()['prefer'] || '', body: req.postData() ? JSON.parse(req.postData()) : null }); return r.fulfill({ status: 201, headers: cors, contentType: 'application/json', body: '[]' }); }
      if (m === 'HEAD') return r.fulfill({ status: 200, headers: { ...cors, 'content-range': '0-2/3' }, body: '' });
      const rows = data(t, u); const single = (req.headers()['accept'] || '').includes('vnd.pgrst.object');
      if (single && Array.isArray(rows)) return r.fulfill({ status: 200, headers: cors, contentType: 'application/json', body: JSON.stringify(rows[0] ?? null) });
      if (!single && rows && !Array.isArray(rows)) return r.fulfill({ status: 200, headers: cors, contentType: 'application/json', body: JSON.stringify([rows]) });
      return r.fulfill({ status: 200, headers: cors, contentType: 'application/json', body: JSON.stringify(rows) });
    });
    await p.addInitScript(() => { const exp = Math.floor(Date.now() / 1000) + 86400 * 365; localStorage.setItem('sb-hrsinekxrfiphlhpoewp-auth-token', JSON.stringify({ access_token: 'a.' + btoa(JSON.stringify({ sub: 'u1', exp })) + '.x', token_type: 'bearer', expires_at: exp, refresh_token: 'r', user: { id: 'u1', aud: 'authenticated' } })) });
    return { ctx, p, errs };
  }
  const idle = async (p) => { await p.waitForFunction(() => !document.body.classList.contains('loading'), null, { timeout: 8000 }); await p.waitForTimeout(150); };
  const nb = (s) => (s || '').replace(/ /g, ' ');

  let { ctx, p, errs } = await page({ width: 390, height: 844 });
  await p.goto(APP + '#plano'); await idle(p);
  await p.screenshot({ path: OUT + '/f4-plano.png', fullPage: true });
  const cards = await p.$$eval('.cards2 a.card', es => es.map(e => [e.getAttribute('href'), e.textContent.replace(/ /g, ' ')]));
  ok('Plano: 4 cards na ordem', JSON.stringify(cards.map(c => c[0])) === JSON.stringify(['#orcamento?month=2026-11', '#meta', '#fixas', '#simular']), cards.map(c => c[0]).join(' '));
  // restam = orçado 8000 − gasto 5500 − fixas pendentes 1500 = 1000
  ok('Orçamento: "restam R$ 1.000" e gasto de orçado', cards[0][1].includes('R$ 1.000restam · ') && cards[0][1].includes('gasto R$ 5.500 de R$ 8.000') && cards[0][1].includes('R$ 1.800 comprometido'), cards[0][1]);
  ok('Meta de sobra: meta e o que o orçamento deixa', cards[1][1].includes('R$ 5.000/mês') && cards[1][1].includes('deixa R$ 22.000'), cards[1][1]);
  ok('Contas fixas: total, a pagar e sugeridas', cards[2][1].includes('R$ 4.700/mês') && cards[2][1].includes('a pagar em nov/26: R$ 1.500') && cards[2][1].includes('2 para conferir'), cards[2][1]);
  ok('Simular: cenários salvos', cards[3][1].includes('3 cenários salvos'), cards[3][1]);
  ok('Reservas separadas, com "+ Nova reserva"', (await p.locator('h2', { hasText: 'Reservas' }).count()) === 1 && (await p.locator('text=+ Nova reserva').count()) === 1 && (await p.locator('text=guardar R$ 500/mês').count()) === 1);
  ok('sem "Compromissos mensais" no Plano', (await p.locator('text=Compromissos mensais').count()) === 0);
  ok('Patrimônio discreto (fechado)', !(await p.locator('details.pat').evaluate(e => e.open)) && nb(await p.locator('details.pat summary').textContent()).includes('R$ 276.200'));
  await p.locator('details.pat summary').click(); ok('Patrimônio abre o detalhe', (await p.locator('details.pat', { hasText: 'Imóveis' }).isVisible()));
  await p.locator('text=+ Nova reserva').click(); await p.waitForTimeout(150);
  ok('nova reserva: janela com "Quanto guardar por mês"', (await p.locator('#sheetBody', { hasText: 'Nova reserva' }).count()) === 1 && (await p.locator('#sheetBody', { hasText: 'Quanto guardar por mês' }).count()) === 1);
  await p.keyboard.press('Escape');

  // Orçamento
  await p.evaluate(() => scrollTo(0, 0)); await p.locator('.cards2 a.card').first().click(); await idle(p);
  await p.screenshot({ path: OUT + '/f4-orcamento.png', fullPage: true });
  ok('Orçamento abre com "‹ Plano"', (await p.locator('h1').first().textContent()).trim() === 'Orçamento' && (await p.locator('a.crumb').textContent()).includes('Plano'));
  const rs = await p.$$eval('.list .item .a', es => es.map(e => e.textContent.replace(/ /g, ' ')));
  ok('linhas dizem "restam"/"passou" (nada de "+R$")', JSON.stringify(rs.slice(0, 3)) === JSON.stringify(['restam R$ 500', 'restam R$ 800', 'passou R$ 300']) && !rs.slice(0, 3).some(x => x.includes('+')), rs.join(' | '));
  ok('"Como é calculado" recolhido', (await p.locator('details', { hasText: 'Como é calculado' }).count()) === 1);
  ok('parcelas futuras levam ao mês', await p.locator('a.item[href="#orcamento?month=2026-12"]').count() === 1);
  await p.locator('.list .item', { hasText: 'Lazer' }).click(); await p.waitForTimeout(150);
  const sh = nb(await p.locator('#sheetBody').textContent());
  ok('editar: "Só em nov/26" e "De nov/26 em diante"', (await p.locator('#sheetBody button', { hasText: 'Só em nov/26' }).count()) === 1 && (await p.locator('#sheetBody button', { hasText: 'De nov/26 em diante' }).count()) === 1);
  ok('editar: explica o efeito (13 meses, nov/26 a nov/27)', sh.includes('grava 13 meses (nov/26 a nov/27)') && sh.includes('anteriores continuam como estão'), sh);
  writes.length = 0; await p.fill('#bv', '1.200'); await p.locator('#sheetBody button', { hasText: 'Só em nov/26' }).click(); await idle(p);
  const w1 = writes.filter(w => w.t === 'budgets');
  ok('só este mês: grava 1 linha de nov/26', w1.length === 1 && JSON.stringify(w1[0].body) .includes('"month":"2026-11-01"') && w1[0].body.amount === 1200 && w1[0].body.group_id === 'lazer', JSON.stringify(w1));
  ok('só este mês: aviso com Desfazer', nb(await p.locator('#toast').textContent()).includes('Lazer em nov/26: R$ 1.200') && await p.locator('#toast button', { hasText: 'Desfazer' }).isVisible());
  writes.length = 0; await p.locator('#toast button', { hasText: 'Desfazer' }).click(); await idle(p);
  ok('Desfazer devolve o valor anterior (1.000, proposta)', writes.length === 1 && writes[0].body.amount === 1000 && writes[0].body.source === 'proposta', JSON.stringify(writes));
  await p.locator('.list .item', { hasText: 'Lazer' }).click(); await p.waitForTimeout(150);
  writes.length = 0; await p.fill('#bv', '1500'); await p.locator('#sheetBody button', { hasText: 'De nov/26 em diante' }).click(); await idle(p);
  const fr = writes[0], fw = writes[1];
  ok('em diante: congela os 12 meses anteriores com o valor antigo, sem sobrescrever', writes.length === 2 && fr.body.length === 12 && fr.body[0].month === '2025-11-01' && fr.body[11].month === '2026-10-01' && fr.body.every(x => x.amount === 900 && x.source === 'proposta') && fr.prefer.includes('ignore-duplicates'), JSON.stringify(fr && [fr.body.length, fr.prefer]));
  ok('em diante: grava nov/26 a nov/27 e o padrão', fw.body.length === 14 && fw.body[0].month === '2026-11-01' && fw.body[12].month === '2027-11-01' && fw.body[13].month === '1900-01-01' && fw.body.every(x => x.amount === 1500 && x.group_id === 'lazer') && fw.prefer.includes('merge-duplicates'), JSON.stringify(fw && [fw.body.length, fw.prefer]));
  await p.locator('a.crumb').click(); await idle(p);
  ok('"‹ Plano" volta ao Plano', (await p.locator('h1').first().textContent()).trim() === 'Plano');

  // Contas fixas
  await p.goto(APP + '#fixas'); await idle(p);
  await p.screenshot({ path: OUT + '/f4-fixas.png', fullPage: true });
  ok('Contas fixas: título e "‹ Plano"', (await p.locator('h1').first().textContent()).trim() === 'Contas fixas' && (await p.locator('a.crumb').count()) === 1);
  const fin = await p.$$eval('h2:has-text("Financiamentos") + p + .list .item', es => es.map(e => e.textContent));
  ok('financiamentos juntos das contas fixas', fin.length === 2 && fin[0].includes('parcela 62 de 420') && fin[0].includes('fora das contas fixas') && fin[1].includes('na lista acima'), fin.join(' | '));
  await p.locator('h2:has-text("Financiamentos") + p + .list .item').first().click(); await p.waitForTimeout(150);
  ok('financiamento editável (saldo devedor)', await p.locator('#sheetBody #co').count() === 1);
  await p.keyboard.press('Escape');
  ok('sem erros de JS (celular)', errs.length === 0, errs.join(' | '));
  await ctx.close();

  ({ ctx, p, errs } = await page({ width: 1366, height: 900 }, 'dark'));
  await p.goto(APP + '#plano'); await idle(p); await p.screenshot({ path: OUT + '/f4-plano-desk-escuro.png' });
  await p.goto(APP + '#orcamento?month=2026-12'); await idle(p);
  ok('notebook: Orçamento por link direto (mês futuro)', (await p.locator('h1').first().textContent()).trim() === 'Orçamento' && await p.$eval('#mp', s => s.value) === '2026-12');
  ok('aba Plano destacada no Orçamento', (await p.locator('.tabs a.on').getAttribute('href')) === '#plano');
  ok('sem erros de JS (notebook)', errs.length === 0, errs.join(' | '));
  await ctx.close(); await b.close();
  for (const r of results) console.log(r.join('  '));
  console.log(results.filter(r => r[0] !== 'OK ').length ? 'RESULTADO: HÁ FALHAS' : 'RESULTADO: TUDO OK (' + results.length + ' verificações)');
})().catch(e => { console.error('ERRO NO TESTE', e); process.exit(1); });
