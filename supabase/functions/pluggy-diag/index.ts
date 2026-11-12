// pluggy-diag v6 (12/11/2026) — USO ÚNICO: remove na Pluggy o item ANTIGO (app_settings.pluggy_item_ids_anterior),
// autorizado pelo Hugo. Travas: token no header (tempo constante); body.confirm deve ser exatamente o item antigo;
// recusa se o item estiver em app_settings.pluggy_item_ids (em uso). Não apaga nada no banco. Será substituída por stub 410.
import { createClient } from "npm:@supabase/supabase-js@2";
const PLUGGY = "https://api.pluggy.ai";
const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
const J = (o: unknown, status = 200) => new Response(JSON.stringify(o), { status, headers: { "Content-Type": "application/json" } });
async function safeEqual(a: string, b: string) {
  const e = new TextEncoder();
  const [x, y] = (await Promise.all([crypto.subtle.digest("SHA-256", e.encode(a)), crypto.subtle.digest("SHA-256", e.encode(b))])).map((h) => new Uint8Array(h));
  let d = 0; for (let i = 0; i < x.length; i++) d |= x[i] ^ y[i]; return d === 0;
}
async function setting(k: string) { const { data } = await sb.from("app_settings").select("value").eq("key", k).maybeSingle(); return (data?.value ?? "") as string; }
Deno.serve(async (req) => {
  const tok = req.headers.get("x-sync-token") ?? "";
  const stored = await setting("sync_token");
  if (!tok || !stored || !(await safeEqual(tok, stored))) return J({ error: "unauthorized" }, 401);
  let body: any = {}; try { body = await req.json(); } catch {}
  const old = (await setting("pluggy_item_ids_anterior")).trim();
  const inUse = (await setting("pluggy_item_ids")).split(",").map((s) => s.trim()).filter(Boolean);
  const target = String(body.confirm ?? "").trim();
  if (!old || target !== old) return J({ error: "confirm deve ser exatamente o item anterior", anterior: old }, 400);
  if (inUse.includes(target)) return J({ error: "item está em uso; recusado", inUse }, 409);
  const dryRun = body.dryRun !== false;
  const a = await fetch(`${PLUGGY}/auth`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ clientId: Deno.env.get("PLUGGY_CLIENT_ID"), clientSecret: Deno.env.get("PLUGGY_CLIENT_SECRET") }) });
  if (!a.ok) return J({ error: "auth Pluggy " + a.status }, 502);
  const key = (await a.json()).apiKey;
  const info = async (id: string) => { const r = await fetch(`${PLUGGY}/items/${id}`, { headers: { "X-API-KEY": key } }); const j: any = await r.json().catch(() => null); return { http: r.status, status: j?.status, connector: j?.connector?.name, lastUpdatedAt: j?.lastUpdatedAt }; };
  const antes = await info(target);
  const atual = await Promise.all(inUse.map(async (id) => ({ id, ...(await info(id)) })));
  if (dryRun) return J({ dryRun: true, target, antes, itens_em_uso: atual });
  const d = await fetch(`${PLUGGY}/items/${target}`, { method: "DELETE", headers: { "X-API-KEY": key } });
  const delBody = await d.text();
  const depois = await info(target);
  const atualDepois = await Promise.all(inUse.map(async (id) => ({ id, ...(await info(id)) })));
  await sb.from("audit_logs").insert({ table_name: "pluggy_items", row_id: target, action: "delete_at_provider", actor_label: "claude (autorizado pelo Hugo)", before: antes, after: { delete_http: d.status, depois, itens_em_uso: atualDepois } });
  return J({ dryRun: false, target, antes, delete_http: d.status, delete_body: delBody.slice(0, 300), depois, itens_em_uso_depois: atualDepois });
});
