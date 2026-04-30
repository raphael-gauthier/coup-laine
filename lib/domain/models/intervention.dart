/// Read-model returned by ClientRepository.listInterventionsForClient.
///
/// Two sources merge into a single list:
/// - `kind == InterventionKind.tour` — derived from a completed tour_stop.
///   `tourId` and `stopId` are non-null; `manualEntryId` is null.
///   `hasBilan` reflects whether `actual_*` were captured (else it's a
///   pre-v6 row falling back to planned snapshots).
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
  final int small;
  final int large;
  final String? note;
  final bool hasBilan;

  const Intervention({
    required this.kind,
    required this.date,
    required this.small,
    required this.large,
    required this.hasBilan,
    this.tourId,
    this.stopId,
    this.manualEntryId,
    this.note,
  });

  int get total => small + large;
}
