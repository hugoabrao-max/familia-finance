// Desativada: foi usada uma vez em 06/11/2026 para gerar o link de redefinição de senha do responsável.
Deno.serve(() => new Response(JSON.stringify({ error: "desativada" }), { status: 410, headers: { "Content-Type": "application/json" } }));
