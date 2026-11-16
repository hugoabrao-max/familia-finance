// Gera INSTALAR.html (guia de instalação no navegador, sem Claude e sem tokens) dentro de um kit limpo.
// Uso: bun install/guia/build_guia.ts <pasta_do_kit>   (a pasta criada por install/export_kit.sh)
// Embute: 01_schema.sql, 02_seed.sql, 03_cron.sql, as funções e o app exportado como site estático
// com os marcadores __SBHOST__/__SBKEY__, que a própria página troca pelos dados do projeto da pessoa.
import { $ } from "bun";
import { mkdtempSync, readdirSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";

const kit = process.argv[2];
if (!kit) throw new Error("informe a pasta do kit");
const site = join(mkdtempSync(join(tmpdir(), "ff-guia-")), "site");
await $`bun ${join(kit, "app", "src", "app.ts")}`.env({ ...process.env, EXPORT_STATIC: site, SUPABASE_URL: "https://__SBHOST__", SUPABASE_ANON_KEY: "__SBKEY__" }).quiet();

const text = (p: string) => readFileSync(p, "utf8");
const data = {
  schema: text(join(kit, "install", "01_schema.sql")),
  seed: text(join(kit, "install", "02_seed.sql")),
  cron: text(join(kit, "install", "03_cron.sql")),
  functions: Object.fromEntries(["pluggy-sync", "member-invite", "push"].map(f => [f, text(join(kit, "supabase", "functions", f, "index.ts"))])),
  site: Object.fromEntries(readdirSync(site).map(f => [f, readFileSync(join(site, f)).toString("base64")])),
  version: JSON.parse(text(join(site, "health.json"))).version as string,
};
for (const [k, v] of Object.entries(data.site)) if (!v) throw new Error("arquivo vazio no site: " + k);
if (!text(join(site, "index.html")).includes("__SBHOST__")) throw new Error("site sem marcador __SBHOST__");
// "<" vira < para o JSON não fechar a tag <script> nem abrir comentário HTML
const json = JSON.stringify(data).replace(/</g, "\\u003c");
const tpl = text(join(import.meta.dir, "guia.html"));
if (tpl.split("__KIT__").length !== 2) throw new Error("modelo sem __KIT__ único");
writeFileSync(join(kit, "INSTALAR.html"), tpl.replace("__KIT__", () => json));
console.log(`INSTALAR.html: ${Object.keys(data.site).length} arquivos do app, versão ${data.version}, ${(json.length / 1024).toFixed(0)} KB`);
