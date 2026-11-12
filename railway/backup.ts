// Família Finance AI — backup: baixa a exportação do Supabase, comprime, grava no bucket S3 do Railway e registra o resultado.
// Roda como script (cron). Variáveis: BACKUP_URL, BACKUP_TOKEN, S3_ENDPOINT, S3_BUCKET, S3_REGION, S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY.
import { S3Client } from "bun";

const url = Bun.env.BACKUP_URL!;
const token = Bun.env.BACKUP_TOKEN!;
const s3 = new S3Client({
  endpoint: Bun.env.S3_ENDPOINT!, bucket: Bun.env.S3_BUCKET!, region: Bun.env.S3_REGION || "auto",
  accessKeyId: Bun.env.S3_ACCESS_KEY_ID!, secretAccessKey: Bun.env.S3_SECRET_ACCESS_KEY!,
});

async function report(body: Record<string, unknown>) {
  await fetch(url + "/report", { method: "POST", headers: { "Content-Type": "application/json", "x-backup-token": token }, body: JSON.stringify(body) }).catch(() => {});
}

try {
  const r = await fetch(url, { headers: { "x-backup-token": token } });
  if (!r.ok) throw new Error("export " + r.status + ": " + (await r.text()).slice(0, 200));
  const json = await r.text();
  const parsed = JSON.parse(json);
  const tables: Record<string, number> = {};
  for (const [k, v] of Object.entries(parsed.tables ?? {})) tables[k] = Array.isArray(v) ? v.length : 0;
  const gz = Bun.gzipSync(new TextEncoder().encode(json));
  const sha = new Bun.CryptoHasher("sha256").update(gz).digest("hex");
  const stamp = new Date().toISOString().replace(/[:.]/g, "-");
  const key = `familia-finance/${stamp}.json.gz`;
  await s3.write(key, gz, { type: "application/gzip" });
  // verificação de integridade: relê o objeto e confere o hash
  const back = await s3.file(key).arrayBuffer();
  const sha2 = new Bun.CryptoHasher("sha256").update(new Uint8Array(back)).digest("hex");
  if (sha2 !== sha) throw new Error("hash divergente após upload");
  await report({ status: "SUCCESS", object_key: key, bytes: gz.byteLength, sha256: sha, tables, note: "verificado por releitura" });
  console.log("backup ok", key, gz.byteLength, "bytes", tables);
} catch (e) {
  await report({ status: "FAILED", note: String((e as Error).message) });
  console.error("backup falhou:", e);
  process.exit(1);
}
