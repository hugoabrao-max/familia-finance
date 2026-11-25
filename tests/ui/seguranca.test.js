// Teste de segurança da interface (v0.24.1): links maliciosos no endereço e nomes com código não executam nada.
// Uso: node seguranca.test.js <url_app> <dir_saida>   (requer sb.mjs; ver README.md). Sai com código 1 se algo falhar.
const { chromium } = require('playwright');
const fs = require('fs');
const APP = process.argv[2] || 'http://localhost:3999/';
const OUT = process.argv[3] || '.';
const SB = fs.readFileSync(__dirname + '/sb.mjs');
const reqs = [], writes = [];
const cats = [{ id: 'alimentacao', name: 'Alimentação', parent_id: null, sort: 0, kind: 'despesa' }, { id: 'lazer', name: 'Lazer', parent_id: null, sort: 1, kind: 'despesa' }, { id: 'moradia', name: 'Moradia', parent_id: null, sort: 2, kind: 'despesa' }];
const BUD = [{ group_id: 'alimentacao', group_name: 'Alimentação', orcado: 2000, gasto: 1200, saldo: 800, source: 'hugo' }, { group_id: 'lazer', group_name: 'Lazer', orcado: 1000, gasto: 1300, saldo: -300, source: 'proposta' }, { group_id: 'moradia', group_name: 'Moradia', orcado: 5000, gasto: 3000, saldo: 2000, source: 'proposta' }];
const MC = [{ month: '2026-11-01', group_id: 'moradia', parcelas_cartao: 0, n_parcelas: 0, compromissos_pendentes: 1500, nomes: 'Condomínio' }, { month: '2026-11-01', group_id: 'alimentacao', parcelas_cartao: 300, n_parcelas: 2, compromissos_pendentes: 0, nomes: '' }];
const FE = [{ id: 'f9', name: 'Financiamentos imobiliários (Santander)', valor_atual: 7377.86, pago_mes: 0, is_active: true, end_month: null, source: 'hugo', group_name: 'Moradia', category_id: 'financiamento_imobiliario', category_name: 'Financiamento imobiliário', channel: 'conta', commitment_id: 'c1' },{ id: 'f1', name: 'Condomínio', valor_atual: 1500, pago_mes: 0, is_active: true, end_month: null, source: 'hugo', group_name: 'Moradia', category_name: 'Condomínio', channel: 'conta', commitment_id: 'c2' },
  { id: 'f2', name: 'Internet', valor_atual: 200, pago_mes: 200, is_active: true, end_month: null, source: 'sugerido', group_name: 'Moradia', category_name: 'Internet', channel: 'conta' },
  { id: 'f3', name: 'Escola', valor_atual: 3000, pago_mes: 3000, is_active: true, end_month: null, source: 'sugerido', group_name: 'Educação', category_name: 'Escola', channel: 'conta' }];
let DUPS = [];
const COM = [{ id: 'c3', name: 'Financiamento apto', kind: 'financiamento', category_id: 'financiamento_imobiliario', monthly_amount: 2978.74, end_date: '2054-03-22', outstanding_balance: 300000 },{ id: 'c1', name: 'Financiamento casa', kind: 'financiamento', monthly_amount: 4399.12, installments_paid: 62, installments_total: 420, end_date: '2056-08-12', outstanding_balance: 500000 },
  { id: 'c2', name: 'Condomínio', kind: 'fixo', monthly_amount: 1500, end_date: null }];
