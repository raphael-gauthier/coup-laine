function parsePart(part: string | undefined): number {
  if (part === undefined) return 0;
  const cleaned = part.split('-')[0] ?? '0';
  const n = Number.parseInt(cleaned, 10);
  return Number.isFinite(n) ? n : NaN;
}

function parseSemver(v: string): [number, number, number] | null {
  const [head] = v.split('-');
  const parts = (head ?? '').split('.');
  if (parts.length === 0 || parts[0] === '') return null;
  const major = parsePart(parts[0]);
  const minor = parsePart(parts[1]);
  const patch = parsePart(parts[2]);
  if (Number.isNaN(major) || Number.isNaN(minor) || Number.isNaN(patch)) return null;
  return [major, minor, patch];
}

export function compareSemver(a: string, b: string): -1 | 0 | 1 {
  const pa = parseSemver(a);
  const pb = parseSemver(b);
  // Either side malformed → fail-open: pretend equal so the caller treats as 'ok'.
  if (!pa || !pb) return 0;
  for (let i = 0; i < 3; i++) {
    const ai = pa[i] ?? 0;
    const bi = pb[i] ?? 0;
    if (ai < bi) return -1;
    if (ai > bi) return 1;
  }
  return 0;
}
