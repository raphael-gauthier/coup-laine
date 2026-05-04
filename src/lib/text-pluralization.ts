export function pluralize(count: number, singular: string, plural: string): string {
  return Math.abs(count) <= 1 ? singular : plural;
}

/**
 * Returns the noun in the form matching `count` (singular for ≤1, else plural).
 * Accepts the input in either form: pluralizes a singular when needed,
 * singularizes a plural when needed.
 *
 * Plural rules: -s/-x/-z already plural; -al → -aux; -au/-eau/-eu → +x; else +s.
 * Singular rules: -eaux → -eau; -aux → -al; trailing -s → strip; -x/-z → as-is.
 *
 * Known limitations: -ou words taking -oux (bijou, etc.), -al exceptions
 * (bal, festival, …), and prepositions in compounds are not handled.
 */
export function pluralizeFr(word: string, count: number): string {
  if (word.length === 0) return word;
  if (count <= 1) return word.split(' ').map(singularizeFrWord).join(' ');
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

function singularizeFrWord(w: string): string {
  if (w.length === 0) return w;
  const lower = w.toLowerCase();
  if (lower.endsWith('eaux')) return w.slice(0, -1); // Veaux → Veau
  if (lower.endsWith('aux') && w.length > 3) return `${w.slice(0, -3)}al`; // Chevaux → Cheval
  if (lower.endsWith('s')) return w.slice(0, -1); // Moutons → Mouton
  return w; // already singular or unknown form
}
