/// French pluralization for noun phrases that may include adjectives.
///
/// Splits the input on spaces and pluralizes each token following common
/// French rules:
///   - words ending in s/x/z are invariable
///   - -al → -aux (Cheval → Chevaux)
///   - -au, -eau, -eu → +x (Veau → Veaux, Cheveu → Cheveux)
///   - everything else → +s
///
/// Returns [word] unchanged when [count] is 0 or 1.
///
/// Known limitations (uncommon for animal-category names; users can
/// rename if hit):
///   - prepositions inside compounds (e.g. "Cheval de trait") are
///     incorrectly pluralized
///   - the 7 nouns in -ou that take -oux (bijou, caillou, chou, genou,
///     hibou, joujou, pou) are pluralized as +s
///   - -al exceptions (bal, carnaval, festival, …) are pluralized -aux
String pluralizeFr(String word, int count) {
  if (count <= 1 || word.isEmpty) return word;
  return word.split(' ').map(_pluralizeWord).join(' ');
}

String _pluralizeWord(String w) {
  if (w.isEmpty) return w;
  final lower = w.toLowerCase();
  if (lower.endsWith('s') || lower.endsWith('x') || lower.endsWith('z')) {
    return w;
  }
  if (lower.endsWith('al')) {
    return '${w.substring(0, w.length - 2)}aux';
  }
  if (lower.endsWith('eau') || lower.endsWith('au') || lower.endsWith('eu')) {
    return '${w}x';
  }
  return '${w}s';
}
