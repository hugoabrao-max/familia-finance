// Família Finance AI — backup: baixa a exportação do Supabase, comprime, grava no bucket S3 do Railway e registra o resultado.
// Roda como script (cron). Variáveis: BACKUP_URL, BACKUP_TOKEN, S3_ENDPOINT, S3_BUCKET, S3_REGION, S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY.
// v2 (24/11/2026): o registro do resultado confere a resposta e tenta 3 vezes (antes, uma falha ao registrar sumia);
//   retenção: depois de um backup verificado, apaga só backups com mais de 35 dias que não sejam o 1º do mês
//   (o bloco abaixo é cópia de railway/retencao.ts, testado por railway/retencao.test.ts).
import { S3Client } from "bun";

const url = Bun.env.BACKUP_URL!;
const token = Bun.env.BACKUP_TOKEN!;
const s3 = new S3Client({
  endpoint: Bun.env.S3_ENDPOINT!, bucket: Bun.env.S3_BUCKET!, region: Bun.env.S3_REGION || "auto",
  accessKeyId: Bun.env.S3_ACCESS_KEY_ID!, secretAccessKey: Bun.env.S3_SECRET_ACCESS_KEY!,
});

// ---- retenção (cópia de retencao.ts) ----
const PREFIX = "familia-finance/";
function dataDaChave(key: string): Date | null {
  const m = /^familia-finance\/(\d{4}-\d{2}-\d{2})T(\d{2})-(\d{2})-(\d{2})-(\d{3})Z\.json\.gz$/.exec(key);
  if (!m) return null;
  const d = new Date(`${m[1]}T${m[2]}:${m[3]}:${m[4]}.${m[5]}Z`);
  return isNaN(d.getTime()) ? null : d;
}
function escolherApagar(keys: string[], agora: Date, diasTudo = 35, minimo = 30): string[] {
  const validos = keys.map((k) => ({ k, d: dataDaChave(k) })).filter((x): x is { k: string; d: Date } => !!x.d).sort((a, b) => a.d.getTime() - b.d.getTime());
  if (validos.length <= minimo) return [];
  const limite = agora.getTime() - diasTudo * 86_400_000;
  const primeiroDoMes = new Set<string>();
  const visto = new Set<string>();
  for (const { k, d } of validos) { const mes = d.toISOString().slice(0, 7); if (!visto.has(mes)) { visto.add(mes); primeiroDoMes.add(k); } }
  const apagar = validos.filter(({ k, d }) => d.getTime() < limite && !primeiroDoMes.has(k)).map(({ k }) => k);
  const sobra = validos.length - apagar.length;
  return sobra < minimo ? apagar.slice(0, Math.max(0, validos.length - minimo)) : apagar;
}
// ---- fim da retenção ----

async function report(body: Record<string, unknown>) {
  for (let i = 1; i <= 3; i++) {
    try {
      const r = await fetch(url + "/report", { method: "POST", signal: AbortSignal.timeout(30_000), headers: { "Content-Type": "application/json", "x-backup-token": token }, body: JSON.stringify(body) });
      if (r.ok) return true;
      console.error("report respondeu", r.status, (await r.text()).slice(0, 200));
    } catch (e) { console.error("report falhou:", (e as Error).message); }
    await Bun.sleep(5000 * i);
  }
  return false;
}

async function listarTudo(): Promise<string[]> {
  const keys: string[] = []; let cont: string | undefined;
  for (let i = 0; i < 100; i++) {
    const r: any = await s3.list({ prefix: PREFIX, ...(cont ? { continuationToken: cont } : {}) });
    for (const o of r.contents ?? []) keys.push(o.key);
    if (!r.isTruncated || !r.nextContinuationToken) break;
    cont = r.nextContinuationToken;
  }
  return keys;
}

let ok = false, key = "";
try {
  const r = await fetch(url, { headers: { "x-backup-token": token }, signal: AbortSignal.timeout(120_000) });
  if (!r.ok) throw new Error("export " + r.status + ": " + (await r.text()).slice(0, 200));
  const json = await r.text();
  const parsed = JSON.parse(json);
  const tables: Record<string, number> = {};
  for (const [k, v] of Object.entries(parsed.tables ?? {})) tables[k] = Array.isArray(v) ? v.length : 0;
  const gz = Bun.gzipSync(new TextEncoder().encode(json));
  const sha = new Bun.CryptoHasher("sha256").update(gz).digest("hex");
  const stamp = new Date().toISOString().replace(/[:.]/g, "-");
  key = `${PREFIX}${stamp}.json.gz`;
  await s3.write(key, gz, { type: "application/gzip" });
  // verificação de integridade: relê o objeto e confere o hash
  const back = await s3.file(key).arrayBuffer();
  const sha2 = new Bun.CryptoHasher("sha256").update(new Uint8Array(back)).digest("hex");
  if (sha2 !== sha) throw new Error("hash divergente após upload");
  ok = true;
  // retenção: só depois de um backup novo verificado; erro aqui não invalida o backup
  let apagados: string[] = [];
  try {
    const todas = await listarTudo();
    apagados = escolherApagar(todas, new Date()).filter((k) => k !== key);
    for (const k of apagados) await s3.file(k).delete();
  } catch (e) { console.error("retenção falhou (backup continua válido):", (e as Error).message); }
  const nota = "verificado por releitura" + (apagados.length ? `; retenção apagou ${apagados.length} antigo(s): ${apagados.slice(0, 3).join(", ")}${apagados.length > 3 ? "…" : ""}` : "");
  const reg = await report({ status: "SUCCESS", object_key: key, bytes: gz.byteLength, sha256: sha, tables, note: nota });
  console.log("backup ok", key, gz.byteLength, "bytes", tables, "apagados", apagados.length, "registrado", reg);
  if (!reg) process.exit(1);
} catch (e) {
  console.error("backup falhou:", e);
  await report({ status: "FAILED", object_key: key || null, note: String((e as Error).message).slice(0, 500) });
  process.exit(1);
}
