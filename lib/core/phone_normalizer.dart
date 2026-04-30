/// Cleans up a list of phone numbers before persistence:
///   - trims each entry,
///   - drops entries that are empty after trimming,
///   - removes duplicates while preserving the order of first occurrences.
///
/// Used by [ClientRepository] on every write so the stored list stays
/// canonical (no leading/trailing whitespace, no blanks, no dupes).
List<String> normalizePhones(List<String> input) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in input) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    if (seen.add(trimmed)) out.add(trimmed);
  }
  return out;
}
