import '../models/client.dart';
import '../models/coordinates.dart';
import '../models/distance_matrix_entry.dart';
import '../models/settings.dart';
import 'build_tour_draft.dart';

class OptimizedProposal {
  final List<int> selectedClientIds; // already in optimal order
  final int estimatedDurationMinutes;
  final bool isUnderTarget;
  final bool isOverTarget;

  const OptimizedProposal({
    required this.selectedClientIds,
    required this.estimatedDurationMinutes,
    required this.isUnderTarget,
    required this.isOverTarget,
  });

  factory OptimizedProposal.empty() => const OptimizedProposal(
        selectedClientIds: [],
        estimatedDurationMinutes: 0,
        isUnderTarget: false,
        isOverTarget: false,
      );
}

class BuildOptimizedTourProposal {
  static const int toleranceMinutes = 30;

  const BuildOptimizedTourProposal();

  OptimizedProposal call({
    required String communeName,
    required int targetMinutes,
    required int startTimeMinutes,
    required List<Client> waitingClients,
    required List<DistanceMatrixEntry> matrix,
    required Settings settings,
  }) {
    final eligible = waitingClients
        .where((c) => !c.needsDistanceRecompute)
        .toList();
    final byId = {for (final c in eligible) c.id: c};
    final seedIds = eligible
        .where((c) => c.city == communeName)
        .map((c) => c.id)
        .toList();
    if (seedIds.isEmpty) return OptimizedProposal.empty();

    var current = List<int>.from(seedIds);
    var draft = _buildDraft(
      candidateIds: current,
      candidates: eligible,
      matrix: matrix,
      settings: settings,
      startTimeMinutes: startTimeMinutes,
    );
    var duration = draft.endTimeMinutes - startTimeMinutes;

    // Compute barycentre of the seed for distance tie-breaking.
    final bary = _barycentre([for (final id in seedIds) byId[id]!.coordinates]);

    if (duration < targetMinutes - toleranceMinutes) {
      // EXTENSION
      final extras = eligible
          .where((c) => c.city != communeName && !seedIds.contains(c.id))
          .toList()
        ..sort((a, b) => _distSq(a.coordinates, bary)
            .compareTo(_distSq(b.coordinates, bary)));
      for (final cand in extras) {
        final next = [...current, cand.id];
        final nextDraft = _buildDraft(
          candidateIds: next,
          candidates: eligible,
          matrix: matrix,
          settings: settings,
          startTimeMinutes: startTimeMinutes,
        );
        final nextDuration = nextDraft.endTimeMinutes - startTimeMinutes;
        if (nextDuration > targetMinutes + toleranceMinutes) break;
        current = nextDraft.orderedClientIds;
        draft = nextDraft;
        duration = nextDuration;
      }
    } else if (duration > targetMinutes + toleranceMinutes) {
      // CONTRACTION
      while (current.length > 1 &&
          duration > targetMinutes + toleranceMinutes) {
        // Remove the candidate farthest from the barycentre.
        var farthestId = current.first;
        var farthestDistSq = -1.0;
        for (final id in current) {
          final d = _distSq(byId[id]!.coordinates, bary);
          if (d > farthestDistSq) {
            farthestDistSq = d;
            farthestId = id;
          }
        }
        final next = current.where((id) => id != farthestId).toList();
        final nextDraft = _buildDraft(
          candidateIds: next,
          candidates: eligible,
          matrix: matrix,
          settings: settings,
          startTimeMinutes: startTimeMinutes,
        );
        current = nextDraft.orderedClientIds;
        draft = nextDraft;
        duration = nextDraft.endTimeMinutes - startTimeMinutes;
      }
    }

    return OptimizedProposal(
      selectedClientIds: current,
      estimatedDurationMinutes: duration,
      isUnderTarget: duration < targetMinutes - toleranceMinutes,
      isOverTarget: duration > targetMinutes + toleranceMinutes,
    );
  }

  TourDraftResult _buildDraft({
    required List<int> candidateIds,
    required List<Client> candidates,
    required List<DistanceMatrixEntry> matrix,
    required Settings settings,
    required int startTimeMinutes,
  }) {
    return const BuildTourDraft().build(
      candidateIds: candidateIds,
      candidates: candidates,
      matrix: matrix,
      settings: settings,
      startTimeMinutes: startTimeMinutes,
    );
  }

  Coordinates _barycentre(List<Coordinates> points) {
    var lat = 0.0;
    var lon = 0.0;
    for (final p in points) {
      lat += p.lat;
      lon += p.lon;
    }
    final n = points.length;
    return Coordinates(lat: lat / n, lon: lon / n);
  }

  double _distSq(Coordinates a, Coordinates b) {
    final dLat = a.lat - b.lat;
    final dLon = a.lon - b.lon;
    return dLat * dLat + dLon * dLon;
  }
}
