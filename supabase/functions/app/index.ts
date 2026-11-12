// Família Finance AI — app (desativada em 12/11/2026)
// Tentativa antiga de servir o SPA pelo Supabase (o domínio supabase.co bloqueia HTML).
// O app real está no Railway: https://familia-finance.up.railway.app
// Código anterior (v0.1) preservado no repositório (histórico do git). Remover esta função pelo painel do Supabase.
Deno.serve(() => new Response(JSON.stringify({ error: "gone", app: "https://familia-finance.up.railway.app" }), { status: 410, headers: { "Content-Type": "application/json" } }));
