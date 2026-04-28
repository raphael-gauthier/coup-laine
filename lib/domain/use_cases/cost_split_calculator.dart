import 'bracket_counter.dart';

class CostSplitResult {
  final int totalFeeCents;
  final int feeFarthestCents;
  final int feeInterCents;
  final List<int> shareCents;

  const CostSplitResult({
    required this.totalFeeCents,
    required this.feeFarthestCents,
    required this.feeInterCents,
    required this.shareCents,
  });
}

class CostSplitCalculator {
  final BracketCounter brackets;

  const CostSplitCalculator({required this.brackets});

  /// [baseToStopMeters]: distance from base to each stop, in visit order.
  /// [interStopMeters]: distances between consecutive stops; length = n - 1.
  CostSplitResult split({
    required List<int> baseToStopMeters,
    required List<int> interStopMeters,
  }) {
    final n = baseToStopMeters.length;
    if (n == 0) {
      throw ArgumentError('Cannot split fee for an empty tour');
    }
    if (interStopMeters.length != n - 1) {
      throw ArgumentError(
        'interStopMeters must have length n - 1 (got '
        '${interStopMeters.length}, expected ${n - 1})',
      );
    }

    final farthestMeters =
        baseToStopMeters.reduce((a, b) => a > b ? a : b);
    final interTotalMeters =
        interStopMeters.fold<int>(0, (sum, d) => sum + d);

    final feeFarthestCents = brackets.feeCentsFor(farthestMeters);
    final feeInterCents = brackets.feeCentsFor(interTotalMeters);
    final totalFeeCents = feeFarthestCents + feeInterCents;

    final base = totalFeeCents ~/ n;
    final remainder = totalFeeCents % n;
    final shares = List<int>.generate(
      n,
      (i) => i < remainder ? base + 1 : base,
    );

    return CostSplitResult(
      totalFeeCents: totalFeeCents,
      feeFarthestCents: feeFarthestCents,
      feeInterCents: feeInterCents,
      shareCents: shares,
    );
  }
}
