// Família Finance AI — backup-export (v1.2)
// GET  /            exportação completa (JSON)
// POST /report      registra resultado do upload em backup_runs
// POST /restore     restaura o JSON enviado em restore_test e compara com a produção
// Autorização: header x-backup-token = app_settings.backup_token
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
const J = (o: unknown, status = 200) => new Response(JSON.stringify(o), { status, headers: { "Content-Type": "application/json" } });

// v1.2 (12/11/2026): comparação do token em tempo constante (SHA-256 + XOR, sem saída antecipada).
async function safeEqual(a: string, b: string): Promise<boolean> {
  const enc = new TextEncoder();
  const [ha, hb] = await Promise.all([crypto.subtle.digest("SHA-256", enc.encode(a)), crypto.subtle.digest("SHA-256", enc.encode(b))]);
  const x = new Uint8Array(ha), y = new Uint8Array(hb);
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i];
  return diff === 0;
}

Deno.serve(async (req) => {
  const tok = req.headers.get("x-backup-token") ?? "";
  const { data: s } = await sb.from("app_settings").select("value").eq("key", "backup_token").maybeSingle();
  if (!tok || !s?.value || !(await safeEqual(tok, s.value))) return J({ error: "unauthorized" }, 401);
  const path = new URL(req.url).pathname;
  if (req.method === "POST" && path.endsWith("/report")) {
    const b = await req.json().catch(() => ({}));
    await sb.from("backup_runs").insert({ status: b.status ?? "UNKNOWN", object_key: b.object_key ?? null, bytes: b.bytes ?? null, sha256: b.sha256 ?? null, tables: b.tables ?? null, note: b.note ?? null });
    return J({ ok: true });
  }
  if (req.method === "POST" && path.endsWith("/restore")) {
    const b = await req.json().catch(() => null);
    if (!b || !b.tables) return J({ error: "backup inválido" }, 400);
    const { data, error } = await sb.rpc("restore_backup_to_test", { p: b });
    if (error) return J({ error: error.message }, 500);
    return J(data);
  }
  const { data, error } = await sb.rpc("export_backup");
  if (error) return J({ error: error.message }, 500);
  return J(data);
});
