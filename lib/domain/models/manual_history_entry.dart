import 'tour_stop_animal.dart';

class ManualHistoryEntry {
  final int id;
  final int clientId;
  final DateTime date;
  final List<TourStopAnimal> animals;
  final String? note;

  const ManualHistoryEntry({
    required this.id,
    required this.clientId,
    required this.date,
    required this.animals,
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
