import 'package:coup_laine/infra/db/phone_list_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const c = PhoneListConverter();

  group('PhoneListConverter.fromSql', () {
    test('decodes "[]" to empty list', () {
      expect(c.fromSql('[]'), <String>[]);
    });

    test('decodes a JSON array of strings preserving order', () {
      expect(c.fromSql('["0612","0145"]'), ['0612', '0145']);
    });
  });

  group('PhoneListConverter.toSql', () {
    test('encodes empty list as "[]"', () {
      expect(c.toSql(const []), '[]');
    });

    test('encodes a list of strings as a JSON array', () {
      expect(c.toSql(const ['0612', '0145']), '["0612","0145"]');
    });
  });

  test('round-trips a non-trivial list unchanged', () {
    final original = ['06 12 34 56 78', '+33 1 45 67 89 00', 'mobile-épouse'];
    expect(c.fromSql(c.toSql(original)), original);
  });
}
