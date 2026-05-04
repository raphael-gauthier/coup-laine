export function pluralize(count: number, singular: string, plural: string): string {
  return Math.abs(count) <= 1 ? singular : plural;
}

/**
 * French pluralization for noun phrases that may include adjectives.
 * Rules: -s/-x/-z invariable; -al → -aux; -au/-eau/-eu → +x; else +s.
 * Known limitations: -ou words taking -oux (bijou, etc.), -al exceptions
 * (bal, festival, …), and prepositions in compounds are not handled.
 */
export function pluralizeFr(word: string, count: number): string {
  if (count <= 1 || word.length === 0) return word;
  return word.split(' ').map(pluralizeFrWord).join(' ');
}

function pluralizeFrWord(w: string): string {
  if (w.length === 0) return w;
  const lower = w.toLowerCase();
  if (lower.endsWith('s') || lower.endsWith('x') || lower.endsWith('z')) return w;
  if (lower.endsWith('al')) return `${w.slice(0, -2)}aux`;
  if (lower.endsWith('eau') || lower.endsWith('au') || lower.endsWith('eu')) return `${w}x`;
  return `${w}s`;
}
