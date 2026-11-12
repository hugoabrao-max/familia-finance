// Diagnóstico temporário (somente leitura: GET item, sem refresh)
import { createClient } from "npm:@supabase/supabase-js@2";
const PLUGGY = "https://api.pluggy.ai";
const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
Deno.serve(async (req) => {
  const tok = req.headers.get("x-sync-token");
  const { data: s } = await sb.from("app_settings").select("value").eq("key", "sync_token").maybeSingle();
  if (!tok || tok !== s?.value) return new Response("unauthorized", { status: 401 });
  let body: any = {}; try { body = await req.json(); } catch {}
  const a = await fetch(`${PLUGGY}/auth`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ clientId: Deno.env.get("PLUGGY_CLIENT_ID"), clientSecret: Deno.env.get("PLUGGY_CLIENT_SECRET") }) });
  const key = (await a.json()).apiKey;
  const out: any = {};
  for (const id of (body.items ?? [])) {
    const r = await fetch(`${PLUGGY}/items/${id}`, { headers: { "X-API-KEY": key } });
    const j: any = await r.json().catch(() => null);
    out[id] = { http: r.status, status: j?.status, executionStatus: j?.executionStatus, lastUpdatedAt: j?.lastUpdatedAt, updatedAt: j?.updatedAt, nextAutoSyncAt: j?.nextAutoSyncAt, autoSyncDisabledAt: j?.autoSyncDisabledAt, statusDetail: j?.statusDetail, error: j?.error, connector: j?.connector?.name, products: j?.products };
  }
  return new Response(JSON.stringify(out), { headers: { "Content-Type": "application/json" } });
});
