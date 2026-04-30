import 'package:coup_laine/core/phone_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizePhones', () {
    test('trims each entry', () {
      expect(normalizePhones(['  06 12  ', '0145']), ['06 12', '0145']);
    });

    test('drops empty and whitespace-only entries', () {
      expect(normalizePhones(['', '   ', '0612', '\t']), ['0612']);
    });

    test('drops duplicates, keeping the first occurrence (stable)', () {
      expect(
        normalizePhones(['0612', '0145', '0612', '0788']),
        ['0612', '0145', '0788'],
      );
    });

    test('treats post-trim duplicates as duplicates', () {
      expect(normalizePhones(['  0612  ', '0612']), ['0612']);
    });

    test('treats whitespace-only formatting differences as duplicates', () {
      expect(normalizePhones(['06 12', '0612']), ['06 12']);
    });

    test('matches the spec example end-to-end', () {
      expect(
        normalizePhones(['  06 12  ', '', '0612', '0145']),
        ['06 12', '0145'],
      );
    });

    test('preserves order of distinct entries', () {
      expect(
        normalizePhones(['C', 'A', 'B']),
        ['C', 'A', 'B'],
      );
    });

    test('returns empty for an empty input', () {
      expect(normalizePhones(<String>[]), <String>[]);
    });
  });
}
