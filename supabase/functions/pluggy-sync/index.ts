// Família Finance AI — pluggy-sync (v1.3.2)
// Sincroniza itens do conector MeuPluggy (Pluggy) para o Supabase.
// Autenticação da chamada: header x-sync-token = app_settings.sync_token
// ou Authorization: Bearer <service_role_key>.
// Item IDs: secret PLUGGY_ITEM_IDS ou, na falta dele, app_settings.pluggy_item_ids.
// Transações: GET /v2/transactions (cursor). Datas: usadas como a Pluggy entrega (aaaa-mm-dd).
// v1.3 (06/11/2026): reautorização do MeuPluggy gera novos IDs de conta e de transação.
//   - conta nova sem provider_account_id conhecido é casada com a existente por tipo+subtipo+número;
//   - transação nova é casada com a existente da mesma conta por instante (ms) + valor + descrição,
//     e só o ID da origem é trocado (categoria, regra e correções manuais são preservadas).
// v1.3.2: compras no exterior gravadas em BRL (amountInAccountCurrency); moeda/valor originais em original_*.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const PLUGGY = "https://api.pluggy.ai";
const HOUSEHOLD_ID = "00000000-0000-0000-0000-000000000001";
const LOCK_MINUTES = 20;
const OVERLAP_DAYS = 10;
const INITIAL_DAYS = 365;

const sb = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

type Json = Record<string, unknown>;

function isoDate(v: unknown): string | null {
  if (typeof v !== "string" || v.length < 10) return null;
  const s = v.slice(0, 10);
  return /^\d{4}-\d{2}-\d{2}$/.test(s) ? s : null;
}
function ymd(d: Date): string { return d.toISOString().slice(0, 10); }
function addDays(s: string, n: number): string { const d = new Date(s + "T12:00:00Z"); d.setUTCDate(d.getUTCDate() + n); return ymd(d); }
function num(v: unknown): number | null { return typeof v === "number" && isFinite(v) ? Math.round(v * 100) / 100 : null; }
async function sha256(s: string): Promise<string> {
  const b = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return Array.from(new Uint8Array(b)).map((x) => x.toString(16).padStart(2, "0")).join("");
}
function stableStringify(o: unknown): string {
  if (o === null || typeof o !== "object") return JSON.stringify(o);
  if (Array.isArray(o)) return "[" + o.map(stableStringify).join(",") + "]";
  const k = Object.keys(o as Json).sort();
  return "{" + k.map((x) => JSON.stringify(x) + ":" + stableStringify((o as Json)[x])).join(",") + "}";
}
function chunk<T>(a: T[], n: number): T[][] { const r: T[][] = []; for (let i = 0; i < a.length; i += n) r.push(a.slice(i, i + n)); return r; }
function isForeign(t: Json): boolean {
  return typeof t.currencyCode === "string" && t.currencyCode !== "BRL" && typeof t.amountInAccountCurrency === "number";
}
function signedAmount(t: Json): number {
  // compra no exterior: usa o valor em reais (amountInAccountCurrency); o original vai para original_amount
  const rawAmt = isForeign(t) ? Number(t.amountInAccountCurrency) : Number(t.amount ?? 0);
  // sinal gerencial: DEBIT = saída (negativo), CREDIT = entrada (positivo); sem tipo, mantém o sinal da origem
  const s = t.type === "DEBIT" ? -Math.abs(rawAmt) : t.type === "CREDIT" ? Math.abs(rawAmt) : rawAmt;
  return Math.round(s * 100) / 100;
}
function matchKey(eventAt: unknown, amount: number, description: unknown): string | null {
  if (typeof eventAt !== "string") return null;
  const ms = Date.parse(eventAt);
  if (!isFinite(ms)) return null;
  return `${ms}|${amount.toFixed(2)}|${String(description ?? "").trim()}`;
}

