import 'tour_stop_prestation.dart';

/// Read-model returned by ClientRepository.listInterventionsForClient.
///
/// Two sources merge into a single list:
/// - `kind == InterventionKind.tour` — derived from a completed tour_stop.
///   `tourId` and `stopId` are non-null; `manualEntryId` is null.
///   `hasBilan` reflects whether `actualPrestations` were captured (else it's a
///   pre-bilan row falling back to planned snapshots).
/// - `kind == InterventionKind.manual` — a row in `manual_history_entries`.
///   `manualEntryId` is non-null; `tourId`/`stopId` are null.
///   `hasBilan` is always true (the user typed it in).
enum InterventionKind { tour, manual }

class Intervention {
  final InterventionKind kind;
  final int? tourId;
  final int? stopId;
  final int? manualEntryId;
  final DateTime date;
  final List<TourStopPrestation> prestations;
  final String? note;
  final bool hasBilan;

  const Intervention({
    required this.kind,
    required this.date,
    required this.prestations,
    required this.hasBilan,
    this.tourId,
    this.stopId,
    this.manualEntryId,
    this.note,
  });

  /// Sum of qty over all prestations (used for compact display only).
  int get prestationsQtyTotal {
    var total = 0;
    for (final p in prestations) {
      total += p.qty;
    }
    return total;
  }

  /// Sum of priceCentsSnapshot × qty.
  int get totalRevenueCents {
    var total = 0;
    for (final p in prestations) {
      total += p.priceCentsSnapshot * p.qty;
    }
    return total;
  }

  /// Sum of minutesSnapshot × qty.
  int get totalMinutes {
    var total = 0;
    for (final p in prestations) {
      total += p.minutesSnapshot * p.qty;
    }
    return total;
  }
}
