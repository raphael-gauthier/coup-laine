import 'tour_stop_animal.dart';

class TourStop {
  final int id;
  final int tourId;
  final int? clientId;
  final String clientNameSnapshot;
  final int orderIndex;
  final int estimatedArrivalMinutes;
  final int estimatedDepartureMinutes;
  final List<TourStopAnimal> planned;
  final List<TourStopAnimal>? actual;
  final String? interventionNote;
  final int feeShareCents;

  const TourStop({
    required this.id,
    required this.tourId,
    required this.clientId,
    required this.clientNameSnapshot,
    required this.orderIndex,
    required this.estimatedArrivalMinutes,
    required this.estimatedDepartureMinutes,
    required this.planned,
    this.actual,
    this.interventionNote,
    required this.feeShareCents,
  });
}