class Pluggy {
  apiKey = "";
  async auth() {
    const r = await fetch(`${PLUGGY}/auth`, {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ clientId: Deno.env.get("PLUGGY_CLIENT_ID"), clientSecret: Deno.env.get("PLUGGY_CLIENT_SECRET") }),
    });
    if (!r.ok) throw new Error(`Pluggy auth ${r.status}: ${await r.text()}`);
    this.apiKey = (await r.json()).apiKey;
  }
  async getUrl(u: URL): Promise<Json> {
    for (let attempt = 0; attempt < 4; attempt++) {
      const r = await fetch(u, { headers: { "X-API-KEY": this.apiKey } });
      if (r.ok) return await r.json();
      const body = await r.text();
      if (r.status === 429 || r.status >= 500) { await new Promise((res) => setTimeout(res, 800 * 2 ** attempt)); continue; }
      throw new Error(`Pluggy GET ${u.pathname} ${r.status}: ${body}`);
    }
    throw new Error(`Pluggy GET ${u.pathname}: esgotadas as retentativas`);
  }
  async get(path: string, params: Record<string, string | number> = {}): Promise<Json> {
    const u = new URL(PLUGGY + path);
    for (const [k, v] of Object.entries(params)) u.searchParams.set(k, String(v));
    return this.getUrl(u);
  }
  async paged(path: string, params: Record<string, string | number>): Promise<Json[]> {
    const out: Json[] = [];
    let page = 1, total = 1;
    do {
      const r = await this.get(path, { ...params, page, pageSize: 500 });
      out.push(...((r.results as Json[]) ?? []));
      total = Number(r.totalPages ?? 1);
      page++;
    } while (page <= total);
    return out;
  }
  // paginação por cursor (/v2/transactions): 'next' é a query string pronta da próxima página
  async cursor(path: string, params: Record<string, string | number>): Promise<Json[]> {
    const out: Json[] = [];
    const first = new URL(PLUGGY + path);
    for (const [k, v] of Object.entries(params)) first.searchParams.set(k, String(v));
    let next: string | null = first.search;
    let guard = 0;
    while (next && guard++ < 200) {
      const r = await this.getUrl(new URL(PLUGGY + path + next));
      out.push(...((r.results as Json[]) ?? []));
      next = typeof r.next === "string" && r.next.length ? r.next : null;
    }
    return out;
  }
}

async function setting(key: string): Promise<string | null> {
  const { data } = await sb.from("app_settings").select("value").eq("key", key).maybeSingle();
  return data?.value ?? null;
}

async function authorized(req: Request): Promise<boolean> {
  const svc = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const bearer = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (svc && bearer === svc) return true;
  const tok = req.headers.get("x-sync-token") ?? new URL(req.url).searchParams.get("token");
  if (!tok) return false;
  const stored = await setting("sync_token");
  return !!stored && stored === tok;
}

