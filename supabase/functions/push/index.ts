// Notificações no celular (Web Push) do Family Finance.
// v1.0 (16/11/2026). verify_jwt = false: autenticação feita aqui (login do app ou x-sync-token do agendamento).
//   op=key          → chave pública VAPID (gerada e guardada em app_settings na primeira vez)
//   op=subscribe    → (login) grava o aparelho do membro
//   op=unsubscribe  → (login) remove o aparelho
//   op=test         → (login) manda um aviso de teste para os aparelhos do próprio membro
//   op=digest       → (x-sync-token) se houver lançamentos pendentes, avisa todos os aparelhos inscritos em "revisao"
// Chaves VAPID nunca saem do servidor: a privada fica em app_settings (sem política de leitura = só service role).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const APP_URL = "https://familia-finance.up.railway.app";
const cors = { "Access-Control-Allow-Origin": APP_URL, "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info", "Access-Control-Allow-Methods": "POST, OPTIONS" };
const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { ...cors, "Content-Type": "application/json" } });
const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
const te = new TextEncoder();

// ---------- base64url ----------
const b64u = (b: Uint8Array) => btoa(String.fromCharCode(...b)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const unb64u = (s: string) => { s = s.replace(/-/g, "+").replace(/_/g, "/"); while (s.length % 4) s += "="; return Uint8Array.from(atob(s), c => c.charCodeAt(0)); };
const concat = (...a: Uint8Array[]) => { const o = new Uint8Array(a.reduce((n, x) => n + x.length, 0)); let p = 0; for (const x of a) { o.set(x, p); p += x.length; } return o; };

async function setting(key: string) { const { data } = await sb.from("app_settings").select("value").eq("key", key).maybeSingle(); return data?.value as string | undefined; }

// ---------- chaves VAPID ----------
let vapidCache: { pub: string; priv: CryptoKey } | null = null;
async function vapid() {
  if (vapidCache) return vapidCache;
  let pub = await setting("vapid_public"); let jwk = await setting("vapid_private_jwk");
  if (!pub || !jwk) {
    const kp = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign", "verify"]) as CryptoKeyPair;
    pub = b64u(new Uint8Array(await crypto.subtle.exportKey("raw", kp.publicKey)));
    jwk = JSON.stringify(await crypto.subtle.exportKey("jwk", kp.privateKey));
    // insere só se ainda não existir (duas chamadas simultâneas não trocam a chave)
    await sb.from("app_settings").upsert([{ key: "vapid_public", value: pub }, { key: "vapid_private_jwk", value: jwk }], { onConflict: "key", ignoreDuplicates: true });
    pub = await setting("vapid_public"); jwk = await setting("vapid_private_jwk");
  }
  const priv = await crypto.subtle.importKey("jwk", JSON.parse(jwk!), { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  vapidCache = { pub: pub!, priv }; return vapidCache;
}
async function vapidAuth(endpoint: string) {
  const { pub, priv } = await vapid();
  const aud = new URL(endpoint).origin;
  const head = b64u(te.encode(JSON.stringify({ typ: "JWT", alg: "ES256" })));
  const body = b64u(te.encode(JSON.stringify({ aud, exp: Math.floor(Date.now() / 1000) + 12 * 3600, sub: APP_URL })));
  const sig = new Uint8Array(await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, priv, te.encode(head + "." + body)));
  return `vapid t=${head}.${body}.${b64u(sig)}, k=${pub}`;
}

// ---------- criptografia da mensagem (RFC 8291, aes128gcm) ----------
async function hkdf(salt: Uint8Array, ikm: Uint8Array, info: Uint8Array, len: number) {
  const k = await crypto.subtle.importKey("raw", ikm, "HKDF", false, ["deriveBits"]);
  return new Uint8Array(await crypto.subtle.deriveBits({ name: "HKDF", hash: "SHA-256", salt, info }, k, len * 8));
}
export async function encrypt(payload: Uint8Array, p256dh: string, authSecret: string, salt = crypto.getRandomValues(new Uint8Array(16)), asKeys?: CryptoKeyPair) {
  const uaPub = unb64u(p256dh); const auth = unb64u(authSecret);
  const as = asKeys ?? await crypto.subtle.generateKey({ name: "ECDH", namedCurve: "P-256" }, true, ["deriveBits"]) as CryptoKeyPair;
  const asPub = new Uint8Array(await crypto.subtle.exportKey("raw", as.publicKey));
  const uaKey = await crypto.subtle.importKey("raw", uaPub, { name: "ECDH", namedCurve: "P-256" }, false, []);
  const shared = new Uint8Array(await crypto.subtle.deriveBits({ name: "ECDH", public: uaKey }, as.privateKey, 256));
  const ikm = await hkdf(auth, shared, concat(te.encode("WebPush: info\0"), uaPub, asPub), 32);
  const cek = await hkdf(salt, ikm, te.encode("Content-Encoding: aes128gcm\0"), 16);
  const nonce = await hkdf(salt, ikm, te.encode("Content-Encoding: nonce\0"), 12);
  const key = await crypto.subtle.importKey("raw", cek, "AES-GCM", false, ["encrypt"]);
  const ct = new Uint8Array(await crypto.subtle.encrypt({ name: "AES-GCM", iv: nonce }, key, concat(payload, new Uint8Array([2]))));
  const rs = new Uint8Array(4); new DataView(rs.buffer).setUint32(0, 4096);
  return concat(salt, rs, new Uint8Array([asPub.length]), asPub, ct);
}

type Sub = { id: string; endpoint: string; p256dh: string; auth: string };
async function send(sub: Sub, msg: { title: string; body: string; url: string; tag?: string }) {
  const body = await encrypt(te.encode(JSON.stringify(msg)), sub.p256dh, sub.auth);
  let status = 0;
  try {
    const r = await fetch(sub.endpoint, { method: "POST", headers: { Authorization: await vapidAuth(sub.endpoint), TTL: "86400", Urgency: "normal", "Content-Encoding": "aes128gcm", "Content-Type": "application/octet-stream" }, body });
    status = r.status;
  } catch { status = -1; }
  // 404/410: o aparelho cancelou a inscrição → desativa (não apaga, para o histórico)
  await sb.from("push_subscriptions").update({ last_sent_at: new Date().toISOString(), last_status: status, ...(status === 404 || status === 410 ? { active: false } : {}) }).eq("id", sub.id);
  return status;
}

async function member(req: Request) {
  const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  if (!jwt) return null;
  const { data: u } = await sb.auth.getUser(jwt);
  if (!u?.user) return null;
  const { data: m } = await sb.from("household_members").select("id,display_name").eq("auth_user_id", u.user.id).maybeSingle();
  return m;
}
async function safeEqual(a: string, b: string) {
  const [x, y] = await Promise.all([a, b].map(s => crypto.subtle.digest("SHA-256", te.encode(s))));
  const u = new Uint8Array(x), v = new Uint8Array(y); let d = 0; for (let i = 0; i < u.length; i++) d |= u[i] ^ v[i]; return d === 0;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  let body: any = {}; try { body = await req.json(); } catch { /* sem corpo */ }
  const op = body.op || new URL(req.url).searchParams.get("op");
  try {
    if (op === "key") return json({ key: (await vapid()).pub });

    if (op === "digest") {
      const tok = req.headers.get("x-sync-token") || ""; const stored = await setting("sync_token");
      if (!tok || !stored || !(await safeEqual(tok, stored))) return json({ error: "unauthorized" }, 401);
      const { count } = await sb.from("transactions").select("id", { count: "exact", head: true }).eq("review_status", "pending");
      if (!count) return json({ pendentes: 0, enviados: 0 });
      const { data: subs } = await sb.from("push_subscriptions").select("id,endpoint,p256dh,auth").eq("active", true).contains("kinds", ["revisao"]);
      const msg = { title: "Family Finance", body: count === 1 ? "1 lançamento esperando você na Revisão" : `${count} lançamentos esperando você na Revisão`, url: APP_URL + "/#revisao", tag: "revisao" };
      const st = await Promise.all((subs || []).map(s => send(s as Sub, msg)));
      return json({ pendentes: count, enviados: st.filter(s => s >= 200 && s < 300).length, falhas: st.filter(s => s < 200 || s >= 300).length });
    }

    const m = await member(req);
    if (!m) return json({ error: "não autenticado" }, 401);
    if (op === "subscribe") {
      const s = body.subscription; const k = s?.keys || {};
      if (!s?.endpoint || !/^https:\/\//.test(s.endpoint) || !k.p256dh || !k.auth) return json({ error: "inscrição inválida" }, 400);
      const { error } = await sb.from("push_subscriptions").upsert({ member_id: m.id, endpoint: s.endpoint, p256dh: k.p256dh, auth: k.auth, user_agent: (req.headers.get("user-agent") || "").slice(0, 300), active: true, kinds: ["revisao"] }, { onConflict: "endpoint" });
      if (error) return json({ error: error.message }, 500);
      return json({ ok: true });
    }
    if (op === "unsubscribe") {
      await sb.from("push_subscriptions").delete().eq("member_id", m.id).eq("endpoint", String(body.endpoint || ""));
      return json({ ok: true });
    }
    if (op === "test") {
      const { data: subs } = await sb.from("push_subscriptions").select("id,endpoint,p256dh,auth").eq("member_id", m.id).eq("active", true);
      if (!subs?.length) return json({ error: "nenhum aparelho ativo" }, 404);
      const st = await Promise.all(subs.map(s => send(s as Sub, { title: "Family Finance", body: `Notificações ligadas, ${m.display_name}. É assim que o aviso vai chegar.`, url: APP_URL + "/#revisao", tag: "teste" })));
      return json({ enviados: st.filter(s => s >= 200 && s < 300).length, status: st });
    }
    return json({ error: "operação desconhecida" }, 400);
  } catch (e) {
    return json({ error: (e as Error).message }, 500);
  }
});
