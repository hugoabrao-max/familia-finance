// Gera link de primeiro acesso / redefinição de senha para um membro da família.
// Só o responsável (owner/admin) pode chamar. O link abre o app, que valida o token e pede a nova senha.
import { createClient } from "npm:@supabase/supabase-js@2";
const APP_URL = "https://familia-finance.up.railway.app";
const cors = { "Access-Control-Allow-Origin": APP_URL, "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info", "Access-Control-Allow-Methods": "POST, OPTIONS" };
const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { ...cors, "Content-Type": "application/json" } });
const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") return json({ error: "método" }, 405);
  const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  const { data: u, error: ue } = await admin.auth.getUser(jwt);
  if (ue || !u?.user) return json({ error: "não autenticado" }, 401);
  const { data: caller } = await admin.from("household_members").select("id,role,household_id,display_name").eq("auth_user_id", u.user.id).maybeSingle();
  if (!caller || !["owner", "admin"].includes(caller.role)) return json({ error: "sem permissão" }, 403);
  let body: any = {}; try { body = await req.json(); } catch { /* */ }
  const { data: m } = await admin.from("household_members").select("id,email,display_name,auth_user_id,household_id").eq("id", body.member_id).maybeSingle();
  if (!m || m.household_id !== caller.household_id || !m.email) return json({ error: "membro não encontrado" }, 404);
  if (!m.auth_user_id) {
    const { error: ce } = await admin.auth.admin.createUser({ email: m.email, email_confirm: true });
    if (ce && !/already/i.test(ce.message)) return json({ error: "criar usuário: " + ce.message }, 500);
  }
  const { data: link, error: le } = await admin.auth.admin.generateLink({ type: "recovery", email: m.email });
  if (le || !link?.properties?.hashed_token) return json({ error: "gerar link: " + (le?.message || "sem token") }, 500);
  await admin.from("audit_logs").insert({ table_name: "household_members", row_id: m.id, action: "access_link", actor: caller.id, actor_label: caller.display_name, after: { email: m.email } });
  const url = APP_URL + "/#acesso=" + encodeURIComponent(link.properties.hashed_token) + "&e=" + encodeURIComponent(m.email);
  return json({ url, nome: m.display_name, validade: "1 hora, uso único" });
});