Deno.serve(async (req) => {
  if (!(await authorized(req))) return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
  let body: Json = {};
  try { body = await req.json(); } catch { /* sem corpo */ }
  const trigger = String(body.trigger ?? "manual");
  const forceFrom = typeof body.from === "string" ? body.from : null;

  const since = new Date(Date.now() - LOCK_MINUTES * 60_000).toISOString();
  const { data: running } = await sb.from("sync_jobs").select("id").eq("status", "RUNNING").gte("started_at", since).limit(1);
  if (running && running.length) return new Response(JSON.stringify({ error: "sync_running", job: running[0].id }), { status: 409 });

  const { data: job, error: jobErr } = await sb.from("sync_jobs").insert({ trigger }).select("id, started_at").single();
  if (jobErr || !job) return new Response(JSON.stringify({ error: jobErr?.message }), { status: 500 });
  const jobId = job.id as string;
  const observedAt = job.started_at as string;
  const counters = { connections_total: 0, accounts_total: 0, tx_fetched: 0, tx_new: 0, tx_updated: 0, bills_upserted: 0, investments_upserted: 0 };
  const perAccount: Json[] = [];
  let errors = 0;
  const logErr = async (stage: string, e: unknown, extra: Json = {}) => {
    errors++;
    await sb.from("sync_errors").insert({ sync_job_id: jobId, stage, message: String((e as Error)?.message ?? e), detail: extra });
  };

  const envIds = Deno.env.get("PLUGGY_ITEM_IDS") ?? "";
  const idsSource = envIds.trim() ? envIds : (await setting("pluggy_item_ids")) ?? "";
  const itemIds = idsSource.split(",").map((s) => s.trim()).filter(Boolean);
  const pluggy = new Pluggy();
  try {
    if (!itemIds.length) throw new Error("Nenhum item ID (secret PLUGGY_ITEM_IDS e app_settings.pluggy_item_ids vazios)");
    await pluggy.auth();
  } catch (e) {
    await logErr("auth", e);
    await sb.from("sync_jobs").update({ status: "FAILED", finished_at: new Date().toISOString(), ...counters }).eq("id", jobId);
    return new Response(JSON.stringify({ job: jobId, status: "FAILED", error: String((e as Error).message) }), { status: 500 });
  }

  for (const itemId of itemIds) {
    let connectionId: string | null = null;
    try {
      const item = await pluggy.get(`/items/${itemId}`);
      const connector = (item.connector ?? {}) as Json;
      const { data: prev } = await sb.from("connections").select("id, consent_expires_at").eq("provider_item_id", itemId).maybeSingle();
      const connRow = {
        household_id: HOUSEHOLD_ID,
        provider: "pluggy",
        provider_item_id: itemId,
        connector_id: connector.id ?? null,
        connector_name: connector.name ?? null,
        status: item.status ?? null,
        execution_status: item.executionStatus ?? null,
        status_detail: item.statusDetail ?? null,
        consent_expires_at: item.consentExpiresAt ?? null,
        provider_updated_at: item.lastUpdatedAt ?? null,
        last_sync_at: new Date().toISOString(),
        raw: item,
      };
      const { data: conn, error: cErr } = await sb.from("connections").upsert(connRow, { onConflict: "provider_item_id" }).select("id").single();
      if (cErr || !conn) throw cErr ?? new Error("upsert connections falhou");
      connectionId = conn.id as string;
      counters.connections_total++;
      if (!prev || prev.consent_expires_at !== (item.consentExpiresAt ?? null)) {
        await sb.from("connection_consents").insert({ connection_id: connectionId, consent_expires_at: item.consentExpiresAt ?? null, status: item.status ?? null });
      }

      const accounts = ((await pluggy.get("/accounts", { itemId })).results as Json[]) ?? [];
      for (const a of accounts) {
        const cd = (a.creditData ?? {}) as Json;
        // v1.3: conta já conhecida com outro ID da Pluggy (reautorização) → reaproveita a linha
        const { data: known } = await sb.from("accounts").select("id").eq("provider_account_id", String(a.id)).maybeSingle();
        let remappedAccount = false;
        if (!known && a.number) {
          const { data: same } = await sb.from("accounts").select("id, provider_account_id")
            .eq("type", String(a.type ?? "BANK")).eq("subtype", String(a.subtype ?? "")).eq("number", String(a.number)).limit(2);
          if (same && same.length === 1) {
            const { error: rmErr } = await sb.from("accounts").update({ provider_account_id: String(a.id), connection_id: connectionId }).eq("id", same[0].id);
            if (rmErr) { await logErr("accounts_remap", rmErr, { account: a.id }); continue; }
            remappedAccount = true;
          }
        }
        const accRow = {
          connection_id: connectionId,
          provider_account_id: String(a.id),
          type: String(a.type ?? "BANK"),
          subtype: a.subtype ?? null,
          name: a.name ?? null,
          marketing_name: a.marketingName ?? null,
          number: a.number ?? null,
          owner: a.owner ?? null,
          currency: a.currencyCode ?? "BRL",
          balance: num(a.balance),
          credit_limit: num(cd.creditLimit),
          available_credit_limit: num(cd.availableCreditLimit),
          bill_due_day: isoDate(cd.balanceDueDate) ? Number(isoDate(cd.balanceDueDate)!.slice(8, 10)) : null,
          bill_closing_day: isoDate(cd.balanceCloseDate) ? Number(isoDate(cd.balanceCloseDate)!.slice(8, 10)) : null,
          tax_number: a.taxNumber ?? null,
          raw: a,
          balance_observed_at: new Date().toISOString(),
        };
        const { data: acc, error: aErr } = await sb.from("accounts").upsert(accRow, { onConflict: "provider_account_id" }).select("id").single();
        if (aErr || !acc) { await logErr("accounts", aErr ?? "upsert falhou", { account: a.id }); continue; }
        const accountId = acc.id as string;
        counters.accounts_total++;

        if (accRow.balance !== null) {
          const { data: lastBal } = await sb.from("account_balance_history").select("balance").eq("account_id", accountId).order("observed_at", { ascending: false }).limit(1).maybeSingle();
          if (!lastBal || Number(lastBal.balance) !== accRow.balance) {
            await sb.from("account_balance_history").insert({ account_id: accountId, balance: accRow.balance });
          }
        }

        const stat: Json = { account: a.name, subtype: a.subtype, fetched: 0, new: 0, updated: 0, remapped: 0, account_remapped: remappedAccount, from: null, to: null };
        try {
          const today = ymd(new Date());
          let from = forceFrom;
          if (!from) {
            const { data: last } = await sb.from("transactions").select("event_date").eq("account_id", accountId).eq("source", "pluggy").order("event_date", { ascending: false }).limit(1).maybeSingle();
            from = last?.event_date ? addDays(String(last.event_date), -OVERLAP_DAYS) : addDays(today, -INITIAL_DAYS);
          }
          stat.from = from; stat.to = today;
          const txs = await pluggy.cursor("/v2/transactions", { accountId: String(a.id), dateFrom: from, dateTo: today });
          counters.tx_fetched += txs.length; stat.fetched = txs.length;

          const ids = txs.map((t) => String(t.id));
          const idSet = new Set(ids);
          const existing = new Map<string, { id: string; payload_hash: string; changed_count: number }>();
          // lotes de 100: lotes de 500 IDs estouram o tamanho da URL do PostgREST (erro silencioso → duplicidade)
          for (const c of chunk(ids, 100)) {
            const { data, error: exErr } = await sb.from("raw_transactions").select("id, provider_tx_id, payload_hash, changed_count").in("provider_tx_id", c);
            if (exErr) throw exErr;
            for (const r of data ?? []) existing.set(r.provider_tx_id, { id: r.id, payload_hash: r.payload_hash, changed_count: r.changed_count });
          }

          // v1.3: casamento de transações que mudaram de ID (mesma conta, instante, valor e descrição)
          const unknown = txs.filter((t) => !existing.has(String(t.id)));
          if (unknown.length) {
            const pool = new Map<string, { txId: string; rawId: string | null; ref: string }[]>();
            const pageSize = 1000;
            for (let off = 0; ; off += pageSize) {
              const { data, error } = await sb.from("transactions").select("id, raw_transaction_id, source_ref, event_at, amount, description")
                .eq("account_id", accountId).eq("source", "pluggy").gte("event_date", addDays(from!, -2))
                .order("id").range(off, off + pageSize - 1);
              if (error) throw error;
              for (const r of data ?? []) {
                if (idSet.has(r.source_ref)) continue;
                const k = matchKey(r.event_at, Number(r.amount), r.description);
                if (!k) continue;
                const arr = pool.get(k) ?? [];
                arr.push({ txId: r.id, rawId: r.raw_transaction_id, ref: r.source_ref });
                pool.set(k, arr);
              }
              if (!data || data.length < pageSize) break;
            }
            for (const t of unknown) {
              const k = matchKey(t.date, signedAmount(t), t.description ?? t.descriptionRaw ?? "(sem descrição)");
              const cand = k ? pool.get(k) : undefined;
              if (!cand || !cand.length) continue;
              const m = cand.shift()!;
              const newRef = String(t.id);
              const { error: e1 } = await sb.from("transactions").update({ source_ref: newRef }).eq("id", m.txId);
              if (e1) throw e1;
              if (m.rawId) {
                const { data: rr, error: e2 } = await sb.from("raw_transactions").update({ provider_tx_id: newRef }).eq("id", m.rawId).select("id, payload_hash, changed_count").single();
                if (e2) throw e2;
                existing.set(newRef, { id: rr.id, payload_hash: rr.payload_hash, changed_count: rr.changed_count });
              }
              stat.remapped = Number(stat.remapped) + 1;
            }
          }

          const rawInserts: Json[] = [];
          const rawUpdates: Json[] = [];
          for (const t of txs) {
            const h = await sha256(stableStringify(t));
            const ex = existing.get(String(t.id));
            if (!ex) rawInserts.push({ account_id: accountId, provider_tx_id: String(t.id), payload: t, payload_hash: h });
            else if (ex.payload_hash !== h) rawUpdates.push({ id: ex.id, payload: t, payload_hash: h, changed_count: ex.changed_count + 1 });
          }
          const rawIdByTx = new Map<string, string>();
          for (const [k, v] of existing) rawIdByTx.set(k, v.id);
          for (const c of chunk(rawInserts, 500)) {
            const { data, error } = await sb.from("raw_transactions").insert(c).select("id, provider_tx_id");
            if (error) throw error;
            for (const r of data ?? []) rawIdByTx.set(r.provider_tx_id, r.id);
          }
          for (const u of rawUpdates) {
            await sb.from("raw_transactions").update({ payload: u.payload, payload_hash: u.payload_hash, changed_count: u.changed_count, last_seen_at: new Date().toISOString() }).eq("id", u.id);
          }
          const updatedIds = new Set(rawUpdates.map((u) => u.id));
          const unchanged = ids.filter((i) => existing.has(i) && !updatedIds.has(existing.get(i)!.id));
          for (const c of chunk(unchanged, 100)) await sb.from("raw_transactions").update({ last_seen_at: new Date().toISOString() }).in("provider_tx_id", c);
          counters.tx_new += rawInserts.length; counters.tx_updated += rawUpdates.length;
          stat.new = rawInserts.length; stat.updated = rawUpdates.length;

          const rows: Json[] = [];
          for (const t of txs) {
            const ccm = (t.creditCardMetadata ?? {}) as Json;
            const eventDate = isoDate(t.date) ?? today;
            rows.push({
              account_id: accountId,
              raw_transaction_id: rawIdByTx.get(String(t.id)) ?? null,
              source: "pluggy",
              source_ref: String(t.id),
              event_date: eventDate,
              event_at: t.date ?? null,
              amount: signedAmount(t),
              currency: "BRL",
              original_amount: isForeign(t) ? (t.type === "DEBIT" ? -Math.abs(Number(t.amount)) : Math.abs(Number(t.amount))) : null,
              original_currency: isForeign(t) ? t.currencyCode : null,
              description: String(t.description ?? t.descriptionRaw ?? "(sem descrição)"),
              description_raw: t.descriptionRaw ?? null,
              provider_code: t.providerCode ?? t.providerId ?? null,
              type: t.type ?? null,
              status: t.status ?? "POSTED",
              operation_type: t.operationType ?? null,
              payment_data: t.paymentData ?? null,
              merchant: t.merchant ?? null,
              installment_number: ccm.installmentNumber ?? null,
              installment_total: ccm.totalInstallments ?? null,
              bill_closing_date: isoDate(t.billClosingDate),
              bill_forecast_date: isoDate(t.billForecastDate),
              balance_after: num(t.balance),
              provider_category: t.category ?? null,
              is_deleted_at_source: false,
            });
          }
          for (const c of chunk(rows, 500)) {
            const { error } = await sb.from("transactions").upsert(c, { onConflict: "source,source_ref" });
            if (error) throw error;
          }
        } catch (e) { await logErr("transactions", e, { account: a.id, name: a.name }); stat.error = String((e as Error).message); }

        if (a.type === "CREDIT") {
          try {
            const bills = ((await pluggy.get("/bills", { accountId: String(a.id) })).results as Json[]) ?? [];
            const rows = bills.map((b) => ({
              account_id: accountId,
              provider_bill_id: String(b.id),
              due_date: isoDate(b.dueDate),
              closing_date: isoDate(b.closingDate ?? b.closeDate),
              total_amount: num(b.totalAmount),
              minimum_payment: num(b.minimumPaymentAmount ?? b.minimumPayment),
              allows_installments: typeof b.allowsInstallments === "boolean" ? b.allowsInstallments : null,
              finance_charges: b.financeCharges ?? null,
              raw: b,
            }));
            if (rows.length) {
              const { error } = await sb.from("card_statements").upsert(rows, { onConflict: "provider_bill_id" });
              if (error) throw error;
            }
            counters.bills_upserted += rows.length; stat.bills = rows.length;
          } catch (e) { await logErr("bills", e, { account: a.id }); }
        }
        perAccount.push(stat);
      }

      try {
        const inv = ((await pluggy.get("/investments", { itemId })).results as Json[]) ?? [];
        const rows = inv.map((i) => ({
          connection_id: connectionId,
          provider_investment_id: String(i.id),
          name: i.name ?? null,
          type: i.type ?? null,
          subtype: i.subtype ?? null,
          balance: num(i.balance),
          amount_invested: num(i.amount ?? i.amountOriginal),
          rate: typeof i.rate === "number" ? i.rate : null,
          rate_type: i.rateType ?? null,
          due_date: isoDate(i.dueDate),
          raw: i,
          observed_at: observedAt,
        }));
        if (rows.length) {
          const { error } = await sb.from("investment_positions").upsert(rows, { onConflict: "provider_investment_id,observed_at" });
          if (error) throw error;
        }
        counters.investments_upserted += rows.length;
      } catch (e) { await logErr("investments", e, { item: itemId }); }
    } catch (e) {
      await logErr("item", e, { item: itemId });
    }
  }

  const status = errors === 0 ? "SUCCESS" : (counters.accounts_total > 0 ? "PARTIAL" : "FAILED");
  const summary = { accounts: perAccount, errors };
  await sb.from("sync_jobs").update({ status, finished_at: new Date().toISOString(), ...counters, summary }).eq("id", jobId);
  return new Response(JSON.stringify({ job: jobId, status, ...counters, accounts: perAccount }), { headers: { "Content-Type": "application/json" } });
});
