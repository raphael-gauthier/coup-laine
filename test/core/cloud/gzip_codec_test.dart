import 'dart:convert';

import 'package:coup_laine/core/cloud/gzip_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trip preserves arbitrary string', () {
    const sample = '{"clients":[{"name":"Marius"}]}';
    final compressed = gzipString(sample);
    expect(compressed, isNot(equals(utf8.encode(sample))));
    final restored = gunzipString(compressed);
    expect(restored, equals(sample));
  });

  test('compression reduces size for repetitive payload', () {
    final big = '{"a":${'x' * 5000}}';
    final compressed = gzipString(big);
    expect(compressed.length, lessThan(utf8.encode(big).length ~/ 5));
  });

  test('gunzipString throws FormatException on garbage input', () {
    expect(
      () => gunzipString(utf8.encode('not gzipped at all')),
      throwsA(isA<FormatException>()),
    );
  });
}
