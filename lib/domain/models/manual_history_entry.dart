import 'tour_stop_prestation.dart';

class ManualHistoryEntry {
  final int id;
  final int clientId;
  final DateTime date;
  final List<TourStopPrestation> prestations;
  final String? note;

  const ManualHistoryEntry({
    required this.id,
    required this.clientId,
    required this.date,
    required this.prestations,
    this.note,
  });

  int get prestationsQtyTotal {
    var total = 0;
    for (final p in prestations) {
      total += p.qty;
    }
    return total;
  }
}
