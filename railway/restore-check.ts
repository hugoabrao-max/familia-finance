// Família Finance AI — restore-check: baixa o backup mais recente do bucket, descomprime, envia ao Supabase
// para restauração em esquema isolado (restore_test) e compara com a produção. Script: roda ao publicar.
import { S3Client } from "bun";

const url = Bun.env.BACKUP_URL!;
const token = Bun.env.BACKUP_TOKEN!;
const s3 = new S3Client({
  endpoint: Bun.env.S3_ENDPOINT!, bucket: Bun.env.S3_BUCKET!, region: Bun.env.S3_REGION || "auto",
  accessKeyId: Bun.env.S3_ACCESS_KEY_ID!, secretAccessKey: Bun.env.S3_SECRET_ACCESS_KEY!,
});

try {
  const listing = await s3.list({ prefix: "familia-finance/" });
  const keys = (listing.contents ?? []).map((o: { key: string }) => o.key).sort();
  if (!keys.length) throw new Error("nenhum backup no bucket");
  const key = keys[keys.length - 1];
  const gz = new Uint8Array(await s3.file(key).arrayBuffer());
  const sha = new Bun.CryptoHasher("sha256").update(gz).digest("hex");
  const json = new TextDecoder().decode(Bun.gunzipSync(gz));
  const r = await fetch(url + "/restore", { method: "POST", headers: { "Content-Type": "application/json", "x-backup-token": token }, body: json });
  const res = await r.json();
  console.log("restore-check", key, sha.slice(0, 16), JSON.stringify(res));
  if (!r.ok || !res.ok) process.exit(1);
} catch (e) {
  console.error("restore-check falhou:", e);
  await fetch(url + "/report", { method: "POST", headers: { "Content-Type": "application/json", "x-backup-token": token }, body: JSON.stringify({ status: "RESTORE_TEST_FAILED", note: String((e as Error).message) }) }).catch(() => {});
  process.exit(1);
}
