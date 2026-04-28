import '../models/client.dart';

/// A derived status used to color the client on the map and to drive
/// status-aware UI (badges, filters).
enum ClientStatus { defaultStatus, waiting, overdue, recompute }

/// 13-month rule: a client whose last shearing was more than this many
/// days ago is "overdue".
const int kOverdueThresholdDays = 395;

extension ClientStatusX on Client {
  ClientStatus get status {
    if (needsDistanceRecompute) return ClientStatus.recompute;
    if (isWaiting) return ClientStatus.waiting;
    final last = lastShearingDate;
    if (last != null &&
        DateTime.now().difference(last).inDays > kOverdueThresholdDays) {
      return ClientStatus.overdue;
    }
    return ClientStatus.defaultStatus;
  }
}
