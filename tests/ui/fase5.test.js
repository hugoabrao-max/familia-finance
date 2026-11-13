// Teste da Fase 5 (tema no app, notebook em grade, teclado/leitor de tela, vocabulário, tela Mais) com Supabase simulado.
// Uso: node fase5.test.js <url_app> <dir_saida>   (requer sb.mjs; ver README.md)
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
    case 'project_docs': return [{ name: 'ROADMAP', updated_at: '2026-11-12T20:00:00Z' }];
    case 'household_members': return u.searchParams.get('auth_user_id') ? [{ id: 'm1', role: 'owner', display_name: 'Hugo', auth_user_id: 'u1' }] : [{ id: 'm1', role: 'owner', display_name: 'Hugo', auth_user_id: 'u1', email: 'h@x' }, { id: 'm2', role: 'member', display_name: 'Juliana', auth_user_id: 'u2', email: 'j@x' }];
    case 'data_quality_issues': return DUPS;
    case 'v_tx': return [{ id: 't1', event_date: '2026-11-10', amount: -50, description: 'PADARIA', counterpart_name: 'Padaria', category_id: 'alimentacao', category_name: 'Alimentação', review_status: 'auto', account_name: 'Conta', source: 'pluggy' }];
    case 'v_month_summary': return [{ month: '2026-11-01', receitas: 30000, despesas: -7400, investimentos: 0, resultado: 22600, pendentes: 0 }];
    case 'v_category_month': return [{ month: '2026-11-01', group_id: 'alimentacao', group_name: 'Alimentação', category_id: 'alimentacao', category_name: 'Alimentação', category_kind: 'despesa', n: 4, total: -1200 }];
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

  let { ctx, p, errs } = await page({ width: 390, height: 844 }, 'light');
  // Mais
  await p.goto(APP + '#operacao'); await idle(p);
  await p.screenshot({ path: OUT + '/f5-mais.png', fullPage: true });
  const txt = nb(await p.locator('#app').textContent());
  ok('tela chama "Mais"', (await p.locator('h1').first().textContent()).trim() === 'Mais');
  ok('conexão: "atualizada", "há 3 horas", nada de UPDATED', txt.includes('atualizada') && txt.includes('atualizados há 3 horas') && !txt.includes('UPDATED'), txt.slice(0, 200));
  ok('sincronizações: "sem erros", "parcial", "automática"', txt.includes('sem erros') && txt.includes('parcial') && txt.includes('automática') && !txt.includes('SUCCESS'));
  ok('horários no fuso de Cuiabá (14:15 UTC = 10:15)', txt.includes('12/11/2026, 10:15'), '');
  ok('membros: Hugo (dono), Juliana (membro)', txt.includes('Hugo (dono)') && txt.includes('Juliana (membro)') && !txt.includes('owner'));
  ok('duplicidades: seção com aviso quando vazia', (await p.locator('#dup').count()) === 1 && txt.includes('Nenhuma duplicidade em aberto'));
  // tema
  await p.locator('#tema button', { hasText: 'Escuro' }).click();
  ok('tema Escuro aplica na hora', await p.evaluate(() => document.documentElement.dataset.theme) === 'dark' && await p.evaluate(() => getComputedStyle(document.body).backgroundColor) === 'rgb(17, 22, 18)');
  ok('botão marcado (aria-pressed)', await p.locator('#tema button[data-t=escuro]').getAttribute('aria-pressed') === 'true');
  await p.reload(); await idle(p);
  ok('tema guardado após recarregar', await p.evaluate(() => getComputedStyle(document.body).backgroundColor) === 'rgb(17, 22, 18)' && (await p.locator('#tema button.on').textContent()) === 'Escuro');
  await p.locator('#tema button', { hasText: 'Automático' }).click();
  ok('Automático volta ao do aparelho (claro)', await p.evaluate(() => !document.documentElement.hasAttribute('data-theme') && getComputedStyle(document.body).backgroundColor === 'rgb(238, 240, 234)'));
  // duplicidades com item + link do alerta
  DUPS = [{ id: 1, kind: 'duplicate_suspect', status: 'open', created_at: '2026-11-12T12:00:00Z', detail: { description: 'IFD*CUPIM BAR', amount: -211.88, event_date: '2026-10-28' } }];
  await p.goto(APP + '#operacao?sec=dup'); await idle(p); await p.waitForTimeout(200);
  ok('duplicidade listada com valor e data', nb(await p.locator('#dup + .list').textContent()).includes('IFD*CUPIM BAR') && nb(await p.locator('#dup + .list').textContent()).includes('-R$ 211,88'));
  ok('link do alerta rola até as duplicidades', await p.evaluate(() => Math.abs(document.getElementById('dup').getBoundingClientRect().top) < 120));
  DUPS = [];
  // teclado
  await p.goto(APP + '#lancamentos?month=2026-11'); await idle(p);
  const it = p.locator('#lxlist .item').first();
  ok('item da lista vira botão de teclado', await it.getAttribute('role') === 'button' && await it.getAttribute('tabindex') === '0');
  await it.focus(); await p.keyboard.press('Enter'); await p.waitForTimeout(200);
  ok('Enter abre a janela do lançamento', await p.locator('#sheet.on #cx').count() === 1);
  await p.keyboard.press('Escape'); await p.waitForTimeout(100);
  ok('Esc fecha e o foco volta ao item', await p.evaluate(() => document.activeElement && document.activeElement.classList.contains('item')));
  ok('aba atual marcada (aria-current)', await p.locator('.tabs a[aria-current=page]').getAttribute('href') === '#lancamentos');
  ok('ícones das abas escondidos do leitor de tela', await p.locator('.tabs a span[aria-hidden=true]').count() === 6);
  ok('seletor de mês e busca com rótulo', await p.locator('#mp[aria-label]').count() === 1 && await p.locator('#fs[aria-label]').count() === 1);
  const h = await it.evaluate(e => e.getBoundingClientRect().height); ok('alvo de toque ≥ 44 px', h >= 44, h);
  // contas fixas: financiamento incluído pela categoria
  await p.goto(APP + '#fixas'); await idle(p);
  const fin = await p.$$eval('h2:has-text("Financiamentos") + p + .list .item', es => es.map(e => e.textContent));
  ok('financiamento do apto aparece "na lista acima"', fin.some(f => f.includes('Financiamento apto') && f.includes('na lista acima')), fin.join(' | '));
  // vocabulário no código servido
  const html = await (await fetch(APP)).text();
  ok('vocabulário novo (Meta/Simular)', ['Livre depois das contas fixas', 'Livre para o dia a dia', 'Dá para cortar', 'Até quanto cortar', 'O que muda'].every(w => html.includes(w)) && !['Discricionária', 'Corte máx', '= Margem do mês', 'Disponível para os gastos'].some(w => html.includes(w)));
  ok('sem erros de JS (celular)', errs.length === 0, errs.join(' | '));
  await ctx.close();

  ({ ctx, p, errs } = await page({ width: 1366, height: 900 }, 'dark'));
  await p.goto(APP + '#plano'); await idle(p); await p.screenshot({ path: OUT + '/f5-plano-desk.png' });
  ok('notebook: 4 cards lado a lado', (await p.$eval('.cards2', e => getComputedStyle(e).gridTemplateColumns.split(' ').length)) === 4);
  await p.goto(APP + '#operacao'); await idle(p); await p.screenshot({ path: OUT + '/f5-mais-desk.png', fullPage: true });
  const secs = await p.$$eval('.secs > .sec', es => es.map(e => { const r = e.getBoundingClientRect(); return [Math.round(r.left), Math.round(r.top), e.querySelector('h2')?.textContent] }));
  ok('notebook: seções em grade, lidas da esquerda para a direita', secs.length >= 4 && secs[0][1] === secs[1][1] && secs[0][0] < secs[1][0] && secs[2][1] > secs[0][1] && secs[2][0] === secs[0][0], JSON.stringify(secs));
  ok('notebook: tema escuro do aparelho', await p.evaluate(() => getComputedStyle(document.body).backgroundColor) === 'rgb(17, 22, 18)');
  await p.locator('#tema button', { hasText: 'Claro' }).click();
  ok('Claro vence o escuro do aparelho', await p.evaluate(() => getComputedStyle(document.body).backgroundColor) === 'rgb(238, 240, 234)');
  ok('sem erros de JS (notebook)', errs.length === 0, errs.join(' | '));
  await ctx.close(); await b.close();
  for (const r of results) console.log(r.join('  '));
  console.log(results.filter(r => r[0] !== 'OK ').length ? 'RESULTADO: HÁ FALHAS' : 'RESULTADO: TUDO OK (' + results.length + ' verificações)');
})().catch(e => { console.error('ERRO NO TESTE', e); process.exit(1); });
