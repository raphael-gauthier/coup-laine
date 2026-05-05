export function normalizeForSearch(input: string): string {
  return input
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '') // strip combining diacritical marks
    .replace(/\s+/g, ' ')
    .trim();
}

function normalize(s: string): string {
  return s.toLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, '');
}

export function matchesQuery(haystack: string | null | undefined, query: string): boolean {
  if (!query.trim()) return true;
  if (!haystack) return false;
  return normalize(haystack).includes(normalize(query));
}

export function matchesAny(fields: (string | null | undefined)[], query: string): boolean {
  if (!query.trim()) return true;
  return fields.some((f) => f && matchesQuery(f, query));
}
