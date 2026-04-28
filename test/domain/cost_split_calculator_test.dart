import 'package:coupe_laine/domain/use_cases/bracket_counter.dart';
import 'package:coupe_laine/domain/use_cases/cost_split_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const counter = BracketCounter(bracketKm: 10, feeEurosPerBracket: 8);
  final calculator = CostSplitCalculator(brackets: counter);

  group('CostSplitCalculator', () {
    test('single stop: full fee on the only client', () {
      final result = calculator.split(
        baseToStopMeters: const [25000],
        interStopMeters: const [],
      );
      expect(result.totalFeeCents, 2400);
      expect(result.shareCents, [2400]);
    });

    test('three stops: spec example (25 km farthest, 13 km inter)', () {
      final result = calculator.split(
        baseToStopMeters: const [15000, 22000, 25000],
        interStopMeters: const [5000, 8000],
      );
      // farthest = 25 km → 3 brackets → 24 €
      // inter = 13 km → 2 brackets → 16 €
      // total = 40 €
      expect(result.totalFeeCents, 4000);
      // 4000 / 3 = 1333 remainder 1 → first stop gets +1
      expect(result.shareCents, [1334, 1333, 1333]);
      expect(result.shareCents.reduce((a, b) => a + b), 4000);
    });

    test('shares always sum to total exactly', () {
      final result = calculator.split(
        baseToStopMeters: const [10001, 10000, 10000, 10000, 10000],
        interStopMeters: const [1, 1, 1, 1],
      );
      expect(
        result.shareCents.reduce((a, b) => a + b),
        result.totalFeeCents,
      );
    });

    test('zero stops throws', () {
      expect(
        () => calculator.split(
          baseToStopMeters: const [],
          interStopMeters: const [],
        ),
        throwsArgumentError,
      );
    });
  });
}
