// Família Finance AI — regra de retenção dos backups (usada por backup.ts; testada por retencao.test.ts).
// Mantém TUDO dos últimos 35 dias e, de antes disso, o primeiro backup de cada mês (para sempre).
// Nunca apaga se sobrarem menos de 30 backups. Chave: familia-finance/2026-11-24T09-00-30-177Z.json.gz
export const PREFIX = "familia-finance/";
export function dataDaChave(key: string): Date | null {
  const m = /^familia-finance\/(\d{4}-\d{2}-\d{2})T(\d{2})-(\d{2})-(\d{2})-(\d{3})Z\.json\.gz$/.exec(key);
  if (!m) return null;
  const d = new Date(`${m[1]}T${m[2]}:${m[3]}:${m[4]}.${m[5]}Z`);
  return isNaN(d.getTime()) ? null : d;
}
export function escolherApagar(keys: string[], agora: Date, diasTudo = 35, minimo = 30): string[] {
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
