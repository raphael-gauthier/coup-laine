/// Cleans up a list of phone numbers before persistence:
///   - trims each entry,
///   - drops entries that are empty after trimming,
///   - removes duplicates while preserving the order of first occurrences.
///     Deduplication ignores internal whitespace (e.g. "06 12" and "0612"
///     are considered the same number).
///
/// Used by [ClientRepository] on every write so the stored list stays
/// canonical (no leading/trailing whitespace, no blanks, no dupes).
List<String> normalizePhones(List<String> input) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in input) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    final key = trimmed.replaceAll(RegExp(r'\s+'), '');
    if (seen.add(key)) out.add(trimmed);
  }
  return out;
}
