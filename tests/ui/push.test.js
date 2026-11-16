// Teste das notificações no celular (v0.24) com Supabase e serviço de push simulados.
// Uso: node push.test.js <url_app> <dir_saida>   (requer sb.mjs; ver README.md)
const { chromium } = require('playwright');
const fs = require('fs');
const APP = process.argv[2] || 'http://localhost:3999/';
const OUT = process.argv[3] || '.';
const SB = fs.readFileSync(__dirname + '/sb.mjs');
const reqs = [], writes = [], calls = [];
function data(t) {
  switch (t) {
    case 'household_members': return [{ id: 'm1', role: 'owner', display_name: 'Juliana', auth_user_id: 'u1', email: 'j@x' }];
    case 'categories': return [];
    case 'accounts': return [];
    case 'v_sync_status': return [{ connector_name: 'Meu Pluggy', status: 'UPDATED', provider_updated_at: '2026-11-12T16:00:00Z' }];
    default: return [];
  }
}
(async () => {
  const b = await chromium.launch({ channel: 'chromium' }); const results = []; const ok = (n, c, x) => results.push([c ? 'OK ' : 'FALHA', n, x || '']);
  async function page(vp, scheme) {
    const ctx = await b.newContext({ viewport: vp, serviceWorkers: 'allow', colorScheme: scheme || 'light' }); const p = await ctx.newPage();
    const errs = []; p.on('pageerror', e => errs.push(e.message));
    await p.clock.setFixedTime(new Date('2026-11-12T15:00:00-04:00'));
    await p.route('https://cdn.jsdelivr.net/**', r => r.fulfill({ status: 200, contentType: 'application/javascript', body: SB }));
    await p.route('https://fonts.googleapis.com/**', r => r.abort());
    await p.route('**/auth/v1/**', r => r.fulfill({ status: 200, contentType: 'application/json', body: '{}' }));
    await ctx.grantPermissions(['notifications']);
    await p.route('**/functions/v1/push', r => { const b = JSON.parse(r.request().postData() || '{}'); calls.push(b);
      const cors = { 'access-control-allow-origin': '*', 'access-control-allow-headers': '*' };
      if (r.request().method() === 'OPTIONS') return r.fulfill({ status: 200, headers: cors, body: '' });
      const out = b.op === 'key' ? { key: 'BADg2AlQFMj8zgkXdzQtQmV9-LnHUGUj6V297vF0Yv9rJkA3noUijnHU447cWurig_qibczInT8KC4lH7cnIGgs' } : b.op === 'test' ? { enviados: 1, status: [201] } : { ok: true };
      return r.fulfill({ status: 200, headers: cors, contentType: 'application/json', body: JSON.stringify(out) }); });
    await p.addInitScript(() => { let sub = null; const mk = () => ({ endpoint: 'https://push.exemplo/abc', toJSON() { return { endpoint: this.endpoint, keys: { p256dh: 'BPk', auth: 'AAA' } } }, unsubscribe: async () => { sub = null; return true } });
      if (window.PushManager) { PushManager.prototype.getSubscription = async function () { return sub }; PushManager.prototype.subscribe = async function (o) { window.__subOpts = o; sub = mk(); return sub } } });
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
  await p.goto(APP + '#operacao'); await idle(p); await p.waitForTimeout(400);
  ok('Mais: seção Notificações com "Ligar neste aparelho"', (await p.locator('#notif button', { hasText: 'Ligar neste aparelho' }).count()) === 1, nb(await p.locator('#notif').textContent()));
  await p.locator('#notif button', { hasText: 'Ligar neste aparelho' }).click(); await p.waitForTimeout(600);
  ok('ligar: pede a chave e grava o aparelho', JSON.stringify(calls.map(c => c.op)) === JSON.stringify(['key', 'subscribe']) && calls[1].subscription.endpoint === 'https://push.exemplo/abc', JSON.stringify(calls));
  ok('ligar: usa a chave pública do servidor (65 bytes)', await p.evaluate(() => window.__subOpts && window.__subOpts.userVisibleOnly === true && window.__subOpts.applicationServerKey.length === 65));
  ok('estado "ligadas neste aparelho" com teste e desligar', nb(await p.locator('#notif').textContent()).includes('ligadas neste aparelho') && (await p.locator('#notif button', { hasText: 'Enviar teste' }).count()) === 1);
  await p.screenshot({ path: OUT + '/push-mais.png' });
  calls.length = 0; await p.locator('#notif button', { hasText: 'Enviar teste' }).click(); await p.waitForTimeout(400);
  ok('enviar teste chama op=test e confirma', calls[0]?.op === 'test' && nb(await p.locator('#toast').textContent()).includes('Aviso de teste enviado'));
  calls.length = 0; await p.locator('#notif button', { hasText: 'Desligar' }).click(); await p.waitForTimeout(500);
  ok('desligar remove o aparelho', calls[0]?.op === 'unsubscribe' && calls[0].endpoint === 'https://push.exemplo/abc' && (await p.locator('#notif button', { hasText: 'Ligar neste aparelho' }).count()) === 1);
  // aviso de verdade: entrega uma mensagem de push ao service worker do app (Chrome DevTools) e confere a notificação
  const cdp = await ctx.newCDPSession(p); let regId = null;
  cdp.on('ServiceWorker.workerRegistrationUpdated', ev => { for (const r of ev.registrations) if (!r.isDeleted) regId = r.registrationId; });
  await cdp.send('ServiceWorker.enable'); await p.waitForTimeout(800);
  ok('service worker do app registrado', !!regId, String(regId));
  if (regId) {
    await cdp.send('ServiceWorker.deliverPushMessage', { origin: APP.replace(/\/$/, ''), registrationId: regId, data: JSON.stringify({ title: 'Family Finance', body: '9 lançamentos esperando você na Revisão', url: APP + '#revisao', tag: 'revisao' }) });
    await p.waitForTimeout(800);
    const notes = await p.evaluate(() => navigator.serviceWorker.ready.then(r => r.getNotifications()).then(n => n.map(x => ({ t: x.title, b: x.body, tag: x.tag, url: x.data && x.data.url }))));
    ok('push vira notificação com texto e link da Revisão', notes.length === 1 && notes[0].t === 'Family Finance' && notes[0].b === '9 lançamentos esperando você na Revisão' && notes[0].tag === 'revisao' && notes[0].url.endsWith('#revisao'), JSON.stringify(notes));
  }
  await ctx.close();
  // iPhone fora da tela de início: explica como instalar
  ({ ctx, p, errs } = await page({ width: 390, height: 844 }));
  await p.addInitScript(() => { Object.defineProperty(navigator, 'userAgent', { get: () => 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Safari/604.1' }); delete window.PushManager; });
  await p.goto(APP + '#operacao'); await idle(p); await p.waitForTimeout(300);
  ok('iPhone no Safari: orienta "Adicionar à Tela de Início"', nb(await p.locator('#notif').textContent()).includes('Adicionar à Tela de Início'));
  ok('sem erros de JS', errs.length === 0, errs.join(' | '));
  await ctx.close(); await b.close();
  for (const r of results) console.log(r.join('  '));
  console.log(results.filter(r => r[0] !== 'OK ').length ? 'RESULTADO: HÁ FALHAS' : 'RESULTADO: TUDO OK (' + results.length + ' verificações)');
})().catch(e => { console.error('ERRO NO TESTE', e); process.exit(1); });
