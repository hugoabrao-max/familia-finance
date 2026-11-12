// pluggy-diag — desativada em 12/11/2026 (diagnóstico temporário; usada por último para remover o item antigo
// 22255fcb na Pluggy, autorizado pelo Hugo). Versões anteriores no histórico do git. Remover pelo painel do Supabase.
Deno.serve(() => new Response(JSON.stringify({ error: "gone" }), { status: 410, headers: { "Content-Type": "application/json" } }));
