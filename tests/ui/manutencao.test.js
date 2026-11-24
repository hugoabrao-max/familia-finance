// Teste da manutenção v0.25.0: Meta não guarda números de uma consulta que falhou; total de Lançamentos com mais de
// 1.000 lançamentos soma tudo (páginas em paralelo). Supabase simulado; nada sai para fora.
// Uso: node manutencao.test.js <url_app> <dir_saida>   (requer sb.mjs; ver README.md). Sai com código 1 se algo falhar.
const { chromium } = require('playwright');
const fs = require('fs');
const APP = process.argv[2] || 'http://localhost:3999/';
const SB = fs.readFileSync(__dirname + '/sb.mjs');
const FORA = [];
let FALHA_META = true;
const cats = [{ id: 'alimentacao', name: 'Alimentação', parent_id: null, sort: 0, kind: 'despesa' }, { id: 'lazer', name: 'Lazer', parent_id: null, sort: 1, kind: 'despesa' }];
const N = 2500; const TX = Array.from({ length: N }, (_, i) => ({ id: 't' + i, event_date: '2026-11-10', amount: i % 5 === 0 ? 100 : -10, description: 'X' + i, category_id: 'alimentacao', category_name: 'Alimentação', review_status: 'auto', account_name: 'Conta', source: 'pluggy', month: '2026-11-01' }));
const ENT = TX.filter(t => t.amount > 0).reduce((s, t) => s + t.amount, 0), SAI = TX.filter(t => t.amount < 0).reduce((s, t) => s + t.amount, 0);
function data(t, u) {
  switch (t) {
    case 'categories': return cats;
    case 'accounts': return [{ id: 'a1', name: 'Conta', subtype: 'CHECKING_ACCOUNT', number: '1', balance: 1000 }];
    case 'household_members': return [{ id: 'm1', role: 'owner', display_name: 'Hugo', auth_user_id: 'u1' }];
    case 'v_sim_base': return { receita_mensal: 30000 };
    case 'v_meta_base': return [{ group_id: 'lazer', nome: 'Lazer', variavel_mediana: 1234, variavel_por_mes: {} }];
    case 'plan_settings': return { key: 'sobra_meta', value: 5000 };
    default: return [];
  }
}
(async () => {
  const b = await chromium.launch(); const results = []; const ok = (n, c, x) => results.push([c ? 'OK ' : 'FALHA', n, x || '']);
  const ctx = await b.newContext({ viewport: { width: 1280, height: 900 }, serviceWorkers: 'block' }); const p = await ctx.newPage();
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  await p.clock.setFixedTime(new Date('2026-11-12T15:00:00-04:00'));
  await p.route(u => !u.href.startsWith(APP), r => { const h = new URL(r.request().url()).hostname; if (!/fonts\.(googleapis|gstatic)\.com$/.test(h)) FORA.push(r.request().url()); return r.abort(); });
  await p.route('https://cdn.jsdelivr.net/**', r => r.fulfill({ status: 200, contentType: 'application/javascript', body: SB }));
  await p.route('**/auth/v1/**', r => r.fulfill({ status: 200, contentType: 'application/json', body: '{}' }));
  let paginas = 0;
  await p.route('**/rest/v1/**', r => {
    const req = r.request(); const u = new URL(req.url()); const t = u.pathname.split('/rest/v1/')[1]; const m = req.method();
    const cors = { 'access-control-expose-headers': 'content-range', 'access-control-allow-origin': '*' };
    if (t.startsWith('rpc/')) return r.fulfill({ status: 200, contentType: 'application/json', body: 'null' });
    if (m === 'HEAD') return r.fulfill({ status: 200, headers: { ...cors, 'content-range': '0-0/0' }, body: '' });
    if (m !== 'GET') return r.fulfill({ status: 201, headers: cors, contentType: 'application/json', body: '[]' });
    if (t === 'v_meta_base' && FALHA_META) return r.fulfill({ status: 500, headers: cors, contentType: 'application/json', body: '{"message":"falha simulada"}' });
    if (t === 'v_tx' && u.searchParams.get('select') === 'amount') {
      paginas++; const off = Number(u.searchParams.get('offset') || 0), lim = Number(u.searchParams.get('limit') || 1000);
      return r.fulfill({ status: 200, headers: cors, contentType: 'application/json', body: JSON.stringify(TX.slice(off, off + lim).map(x => ({ amount: x.amount }))) });
    }
    if (t === 'v_tx') return r.fulfill({ status: 200, headers: { ...cors, 'content-range': '0-99/' + N }, contentType: 'application/json', body: JSON.stringify(TX.slice(0, 100)) });
    const rows = data(t, u); const single = (req.headers()['accept'] || '').includes('vnd.pgrst.object');
    if (single && Array.isArray(rows)) return r.fulfill({ status: 200, headers: cors, contentType: 'application/json', body: JSON.stringify(rows[0] ?? null) });
    if (!single && rows && !Array.isArray(rows)) return r.fulfill({ status: 200, headers: cors, contentType: 'application/json', body: JSON.stringify([rows]) });
    return r.fulfill({ status: 200, headers: cors, contentType: 'application/json', body: JSON.stringify(rows) });
  });
  await p.addInitScript(() => { const exp = Math.floor(Date.now() / 1000) + 86400 * 365; localStorage.setItem('sb-hrsinekxrfiphlhpoewp-auth-token', JSON.stringify({ access_token: 'a.' + btoa(JSON.stringify({ sub: 'u1', exp })) + '.x', token_type: 'bearer', expires_at: exp, refresh_token: 'r', user: { id: 'u1', aud: 'authenticated' } })) });
  const idle = async () => { await p.waitForFunction(() => !document.body.classList.contains('loading'), null, { timeout: 8000 }).catch(() => {}); await p.waitForTimeout(300); };

  // 1) Meta com uma consulta falhando: avisa e não guarda; ao tentar de novo (consulta já ok) mostra o grupo que faltava
  await p.goto(APP + '#meta'); await idle();
  const t1 = await p.locator('#app').innerText();
  ok('Meta com consulta falhando mostra o aviso de falha', /Tentar de novo/.test(t1), t1.slice(0, 80));
  FALHA_META = false;
  await p.evaluate(() => route()); await idle();
  const t2 = await p.locator('#app').innerText();
  ok('ao tentar de novo, Meta busca de novo e mostra o grupo que faltava (Lazer)', /Lazer/.test(t2) && !/Tentar de novo/.test(t2), t2.slice(0, 120).replace(/\n/g, ' '));

  // 2) Lançamentos: total de 2.500 lançamentos (3 páginas além da primeira) soma tudo
  await p.goto(APP + '#lancamentos?month=2026-11'); await idle(); await p.waitForTimeout(800);
  const tt = await p.evaluate(() => (window._lx || {}).tt || null);
  ok('total soma os 2.500 lançamentos', tt && tt.n === N, JSON.stringify(tt));
  ok('entradas e saídas corretas', tt && Math.round(tt.ent) === ENT && Math.round(tt.sai) === SAI, JSON.stringify(tt) + ' esperado ' + ENT + '/' + SAI);
  ok('buscou 3 páginas de total (1.000 + 1.000 + 500)', paginas >= 3, 'páginas ' + paginas);

  ok('nenhuma chamada saiu do simulado', FORA.length === 0, FORA.slice(0, 3).join(' '));
  ok('sem erro de script', errs.length === 0, errs.slice(0, 2).join(' | '));
  await b.close();
  for (const r of results) console.log(r[0], r[1], r[2]);
  const f = results.filter(r => r[0] !== 'OK ').length;
  console.log(f ? 'RESULTADO: HÁ FALHAS (' + f + ')' : 'RESULTADO: TUDO OK (' + results.length + ' verificações)');
  process.exitCode = f ? 1 : 0;
})().catch(e => { console.error(e); process.exit(1); });
