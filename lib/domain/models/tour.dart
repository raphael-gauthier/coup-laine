import 'coordinates.dart';

enum TourStatus { planned, completed }

class Tour {
  final int id;
  final DateTime plannedDate;
  final int startTimeMinutes;
  final TourStatus status;
  final int totalDistanceMeters;
  final int totalDriveSeconds;
  final int totalTravelFeeCents;
  final String? notes;
  final DateTime? completedAt;
  final DateTime createdAt;

  /// Polyline ORS de la tournée (base → stops dans l'ordre → base).
  /// Nullable : si non disponible (réseau au moment de la création, ou
  /// tournée pré-feature), le rendu carte tombe en lignes droites.
  final List<Coordinates>? routeGeometry;

  const Tour({
    required this.id,
    required this.plannedDate,
    required this.startTimeMinutes,
    required this.status,
    required this.totalDistanceMeters,
    required this.totalDriveSeconds,
    required this.totalTravelFeeCents,
    required this.createdAt,
    this.notes,
    this.completedAt,
    this.routeGeometry,
  });
}
