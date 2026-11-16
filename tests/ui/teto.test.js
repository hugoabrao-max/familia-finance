// Teste do teto da fatura do cartão (v0.23) com Supabase simulado e números reais de nov/26.
// Uso: node teto.test.js <url_app> <dir_saida>   (requer sb.mjs; ver README.md)
const { chromium } = require('playwright');
const fs = require('fs');
const APP = process.argv[2] || 'http://localhost:3999/';
const OUT = process.argv[3] || '.';
const SB = fs.readFileSync(__dirname + '/sb.mjs');
const reqs = [], writes = [];
let TETO = null;
const linha = (mes, sit, fecha, dias, p, v) => ({ mes, situacao: sit, fecha, vence: null, teto: TETO, comprometido: p, parcelas_lancadas: sit === 'aberta' ? p : 0, parcelas_a_lancar: sit === 'aberta' ? 0 : p, gasto_variavel: v, livre: TETO == null ? null : +(TETO - p - v).toFixed(2), dias_ate_fechar: dias });
const tetoRows = () => [linha('2026-11-01', 'aberta', '2026-11-27', 11, 14274.95, 19157.56), linha('2026-12-01', 'futura', '2026-12-29', 43, 9082.45, 0), linha('2027-01-01', 'futura', null, null, 2502.44, 0)];
const BILLS = [{ closing_date: '2026-11-27', due_date: '2026-12-06', competence_month: '2026-11-01', total_lancamentos: 33432.51, n_lancamentos: 134, status: 'aberta', source: 'pluggy_parcelas' },
  ...[['2026-10', 44773], ['2026-09', 57851], ['2026-08', 45498], ['2026-07', 34248], ['2026-06', 31614], ['2026-05', 33125]].map(([m, v]) => ({ closing_date: m + '-28', due_date: m + '-28', competence_month: m + '-01', total_lancamentos: v, paid_amount: v, n_lancamentos: 200, status: 'paga', source: 'pluggy_parcelas' }))];
function data(t, u) {
  const q = (k) => u.searchParams.get(k) || '';
  switch (t) {
    case 'household_members': return [{ id: 'm1', role: 'owner', display_name: 'Hugo', auth_user_id: 'u1' }];
    case 'categories': return [{ id: 'alimentacao', name: 'Alimentação', parent_id: null, sort: 0, kind: 'despesa' }];
    case 'accounts': return [{ id: 'a2', name: 'Unique', subtype: 'CREDIT_CARD', number: '5430', balance: -33432, credit_limit: 100000, available_credit_limit: 60000 }];
    case 'v_card_teto': { const r = tetoRows(); return q('situacao') === 'eq.aberta' ? r[0] : r; }
    case 'v_card_bills': return q('status') === 'eq.aberta' ? BILLS.slice(0, 1) : BILLS;
    case 'v_month_summary': return [{ month: '2026-11-01', receitas: 57000, despesas: -62672, resultado: -5672, pendentes: 0 }];
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
  await p.goto(APP + '#cartao'); await idle(p);
  ok('sem teto: convite para definir', (await p.locator('button', { hasText: 'Definir teto' }).count()) === 1);
  await p.locator('button', { hasText: 'Definir teto' }).click(); await p.waitForTimeout(150);
  const sh = nb(await p.locator('#sheetBody').textContent());
  ok('janela mostra a média das últimas faturas pagas (R$ 41.185)', sh.includes('Média das últimas faturas pagas: R$ 41.185'), sh);
  writes.length = 0; await p.fill('#tv', '40.000'); await p.locator('#sheetBody button', { hasText: 'Salvar' }).click(); TETO = 40000; await idle(p);
  ok('salva teto_fatura = 40000 em plan_settings', writes.length === 1 && writes[0].t === 'plan_settings' && writes[0].body.key === 'teto_fatura' && writes[0].body.value === 40000, JSON.stringify(writes));
  await p.goto(APP + '#cartao'); await idle(p);
  await p.screenshot({ path: OUT + '/teto-cartao.png', fullPage: true });
  const card = nb(await p.locator('.card.destaque').first().textContent());
  ok('livre = 40.000 − 14.275 − 19.158 = R$ 6.567', card.includes('R$ 6.567') && card.includes('livre para gastar'), card);
  ok('ritmo: cerca de R$ 597 por dia nos 11 dias', card.includes('cerca de R$ 597 por dia nos 11 dias'), card);
  const leg = nb(await p.locator('.tleg').textContent());
  ok('legenda: parcelas, gastos e teto', leg.includes('parcelas comprometidas R$ 14.275') && leg.includes('gastos do mês R$ 19.158') && leg.includes('teto R$ 40.000'), leg);
  const prox = nb(await p.locator('.panel', { hasText: 'Próximas faturas' }).textContent());
  ok('próximas: dez/26 livre R$ 30.918 (parcelas R$ 9.082)', prox.includes('dez/26') && prox.includes('parcelas R$ 9.082') && prox.includes('livre R$ 30.918'), prox);
  ok('barra com rótulo para leitor de tela', (await p.locator('.tbar[aria-label]').count()) === 1);
  await p.goto(APP + '#inicio'); await idle(p);
  ok('Início: fatura aberta mostra "livre R$ 6.567 do teto"', nb(await p.locator('.cards3 a.card[href="#cartao"]').textContent()).includes('livre R$ 6.567 do teto'));
  TETO = 30000; await p.reload(); await idle(p);
  ok('passou do teto: Início avisa em "Precisa de você"', nb(await p.locator('.need').textContent()).includes('Fatura do cartão passou do teto em R$ 3.433') && nb(await p.locator('.cards3 a.card[href="#cartao"]').textContent()).includes('passou R$ 3.433 do teto'));
  await p.goto(APP + '#cartao'); await idle(p);
  ok('Cartão: "passou do teto" em vez de livre', nb(await p.locator('.card.destaque').first().textContent()).includes('passou do teto'));
  writes.length = 0; await p.locator('.card.destaque a', { hasText: 'alterar' }).click(); await p.waitForTimeout(150);
  await p.locator('#sheetBody button', { hasText: 'Remover teto' }).click(); await idle(p);
  ok('remover teto grava valor vazio', writes.length === 1 && writes[0].body.value === null);
  ok('sem erros de JS', errs.length === 0, errs.join(' | '));
  await ctx.close(); await b.close();
  for (const r of results) console.log(r.join('  '));
  console.log(results.filter(r => r[0] !== 'OK ').length ? 'RESULTADO: HÁ FALHAS' : 'RESULTADO: TUDO OK (' + results.length + ' verificações)');
})().catch(e => { console.error('ERRO NO TESTE', e); process.exit(1); });
