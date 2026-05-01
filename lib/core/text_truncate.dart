// lib/core/text_truncate.dart

/// Tronque un texte pour preview (notes d'historique, descriptions courtes
/// dans une liste, etc.). Bulletproof : ne dépend pas du layout — Flutter
/// `Text(maxLines, overflow: ellipsis)` est unreliable dans certains
/// `Row > Expanded`.
///
/// - Whitespace consécutifs (incl. newlines) compactés en un espace.
/// - Coupe sur la dernière espace si possible (pas au milieu d'un mot).
/// - Ajoute `…` si tronqué.
String truncateForPreview(String s, {int maxChars = 100}) {
  final flat = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (flat.length <= maxChars) return flat;
  final cut = flat.substring(0, maxChars);
  final lastSpace = cut.lastIndexOf(' ');
  final base = lastSpace > maxChars ~/ 2 ? cut.substring(0, lastSpace) : cut;
  return '$base…';
}