function data(t, u) {
  const q = (k) => u.searchParams.get(k) || '';
  switch (t) {
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
    case 'v_sync_status': return [{ connector_name: 'Meu Pluggy', status: 'UPDATED', provider_updated_at: '2026-11-12T16:00:00Z', last_ok_sync: '2026-11-12T14:15:00Z', consent_expires_at: '2027-11-05T00:00:00Z', errors_7d: 0 }];
    case 'sync_jobs': return [{ started_at: '2026-11-12T14:15:00Z', trigger: 'cron', tx_fetched: 146, tx_new: 0, tx_updated: 0, status: 'SUCCESS' }, { started_at: '2026-11-12T10:15:00Z', trigger: 'manual', tx_fetched: 10, tx_new: 1, tx_updated: 0, status: 'PARTIAL' }];
    case 'project_docs': return u.searchParams.get('name') ? { content: 'conteudo' } : [{ name: "X'); window.__pwn='doc'; ('", updated_at: '2026-11-12T20:00:00Z' }];
    case 'household_members': return u.searchParams.get('auth_user_id') ? [{ id: 'm1', role: 'owner', display_name: 'Hugo', auth_user_id: 'u1' }] : [{ id: 'm1', role: 'owner', display_name: 'Hugo', auth_user_id: 'u1', email: 'h@x' }, { id: 'm2', role: 'member', display_name: "D'Ávila <img src=x onerror=\"window.__pwn='membro'\">", auth_user_id: 'u2', email: 'j@x' }];
    case 'data_quality_issues': return DUPS;
    case 'v_tx': return [{ id: 't1', event_date: '2026-11-10', amount: -50, description: 'PADARIA', counterpart_name: 'Padaria', category_id: 'alimentacao', category_name: 'Alimentação', review_status: 'auto', account_name: 'Conta', source: 'pluggy' }];
    case 'v_month_summary': return [{ month: '2026-11-01', receitas: 30000, despesas: -7400, investimentos: 0, resultado: 22600, pendentes: 0 }];
    case 'v_category_month': return [{ month: '2026-11-01', group_id: 'alimentacao', group_name: 'Alimentação', category_id: 'alimentacao', category_name: 'Alimentação', category_kind: 'despesa', n: 4, total: -1200 }];
    default: return [];
  }
}
(async () => {
  const b = await chromium.launch(); const results = []; const ok = (n, c, x) => results.push([c ? 'OK ' : 'FALHA', n, x || '']);
  const ctx = await b.newContext({ viewport: { width: 390, height: 844 }, serviceWorkers: 'block' }); const p = await ctx.newPage();
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  const fora = []; let invite = null;
  await p.clock.setFixedTime(new Date('2026-11-12T15:00:00-04:00'));
  // tudo que não for simulado abaixo é barrado (nada vai para o Supabase real)
  await p.route(u => !u.href.startsWith(APP), r => { fora.push(r.request().url()); return r.abort(); });
  await p.route('https://fonts.googleapis.com/**', r => r.abort());
  await p.route('https://cdn.jsdelivr.net/**', r => r.fulfill({ status: 200, contentType: 'application/javascript', body: SB }));
  await p.route('**/auth/v1/**', r => r.fulfill({ status: 200, contentType: 'application/json', body: '{}' }));
  await p.route('**/functions/v1/member-invite', r => { invite = r.request().postData(); return r.fulfill({ status: 200, contentType: 'application/json', headers: { 'access-control-allow-origin': '*' }, body: '{"error":"simulado"}' }); });
  await p.route('**/rest/v1/**', r => {
    const req = r.request(); const u = new URL(req.url()); const t = u.pathname.split('/rest/v1/')[1]; const m = req.method(); reqs.push(m + ' ' + t + '?' + u.searchParams.toString());
    const cors = { 'access-control-expose-headers': 'content-range', 'access-control-allow-origin': '*' };
    if (t.startsWith('rpc/')) return r.fulfill({ status: 200, contentType: 'application/json', body: 'null' });
    if (m !== 'GET' && m !== 'HEAD') return r.fulfill({ status: 201, headers: cors, contentType: 'application/json', body: '[]' });
    if (m === 'HEAD') return r.fulfill({ status: 200, headers: { ...cors, 'content-range': '0-2/3' }, body: '' });
    const rows = data(t, u); const single = (req.headers()['accept'] || '').includes('vnd.pgrst.object');
    if (single && Array.isArray(rows)) return r.fulfill({ status: 200, headers: cors, contentType: 'application/json', body: JSON.stringify(rows[0] ?? null) });
    if (!single && rows && !Array.isArray(rows)) return r.fulfill({ status: 200, headers: cors, contentType: 'application/json', body: JSON.stringify([rows]) });
    return r.fulfill({ status: 200, headers: cors, contentType: 'application/json', body: JSON.stringify(rows) });
  });
  await p.addInitScript(() => { const exp = Math.floor(Date.now() / 1000) + 86400 * 365; localStorage.setItem('sb-hrsinekxrfiphlhpoewp-auth-token', JSON.stringify({ access_token: 'a.' + btoa(JSON.stringify({ sub: 'u1', exp })) + '.x', token_type: 'bearer', expires_at: exp, refresh_token: 'r', user: { id: 'u1', aud: 'authenticated' } })) });
  const idle = async () => { await p.waitForFunction(() => !document.body.classList.contains('loading'), null, { timeout: 8000 }).catch(() => {}); await p.waitForTimeout(250); };
  const pwn = () => p.evaluate(() => [window.__pwn, document.querySelectorAll('img[src="x"]').length]);
  const PAY = encodeURIComponent('2026-11"><img src=x onerror="window.__pwn=1">');
  const PAY2 = encodeURIComponent("2026-11'><svg onload=window.__pwn=2>");

  // 1) links maliciosos no parâmetro month
  for (const [nome, hash] of [['categoria', '#categoria?id=alimentacao&month=' + PAY], ['lançamentos', '#lancamentos?month=' + PAY], ['orçamento', '#orcamento?month=' + PAY2], ['lançamentos (aspas simples)', '#lancamentos?month=' + PAY2]]) {
    await p.goto(APP + hash); await idle();
    const [w, imgs] = await pwn(); ok('link malicioso em ' + nome + ' não executa', w === undefined && imgs === 0, 'pwn=' + w + ' imgs=' + imgs);
  }
  // 2) o mês envenenado não fica guardado: Início e o seletor de mês seguem com mês válido
  await p.goto(APP + '#inicio'); await idle();
  { const [w, imgs] = await pwn(); ok('Início depois dos links continua limpo', w === undefined && imgs === 0, 'pwn=' + w); }
  await p.goto(APP + '#lancamentos'); await idle();
  const mp = await p.locator('#mp').inputValue().catch(() => '');
  const rot = (await p.locator('.mes .ml > span').textContent().catch(() => '')).trim();
  ok('mês do seletor continua válido (aaaa-mm), no seletor com setas', /^[0-9]{4}-[0-9]{2}$/.test(mp) && /^(janeiro|fevereiro|março|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)( de [0-9]{4})?$/.test(rot) && (await p.locator('.mes button[aria-label="Mês anterior"]').count()) === 1, mp + ' / ' + rot);
  // 3) mês válido pelo link continua funcionando
  await p.goto(APP + '#lancamentos?month=2026-10'); await idle();
  ok('link com mês válido continua funcionando', (await p.locator('#mp').inputValue().catch(() => '')) === '2026-10' && (await p.locator('.mes .ml > span').textContent()).trim() === 'outubro');

  // 4) nomes vindos do banco com aspas e código (membro e documento)
  await p.goto(APP + '#operacao'); await idle();
  { const [w, imgs] = await pwn(); ok('tela Mais com nomes hostis não executa nada', w === undefined && imgs === 0, 'pwn=' + w + ' imgs=' + imgs); }
  const item = p.locator('.item[data-id="m2"]');
  ok('membro com apóstrofo aparece na lista', (await item.count()) === 1 && (await item.textContent()).includes("D'Ávila"));
  await item.click(); await p.waitForTimeout(500);
  const sheet = await p.locator('.sheet, #sheet, [role=dialog]').first().textContent().catch(() => '');
  { const [w] = await pwn(); ok('clicar no membro abre "Acesso de" com o nome como texto', w === undefined && sheet.includes("Acesso de D'Ávila <img"), sheet.slice(0, 80)); }
  ok('gerar acesso manda o id certo', !!invite && JSON.parse(invite).member_id === 'm2', invite || 'nada enviado');
  await p.keyboard.press('Escape'); await p.waitForTimeout(300);
  const doc = p.locator('.item[data-n]:not([data-id])').filter({ hasText: 'window.__pwn' });
  ok('documento com nome hostil aparece como texto', (await doc.count()) === 1);
  if (await doc.count()) { await doc.click(); await p.waitForTimeout(500); }
  { const [w] = await pwn(); ok('abrir documento com nome hostil não executa', w === undefined, 'pwn=' + w); }
  ok('documento é buscado pelo nome exato', reqs.some(r => r.startsWith('GET project_docs?') && r.includes('name=eq.') && decodeURIComponent(r).includes("__pwn='doc'")));

  ok('nenhuma chamada saiu para fora do simulado', fora.length === 0, fora.slice(0, 3).join(' '));
  ok('sem erro de script', errs.length === 0, errs.slice(0, 2).join(' | '));
  await b.close();
  for (const r of results) console.log(r[0], r[1], r[2]);
  const f = results.filter(r => r[0] !== 'OK ').length;
  console.log(f ? 'RESULTADO: HÁ FALHAS (' + f + ')' : 'RESULTADO: TUDO OK (' + results.length + ' verificações)');
  process.exit(f ? 1 : 0);
})().catch(e => { console.error(e); process.exit(1); });
