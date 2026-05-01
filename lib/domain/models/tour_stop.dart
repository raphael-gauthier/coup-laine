import 'tour_stop_prestation.dart';

class TourStop {
  final int id;
  final int tourId;
  final int? clientId;
  final String clientNameSnapshot;
  final int orderIndex;
  final int estimatedArrivalMinutes;
  final int estimatedDepartureMinutes;
  final List<TourStopPrestation> plannedPrestations;
  final List<TourStopPrestation>? actualPrestations;
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
    required this.plannedPrestations,
    this.actualPrestations,
    this.interventionNote,
    required this.feeShareCents,
  });
}
