// Família Finance AI — restore-check: baixa o backup mais recente do bucket, descomprime, envia ao Supabase
// para restauração em esquema isolado (restore_test) e compara com a produção. Script: roda ao publicar.
// v2 (24/11/2026): lista o bucket inteiro (paginado; antes só os 1.000 primeiros) e recusa testar backup com mais
//   de 36 h (falha de backup não passa despercebida como "restauração ok" de um arquivo velho).
import { S3Client } from "bun";

const url = Bun.env.BACKUP_URL!;
const token = Bun.env.BACKUP_TOKEN!;
const s3 = new S3Client({
  endpoint: Bun.env.S3_ENDPOINT!, bucket: Bun.env.S3_BUCKET!, region: Bun.env.S3_REGION || "auto",
  accessKeyId: Bun.env.S3_ACCESS_KEY_ID!, secretAccessKey: Bun.env.S3_SECRET_ACCESS_KEY!,
});
const PREFIX = "familia-finance/";
const MAX_HORAS = 36;

function dataDaChave(key: string): Date | null {
  const m = /^familia-finance\/(\d{4}-\d{2}-\d{2})T(\d{2})-(\d{2})-(\d{2})-(\d{3})Z\.json\.gz$/.exec(key);
  if (!m) return null;
  const d = new Date(`${m[1]}T${m[2]}:${m[3]}:${m[4]}.${m[5]}Z`);
  return isNaN(d.getTime()) ? null : d;
}
async function report(body: Record<string, unknown>) {
  for (let i = 1; i <= 3; i++) {
    try {
      const r = await fetch(url + "/report", { method: "POST", signal: AbortSignal.timeout(30_000), headers: { "Content-Type": "application/json", "x-backup-token": token }, body: JSON.stringify(body) });
      if (r.ok) return true;
    } catch { /* tenta de novo */ }
    await Bun.sleep(5000 * i);
  }
  return false;
}

try {
  const keys: string[] = []; let next: string | undefined;
  for (let i = 0; i < 100; i++) {
    const r: any = await s3.list({ prefix: PREFIX, ...(next ? { continuationToken: next } : {}) });
    for (const o of r.contents ?? []) keys.push(o.key);
    if (!r.isTruncated || !r.nextContinuationToken) break;
    next = r.nextContinuationToken;
  }
  const comData = keys.map((k) => ({ k, d: dataDaChave(k) })).filter((x): x is { k: string; d: Date } => !!x.d).sort((a, b) => a.d.getTime() - b.d.getTime());
  if (!comData.length) throw new Error("nenhum backup no bucket");
  const { k: key, d } = comData[comData.length - 1];
  const horas = (Date.now() - d.getTime()) / 3_600_000;
  if (horas > MAX_HORAS) throw new Error(`backup mais recente tem ${Math.round(horas)} h (${key}); o backup diário não está rodando`);
  const gz = new Uint8Array(await s3.file(key).arrayBuffer());
  const sha = new Bun.CryptoHasher("sha256").update(gz).digest("hex");
  const json = new TextDecoder().decode(Bun.gunzipSync(gz));
  const r = await fetch(url + "/restore", { method: "POST", signal: AbortSignal.timeout(300_000), headers: { "Content-Type": "application/json", "x-backup-token": token }, body: json });
  const res = await r.json();
  console.log("restore-check", key, sha.slice(0, 16), `${keys.length} backups no bucket`, JSON.stringify(res));
  if (!r.ok || !res.ok) process.exit(1);
} catch (e) {
  console.error("restore-check falhou:", e);
  await report({ status: "RESTORE_TEST_FAILED", note: String((e as Error).message).slice(0, 500) });
  process.exit(1);
}
