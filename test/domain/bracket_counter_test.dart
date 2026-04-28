import 'package:coup_laine/domain/use_cases/bracket_counter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BracketCounter (10 km, 8 €)', () {
    final counter = const BracketCounter(bracketKm: 10, feeEurosPerBracket: 8);

    test('zero metres → zero brackets, zero euros', () {
      expect(counter.bracketsFor(0), 0);
      expect(counter.feeCentsFor(0), 0);
    });

    test('1 metre → 1 bracket → 8 €', () {
      expect(counter.bracketsFor(1), 1);
      expect(counter.feeCentsFor(1), 800);
    });

    test('exactly 10 000 metres → 1 bracket', () {
      expect(counter.bracketsFor(10000), 1);
      expect(counter.feeCentsFor(10000), 800);
    });

    test('10 001 metres → 2 brackets → 16 €', () {
      expect(counter.bracketsFor(10001), 2);
      expect(counter.feeCentsFor(10001), 1600);
    });

    test('25 km → 3 brackets → 24 €', () {
      expect(counter.feeCentsFor(25000), 2400);
    });
  });
}
