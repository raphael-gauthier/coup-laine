import 'tour_stop_animal.dart';

/// Read-model returned by ClientRepository.listInterventionsForClient.
///
/// Two sources merge into a single list:
/// - `kind == InterventionKind.tour` — derived from a completed tour_stop.
///   `tourId` and `stopId` are non-null; `manualEntryId` is null.
///   `hasBilan` reflects whether `actualAnimals` were captured (else it's a
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
  final List<TourStopAnimal> animals;
  final String? note;
  final bool hasBilan;

  const Intervention({
    required this.kind,
    required this.date,
    required this.animals,
    required this.hasBilan,
    this.tourId,
    this.stopId,
    this.manualEntryId,
    this.note,
  });

  int get animalsTotal {
    var total = 0;
    for (final a in animals) {
      total += a.count;
    }
    return total;
  }
}
