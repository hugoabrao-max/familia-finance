// Family Finance — instalador. Cria tudo nas contas de quem roda: banco (Supabase) e app (Netlify).
// Compilado por build.ts em FamilyFinance-Instalador.exe. Não guarda tokens em disco.
import { ASSETS } from "./assets.gen.ts";
import { zip } from "./zip.ts";
import { createInterface } from "node:readline/promises";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const SB = process.env.FF_SUPABASE_API || "https://api.supabase.com";
const NL = process.env.FF_NETLIFY_API || "https://api.netlify.com/api/v1";
const STATE_FILE = join(process.cwd(), "family-finance-instalacao.json");
const rl = createInterface({ input: process.stdin, output: process.stdout });
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms));
const say = (s = "") => console.log(s);
const ok = (s: string) => console.log("  ✔ " + s);
const step = (s: string) => console.log("\n▶ " + s);
class Pare extends Error {}
const falha = (msg: string): never => { throw new Pare(msg); };

type State = { ref?: string; dbPass?: string; org?: string; siteId?: string; appUrl?: string; email?: string; family?: string; done?: string[] };
let st: State = existsSync(STATE_FILE) ? JSON.parse(readFileSync(STATE_FILE, "utf8")) : {};
const save = () => writeFileSync(STATE_FILE, JSON.stringify(st, null, 2));
const done = (k: string) => { st.done = [...new Set([...(st.done || []), k])]; save(); };
const did = (k: string) => (st.done || []).includes(k);

async function ask(q: string, opts: { min?: number; re?: RegExp; dica?: string; padrao?: string } = {}) {
  for (;;) {
    const a = (await rl.question("  " + q + (opts.padrao ? ` [${opts.padrao}]` : "") + ": ")).trim() || opts.padrao || "";
    if ((opts.min ?? 1) > a.length) { say("    " + (opts.dica || "Resposta obrigatória.")); continue; }
    if (opts.re && !opts.re.test(a)) { say("    " + (opts.dica || "Formato inválido.")); continue; }
    return a;
  }
}

async function api(base: string, token: string, path: string, init: RequestInit & { json?: unknown } = {}, tent = 4): Promise<any> {
  const headers: Record<string, string> = { Authorization: "Bearer " + token, ...(init.headers as Record<string, string> || {}) };
  let body = init.body;
  if (init.json !== undefined) { headers["Content-Type"] = "application/json"; body = JSON.stringify(init.json); }
  for (let i = 1; ; i++) {
    let r: Response;
    try { r = await fetch(base + path, { ...init, headers, body }); }
    catch (e) { if (i < tent) { await sleep(2000 * i); continue; } return falha(`sem conexão com ${new URL(base).host}: ${(e as Error).message}`); }
    const txt = await r.text(); let data: any = txt; try { data = txt ? JSON.parse(txt) : null; } catch { /* texto */ }
    if (r.ok) return data;
    if ((r.status === 429 || r.status >= 500) && i < tent) { await sleep(3000 * i); continue; }
    if (r.status === 401 || r.status === 403) falha(`${new URL(base).host} recusou o token (${r.status}). Confira se copiou o token inteiro e se ele não expirou.`);
    const msg = typeof data === "object" && data ? (data.message || data.msg || data.error || JSON.stringify(data)) : String(data);
    return falha(`${init.method || "GET"} ${path} → ${r.status}: ${String(msg).slice(0, 400)}`);
  }
}

