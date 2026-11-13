// Gera o instalador do Family Finance (Windows .exe e, para teste, Linux).
// Uso: bun install/instalador/build.ts
// 1) monta a cópia limpa (install/export_kit.sh, que barra dado pessoal)
// 2) exporta o app como site estático com marcadores __SBHOST__/__SBKEY__
// 3) embute SQL, Edge Functions e site num assets.gen.ts
// 4) compila instalador.ts
import { $ } from "bun";
import { mkdtempSync, readdirSync, readFileSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";

const HERE = import.meta.dir;
const ROOT = join(HERE, "..", "..");
const tmp = mkdtempSync(join(tmpdir(), "ff-kit-"));
const kit = join(tmp, "family-finance");
await $`bash ${join(ROOT, "install", "export_kit.sh")} ${kit}`;
const site = join(tmp, "site");
await $`bun ${join(kit, "app", "src", "app.ts")}`.env({ ...process.env, EXPORT_STATIC: site, SUPABASE_URL: "https://__SBHOST__", SUPABASE_ANON_KEY: "__SBKEY__" });

const text = (p: string) => readFileSync(p, "utf8");
const assets = {
  schema: text(join(kit, "install", "01_schema.sql")),
  seed: text(join(kit, "install", "02_seed.sql")),
  cron: text(join(kit, "install", "03_cron.sql")),
  functions: Object.fromEntries(["pluggy-sync", "member-invite", "backup-export"].map(f => [f, text(join(kit, "supabase", "functions", f, "index.ts"))])),
  site: Object.fromEntries(readdirSync(site).map(f => [f, readFileSync(join(site, f)).toString("base64")])),
  version: JSON.parse(text(join(site, "health.json"))).version as string,
};
for (const [k, v] of Object.entries(assets.site)) if (!v) throw new Error("arquivo vazio no site: " + k);
writeFileSync(join(HERE, "assets.gen.ts"), "// gerado por build.ts — não editar\nexport const ASSETS = " + JSON.stringify(assets) + " as const;\n");
console.log("assets:", Object.keys(assets.site).length, "arquivos do site, versão", assets.version);

mkdirSync(join(HERE, "dist"), { recursive: true });
await $`bun build --compile --target=bun-windows-x64 ${join(HERE, "instalador.ts")} --outfile ${join(HERE, "dist", "FamilyFinance-Instalador.exe")}`;
await $`bun build --compile ${join(HERE, "instalador.ts")} --outfile ${join(HERE, "dist", "familyfinance-instalador-linux")}`;
console.log("pronto: dist/FamilyFinance-Instalador.exe");
