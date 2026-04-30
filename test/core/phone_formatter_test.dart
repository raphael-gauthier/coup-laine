import 'package:coup_laine/core/phone_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPhoneInput — domestic French', () {
    test('groups 10 digits as 5 pairs', () {
      expect(formatPhoneInput('0612345678'), '06 12 34 56 78');
    });

    test('groups partial input as it is typed', () {
      expect(formatPhoneInput('0'), '0');
      expect(formatPhoneInput('06'), '06');
      expect(formatPhoneInput('061'), '06 1');
      expect(formatPhoneInput('0612'), '06 12');
      expect(formatPhoneInput('06123'), '06 12 3');
    });

    test('strips existing spaces and re-groups (idempotent)', () {
      expect(formatPhoneInput('06 12 34 56 78'), '06 12 34 56 78');
    });

    test('strips dots, dashes, parens', () {
      expect(formatPhoneInput('06.12.34.56.78'), '06 12 34 56 78');
      expect(formatPhoneInput('06-12-34-56-78'), '06 12 34 56 78');
      expect(formatPhoneInput('(06) 12 34 56 78'), '06 12 34 56 78');
    });

    test('returns empty for empty input', () {
      expect(formatPhoneInput(''), '');
    });

    test('returns empty when input has no digits', () {
      expect(formatPhoneInput('abc'), '');
      expect(formatPhoneInput('   '), '');
    });

    test('caps at 10 digits — extras are dropped', () {
      expect(formatPhoneInput('06123456789'), '06 12 34 56 78');
      expect(formatPhoneInput('061234567890123'), '06 12 34 56 78');
    });
  });

  group('formatPhoneInput — international (starts with +)', () {
    test('formats French international as +33 6 12 34 56 78', () {
      expect(formatPhoneInput('+33612345678'), '+33 6 12 34 56 78');
    });

    test('formats partial international input', () {
      expect(formatPhoneInput('+'), '+');
      expect(formatPhoneInput('+3'), '+3');
      expect(formatPhoneInput('+33'), '+33');
      expect(formatPhoneInput('+336'), '+33 6');
      expect(formatPhoneInput('+3361'), '+33 61');
      expect(formatPhoneInput('+33612'), '+33 6 12');
    });

    test('idempotent on already-formatted international input', () {
      expect(formatPhoneInput('+33 6 12 34 56 78'), '+33 6 12 34 56 78');
    });

    test('strips dots and other separators in international input', () {
      expect(formatPhoneInput('+33.6.12.34.56.78'), '+33 6 12 34 56 78');
    });

    test('keeps + alone if user just typed plus', () {
      expect(formatPhoneInput('+'), '+');
    });

    test('caps at 11 digits after the + (max 12 chars total)', () {
      expect(formatPhoneInput('+336123456789'), '+33 6 12 34 56 78');
      expect(formatPhoneInput('+33612345678999'), '+33 6 12 34 56 78');
    });
  });
}