const normPix = (s: string) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[^a-z ]/g, " ").replace(/\s+/g, " ").trim();
const sqlStr = (s: string) => s.replace(/'/g, "''");
const senhaForte = () => { const c = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789"; const b = crypto.getRandomValues(new Uint8Array(24)); return Array.from(b, x => c[x % c.length]).join(""); };

async function main() {
  say("\n  FAMILY FINANCE — INSTALADOR\n  ===========================");
  say("  Este programa cria o seu Family Finance nas SUAS contas do Supabase (banco de dados) e da Netlify (site do app).");
  say("  Ele não guarda os tokens em lugar nenhum. Ao final, salva os dados da instalação em family-finance-instalacao.json (guarde esse arquivo: tem a senha do banco).\n");
  if (st.ref) say(`  Achei uma instalação começada (projeto ${st.ref}). Vou continuar de onde parou.\n`);
  const modo = st.ref && did("usuario") ? await ask("O app já está instalado. Digite 1 para conectar o banco (Pluggy) ou 2 para reinstalar o site", { re: /^[12]$/, padrao: "1" }) : "0";

  step("Tokens de acesso");
  say("  Supabase: entre em supabase.com/dashboard/account/tokens → Generate new token → copie (começa com sbp_).");
  const sbTok = await ask("Token do Supabase", { re: /^sbp_[A-Za-z0-9_-]{20,}$|^proxy-injected$/, dica: "O token começa com sbp_ e é longo. Copie de novo, inteiro." });
  let nlTok = "";
  if (modo !== "1") {
    say("  Netlify: entre em app.netlify.com → (sua foto) User settings → Applications → Personal access tokens → New access token → copie.");
    nlTok = await ask("Token da Netlify", { re: /^\S{20,}$|^proxy-injected$/, dica: "O token da Netlify é longo. Copie de novo, inteiro." });
  }
  if (modo === "1") return conectarBanco(sbTok);
  if (modo === "2") { st.done = (st.done || []).filter(k => k !== "site"); save(); }

  if (!did("dados")) {
    step("Seus dados");
    st.family = await ask("Nome da família (ex.: Família Silva)", { min: 3 });
    const nome = await ask("Seu primeiro nome (aparece no app)", { min: 2 });
    st.email = (await ask("Seu e-mail (é com ele que você entra no app)", { re: /^[^@\s]+@[^@\s]+\.[^@\s]+$/, dica: "E-mail inválido." })).toLowerCase();
    const pix = normPix(await ask("Seu nome completo como aparece no PIX (ex.: Pedro Henrique Silva)", { min: 5 }));
    (st as any).nome = nome; (st as any).pix = pix; done("dados");
  }
  const senha = did("usuario") ? "" : await ask("Crie a senha para entrar no app (mínimo 8 caracteres)", { min: 8, dica: "Use pelo menos 8 caracteres." });

  // 1. projeto Supabase
  if (!st.ref) {
    step("Criando o banco de dados no Supabase");
    const orgs: any[] = await api(SB, sbTok, "/v1/organizations");
    if (!orgs?.length) falha("Sua conta do Supabase não tem organização. Entre em supabase.com/dashboard, crie uma organização (plano Free) e rode o instalador de novo.");
    let org = orgs[0];
    if (orgs.length > 1) { orgs.forEach((o, i) => say(`    ${i + 1}) ${o.name}`)); const i = Number(await ask("Número da organização", { re: new RegExp(`^[1-${orgs.length}]$`) })); org = orgs[i - 1]; }
    st.org = org.slug; st.dbPass = senhaForte(); save();
    let p: any;
    try { p = await api(SB, sbTok, "/v1/projects", { method: "POST", json: { name: "family-finance", organization_slug: org.slug, db_pass: st.dbPass, region_selection: { type: "specific", code: "sa-east-1" } } }, 1); }
    catch (e) {
      if (/limit|maximum|free projects/i.test((e as Error).message)) falha("O plano gratuito do Supabase permite 2 projetos ativos. Pause ou apague um projeto antigo e rode o instalador de novo.");
      p = await api(SB, sbTok, "/v1/projects", { method: "POST", json: { name: "family-finance", organization_slug: org.slug, db_pass: st.dbPass, region_selection: { type: "smartGroup", code: "americas" } } });
    }
    st.ref = p.ref; save(); ok(`projeto criado (${st.ref})`);
  }
  const ref = st.ref!;
  if (!did("ativo")) {
    say("  Aguardando o banco ficar pronto (costuma levar 1 a 3 minutos)...");
    const t0 = Date.now();
    for (;;) {
      const h: any[] = await api(SB, sbTok, `/v1/projects/${ref}/health?services=auth,db,rest`).catch(() => []);
      if (Array.isArray(h) && h.length >= 3 && h.every(s => s.status === "ACTIVE_HEALTHY")) break;
      if (Date.now() - t0 > 15 * 60e3) falha("O banco não ficou pronto em 15 minutos. Rode o instalador de novo daqui a pouco: ele continua de onde parou.");
      await sleep(10000);
    }
    ok("banco pronto"); done("ativo");
  }

  // 2. estrutura e dados iniciais
  if (!did("esquema")) {
    step("Instalando tabelas, funções e permissões");
    await api(SB, sbTok, `/v1/projects/${ref}/database/query`, { method: "POST", json: { query: ASSETS.schema } });
    const c: any[] = await api(SB, sbTok, `/v1/projects/${ref}/database/query`, { method: "POST", json: { query: "select (select count(*) from pg_tables where schemaname='public')::int t, (select count(*) from pg_views where schemaname='public')::int v" } });
    if (!(c?.[0]?.t >= 41 && c?.[0]?.v >= 22)) falha("A estrutura não ficou completa: " + JSON.stringify(c));
    ok(`${c[0].t} tabelas e ${c[0].v} consultas instaladas`); done("esquema");
  }
  if (!did("seed")) {
    const s: any = st;
    const seed = ASSETS.seed.replaceAll("{{FAMILIA}}", sqlStr(s.family)).replaceAll("{{TITULAR_NOME}}", sqlStr(s.nome)).replaceAll("{{TITULAR_EMAIL}}", sqlStr(s.email)).replaceAll("{{TITULAR_EXTRATO}}", sqlStr(s.pix));
    await api(SB, sbTok, `/v1/projects/${ref}/database/query`, { method: "POST", json: { query: seed } });
    const c: any[] = await api(SB, sbTok, `/v1/projects/${ref}/database/query`, { method: "POST", json: { query: "select (select count(*) from categories)::int c, (select count(*) from household_members)::int m" } });
    if (!(c?.[0]?.c >= 40 && c?.[0]?.m === 1)) falha("Os dados iniciais não entraram: " + JSON.stringify(c));
    ok(`${c[0].c} categorias e a sua família cadastradas`); done("seed");
  }

  // 3. chaves do projeto
  const keys: any[] = await api(SB, sbTok, `/v1/projects/${ref}/api-keys?reveal=true`);
  let pub = keys.find(k => k.type === "publishable")?.api_key;
  let sec = keys.find(k => k.type === "secret")?.api_key;
  if (!pub) pub = (await api(SB, sbTok, `/v1/projects/${ref}/api-keys`, { method: "POST", json: { type: "publishable", name: "default" } })).api_key;
  if (!sec) sec = (await api(SB, sbTok, `/v1/projects/${ref}/api-keys?reveal=true`, { method: "POST", json: { type: "secret", name: "default", secret_jwt_template: { role: "service_role" } } })).api_key;
  const legacySvc = keys.find(k => k.name === "service_role")?.api_key;
  if (!pub) falha("Não consegui obter a chave pública do projeto.");

  // 4. funções
  if (!did("funcoes")) {
    step("Publicando as funções (sincronização, convites, backup)");
    for (const [slug, code] of Object.entries(ASSETS.functions)) {
      const fd = new FormData();
      fd.append("metadata", JSON.stringify({ entrypoint_path: "index.ts", name: slug, verify_jwt: false }));
      fd.append("file", new Blob([code], { type: "application/typescript" }), "index.ts");
      const r = await api(SB, sbTok, `/v1/projects/${ref}/functions/deploy?slug=${slug}`, { method: "POST", body: fd });
      ok(`${slug} (versão ${r?.version ?? "?"})`);
    }
    done("funcoes");
  }

  // 5. site na Netlify
  if (!did("site")) {
    step("Publicando o app na Netlify");
    if (!st.siteId) {
      const nomeSite = "family-finance-" + Array.from(crypto.getRandomValues(new Uint8Array(4)), b => b.toString(16).padStart(2, "0")).join("");
      const s = await api(NL, nlTok, "/sites", { method: "POST", json: { name: nomeSite } });
      st.siteId = s.id; st.appUrl = (s.ssl_url || s.url).replace(/\/+$/, ""); save();
    }
    const host = `${ref}.supabase.co`;
    const files: Record<string, Uint8Array> = {};
    for (const [name, b64] of Object.entries(ASSETS.site)) {
      let bytes = Uint8Array.from(atob(b64), c => c.charCodeAt(0));
      if (/\.(html|json|js)$|^_headers$/.test(name)) bytes = new TextEncoder().encode(new TextDecoder().decode(bytes).replaceAll("__SBHOST__", host).replaceAll("__SBKEY__", pub));
      files[name] = bytes;
    }
    const d = await api(NL, nlTok, `/sites/${st.siteId}/deploys`, { method: "POST", body: zip(files), headers: { "Content-Type": "application/zip" } });
    const t0 = Date.now();
    for (let dep = d; dep.state !== "ready"; ) {
      if (dep.state === "error") falha("A Netlify recusou a publicação: " + (dep.error_message || "erro"));
      if (Date.now() - t0 > 5 * 60e3) falha("A publicação na Netlify demorou demais. Rode o instalador de novo.");
      await sleep(3000); dep = await api(NL, nlTok, `/deploys/${d.id}`);
    }
    ok("app publicado em " + st.appUrl); done("site");
  }

  // 6. segredos e login
  if (!did("auth")) {
    step("Configurando o login");
    await api(SB, sbTok, `/v1/projects/${ref}/secrets`, { method: "POST", json: [{ name: "APP_URL", value: st.appUrl }] });
    await api(SB, sbTok, `/v1/projects/${ref}/config/auth`, { method: "PATCH", json: { site_url: st.appUrl, uri_allow_list: st.appUrl + "/**", disable_signup: true, external_anonymous_users_enabled: false } });
    ok("só quem você cadastrar consegue entrar"); done("auth");
  }
  if (!did("usuario")) {
    const url = `https://${ref}.supabase.co/auth/v1/admin/users`;
    const body = JSON.stringify({ email: st.email, password: senha, email_confirm: true });
    let r = sec ? await fetch(url, { method: "POST", headers: { apikey: sec, "Content-Type": "application/json" }, body }).catch(() => null) : null;
    if ((!r || r.status === 401 || r.status === 403) && legacySvc) r = await fetch(url, { method: "POST", headers: { apikey: legacySvc, Authorization: "Bearer " + legacySvc, "Content-Type": "application/json" }, body }).catch(() => null);
    if (!r) falha(`Não consegui falar com ${ref}.supabase.co para criar o seu login. Confira a internet e rode de novo.`);
    if (!r.ok && !(r.status === 422 && /exist/i.test(await r.clone().text()))) falha("Não consegui criar o seu login: " + r.status + " " + (await r.text()).slice(0, 300));
    const m: any[] = await api(SB, sbTok, `/v1/projects/${ref}/database/query`, { method: "POST", json: { query: "select count(*)::int n from household_members where auth_user_id is not null" } });
    if (m?.[0]?.n !== 1) falha("O login foi criado, mas não ficou ligado à sua família. Confira se o e-mail digitado é o mesmo.");
    ok("seu login está pronto"); done("usuario");
  }

  say("\n  ======================================================");
  say("  PRONTO! Abra no celular ou no computador:  " + st.appUrl);
  say("  Entre com " + st.email + " e a senha que você criou.");
  say("  No celular, use \"Adicionar à tela inicial\" para ter o ícone.");
  say("  ======================================================");
  const q = await ask("Quer conectar seu banco agora (precisa da conta na Pluggy)? s/n", { re: /^[sSnN]$/, padrao: "n" });
  if (/s/i.test(q)) await conectarBanco(sbTok);
  else say("\n  Quando quiser conectar o banco, rode o instalador de novo e escolha a opção 1.");
}

async function conectarBanco(sbTok: string) {
  const ref = st.ref || falha("Não achei a instalação (arquivo family-finance-instalacao.json). Rode o instalador na mesma pasta em que instalou.");
  step("Conectar o banco (Pluggy)");
  say("  1. Crie a conta em dashboard.pluggy.ai e uma aplicação; copie o CLIENT ID e o CLIENT SECRET.");
  say("  2. Conecte suas contas pelo Meu Pluggy (meu.pluggy.ai) autorizando no app do seu banco.");
  say("  3. No painel da Pluggy, copie o ID do item conectado (um código com hífens).");
  const cid = await ask("CLIENT ID da Pluggy", { min: 10 });
  const csec = await ask("CLIENT SECRET da Pluggy", { min: 10 });
  const items = (await ask("ID do item (se tiver mais de um, separe por vírgula)", { re: /^[0-9a-f-]{20,}(\s*,\s*[0-9a-f-]{20,})*$/i, dica: "O ID tem letras, números e hífens, como 3b1fad88-40cc-4d56-8bd5-4c316243310d." })).replace(/\s/g, "");
  await api(SB, sbTok, `/v1/projects/${ref}/secrets`, { method: "POST", json: [{ name: "PLUGGY_CLIENT_ID", value: cid }, { name: "PLUGGY_CLIENT_SECRET", value: csec }] });
  await api(SB, sbTok, `/v1/projects/${ref}/database/query`, { method: "POST", json: { query: `insert into app_settings(key,value) values ('pluggy_item_ids','${sqlStr(items)}') on conflict (key) do update set value=excluded.value, updated_at=now()` } });
  await api(SB, sbTok, `/v1/projects/${ref}/database/query`, { method: "POST", json: { query: "select cron.unschedule(jobname) from cron.job where jobname in ('pluggy-sync-diario','pos-sync')" } }).catch(() => null);
  await api(SB, sbTok, `/v1/projects/${ref}/database/query`, { method: "POST", json: { query: ASSETS.cron.replaceAll("{{PROJECT_REF}}", ref) } });
  ok("banco conectado: o app vai buscar seus lançamentos 4 vezes por dia (o primeiro em até algumas horas)");
  done("pluggy");
}

main().then(async () => { await rl.question("\n  Tecle Enter para fechar."); rl.close(); })
  .catch(async (e) => {
    say("\n  ✖ " + (e instanceof Pare ? e.message : "Erro inesperado: " + (e as Error).stack));
    say("  Nada foi perdido: rode o instalador de novo, na mesma pasta, e ele continua de onde parou.");
    await rl.question("\n  Tecle Enter para fechar."); rl.close(); process.exitCode = 1;
  });
