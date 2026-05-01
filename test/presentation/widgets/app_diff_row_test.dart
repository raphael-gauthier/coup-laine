// test/presentation/widgets/app_diff_row_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/presentation/widgets/app_diff_row.dart';

void main() {
  group('AppDiffRow.computeDelta', () {
    test('égal → DiffStatus.same, delta 0', () {
      final r = AppDiffRow.computeDelta(planned: 3, actual: 3);
      expect(r.status, DiffStatus.same);
      expect(r.delta, 0);
    });

    test('actual > planned → DiffStatus.up, delta positif', () {
      final r = AppDiffRow.computeDelta(planned: 2, actual: 3);
      expect(r.status, DiffStatus.up);
      expect(r.delta, 1);
    });

    test('actual < planned → DiffStatus.down, delta négatif', () {
      final r = AppDiffRow.computeDelta(planned: 5, actual: 4);
      expect(r.status, DiffStatus.down);
      expect(r.delta, -1);
    });

    test('hors-plan (planned == 0, actual > 0) → DiffStatus.bonus', () {
      final r = AppDiffRow.computeDelta(planned: 0, actual: 2);
      expect(r.status, DiffStatus.bonus);
      expect(r.delta, 2);
    });
  });
}
