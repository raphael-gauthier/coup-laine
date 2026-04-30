import '../domain/models/client.dart';

/// Lower-cases and strips French diacritics from [s].
///
/// Used for both substring matching (search bars) and locale-rough sorting
/// (alphabetical by city / name). Not a full Unicode-normaliser — only
/// covers the latin letters that show up in our address book.
String normalize(String s) {
  const tr = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ÿ': 'y',
  };
  final lower = s.toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.runes) {
    final c = String.fromCharCode(ch);
    buf.write(tr[c] ?? c);
  }
  return buf.toString();
}

/// Returns true if [normalizedQuery] (already passed through [normalize])
/// matches any of the client's searchable fields: name, phones, city,
/// postcode, full address — plus any string in [extraFields] (used to
/// fold in history-entry notes).
///
/// An empty query always matches.
bool matchesClient(
  Client c,
  String normalizedQuery, {
  Iterable<String> extraFields = const [],
}) {
  if (normalizedQuery.isEmpty) return true;
  final fields = [
    c.name,
    c.phones.join(' '),
    c.city,
    c.postcode,
    c.addressLabel,
    ...extraFields,
  ];
  for (final f in fields) {
    if (normalize(f).contains(normalizedQuery)) return true;
  }
  return false;
}
