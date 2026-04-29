import '../models/client.dart';

/// Effective status used to color the client on the map and to drive
/// status-aware UI (badges, filters, list chips).
///
/// Values are declared in natural lifecycle / display order
/// (default → waiting → scheduled → done → noSheep → banned), which is
/// the order chips and layer toggles render in.
///
/// Derivation priority (highest first, see [deriveStatus]):
///   banned > noSheep > done > scheduled > waiting > defaultStatus.
enum ClientStatus {
  defaultStatus,
  waiting,
  scheduled,
  done,
  noSheep,
  banned,
}

/// Pure derivation. The two booleans are computed by the repository from
/// the client's `tour_stop` rows joined to `tours` filtered by the current
/// season epoch.
ClientStatus deriveStatus(
  Client c, {
  required bool hasCompletedTourThisSeason,
  required bool hasPlannedTourThisSeason,
}) {
  if (c.isBanned) return ClientStatus.banned;
  if (c.sheepCountSmall == 0 && c.sheepCountLarge == 0) {
    return ClientStatus.noSheep;
  }
  if (hasCompletedTourThisSeason) return ClientStatus.done;
  if (hasPlannedTourThisSeason) return ClientStatus.scheduled;
  if (c.isWaiting) return ClientStatus.waiting;
  return ClientStatus.defaultStatus;
}
