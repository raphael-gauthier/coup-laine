import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/intervention.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';
import 'package:coup_laine/state/providers/client_kpis.dart';

Intervention _interv({
  required DateTime date,
  required InterventionKind kind,
  List<TourStopPrestation>? prestations,
}) =>
    Intervention(
      date: date,
      kind: kind,
      prestations: prestations ?? const [],
      tourId: kind == InterventionKind.tour ? 1 : null,
      manualEntryId: kind == InterventionKind.manual ? 1 : null,
      hasBilan: true,
    );

TourStopPrestation _row(int qty, int priceCents) => TourStopPrestation(
      prestationId: 1,
      qty: qty,
      nameSnapshot: 'X',
      priceCentsSnapshot: priceCents,
      minutesSnapshot: 0,
      categoryIdSnapshot: null,
      categoryNameSnapshot: null,
      speciesNameSnapshot: null,
    );

void main() {
  group('computeClientKpis', () {
    test('liste vide → 0 interventions, revenue 0, lastDate null', () {
      final k = computeClientKpis([]);
      expect(k.interventionCount, 0);
      expect(k.totalRevenueCents, 0);
      expect(k.lastInterventionDate, isNull);
      expect(k.firstInterventionDate, isNull);
    });

    test('count = nombre d\'interventions', () {
      final k = computeClientKpis([
        _interv(date: DateTime(2025, 9, 3), kind: InterventionKind.tour),
        _interv(date: DateTime(2024, 9, 1), kind: InterventionKind.tour),
        _interv(date: DateTime(2025, 5, 18), kind: InterventionKind.manual),
      ]);
      expect(k.interventionCount, 3);
    });

    test('revenue = somme priceCentsSnapshot × qty sur toutes prestations', () {
      final k = computeClientKpis([
        _interv(
          date: DateTime(2025, 9, 3),
          kind: InterventionKind.tour,
          prestations: [_row(3, 6000), _row(1, 4000)],
        ),
        _interv(
          date: DateTime(2024, 9, 1),
          kind: InterventionKind.tour,
          prestations: [_row(2, 5000)],
        ),
      ]);
      expect(k.totalRevenueCents, 3 * 6000 + 1 * 4000 + 2 * 5000);
    });

    test('lastInterventionDate = max ; firstInterventionDate = min', () {
      final k = computeClientKpis([
        _interv(date: DateTime(2025, 9, 3), kind: InterventionKind.tour),
        _interv(date: DateTime(2024, 9, 1), kind: InterventionKind.tour),
        _interv(date: DateTime(2025, 5, 18), kind: InterventionKind.manual),
      ]);
      expect(k.lastInterventionDate, DateTime(2025, 9, 3));
      expect(k.firstInterventionDate, DateTime(2024, 9, 1));
    });
  });
}
