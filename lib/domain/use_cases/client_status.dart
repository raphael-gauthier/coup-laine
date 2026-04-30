import '../models/client.dart';

/// Effective status used to color the client on the map and to drive
/// status-aware UI (badges, filters, list chips).
///
/// Values are declared in natural lifecycle / display order
/// (default → waiting → scheduled → done → noAnimals → banned), which is
/// the order chips and layer toggles render in.
///
/// Derivation priority (highest first, see [deriveStatus]):
///   banned > noAnimals > scheduled > done > waiting > defaultStatus.
///
/// `scheduled` outranks `done` so that a client with an upcoming planned
/// tour stays surfaced as actionable even if a past completion (real or
/// backfilled via a manual history entry) also lands inside the season.
enum ClientStatus {
  defaultStatus,
  waiting,
  scheduled,
  done,
  noAnimals,
  banned,
}

/// Pure derivation. The two booleans are computed by the repository from
/// the client's `tour_stop` rows joined to `tours` filtered by the current
/// season epoch (and, for completion, also from manual history entries).
ClientStatus deriveStatus(
  Client c, {
  required bool hasCompletedTourThisSeason,
  required bool hasPlannedTourThisSeason,
}) {
  if (c.isBanned) return ClientStatus.banned;
  if (c.animalsTotal == 0) return ClientStatus.noAnimals;
  if (hasPlannedTourThisSeason) return ClientStatus.scheduled;
  if (hasCompletedTourThisSeason) return ClientStatus.done;
  if (c.isWaiting) return ClientStatus.waiting;
  return ClientStatus.defaultStatus;
}
