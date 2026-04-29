/// Read-model returned by ClientRepository.listInterventionsForClient.
///
/// Each row is derived from a completed tour_stop: the date comes from
/// `tour.plannedDate`, counts and note from the stop. For tour_stops
/// completed before schemaVersion 6 (no `actual_*` columns yet), the
/// repository falls back to the planned snapshots and sets
/// `hasBilan = false` so the UI can mark the line as "planifié, pas de bilan".
class Intervention {
  final int tourId;
  final int stopId;
  final DateTime date;
  final int small;
  final int large;
  final String? note;
  final bool hasBilan;

  const Intervention({
    required this.tourId,
    required this.stopId,
    required this.date,
    required this.small,
    required this.large,
    required this.hasBilan,
    this.note,
  });

  int get total => small + large;
}
