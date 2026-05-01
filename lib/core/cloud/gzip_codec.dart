import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Compresse une chaîne UTF-8 en gzip.
Uint8List gzipString(String input) {
  final bytes = utf8.encode(input);
  return const GZipEncoder().encodeBytes(bytes);
}

/// Décompresse un blob gzip et retourne la chaîne UTF-8 originale.
/// Lance [FormatException] si le blob n'est pas un gzip valide.
String gunzipString(List<int> input) {
  try {
    final decoded = const GZipDecoder().decodeBytes(input);
    return utf8.decode(decoded);
  } catch (e) {
    throw FormatException('Invalid gzip payload: $e');
  }
}
