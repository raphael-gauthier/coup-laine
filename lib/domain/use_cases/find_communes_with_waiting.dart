import '../models/client.dart';
import 'client_status.dart';

typedef CommuneWithWaiting = ({String name, int count});

class FindCommunesWithWaiting {
  const FindCommunesWithWaiting();

  List<CommuneWithWaiting> call({
    required List<Client> clients,
    required Map<int, ClientStatus> statusByClientId,
  }) {
    final counts = <String, int>{};
    for (final c in clients) {
      if (c.needsDistanceRecompute) continue;
      if (statusByClientId[c.id] != ClientStatus.waiting) continue;
      counts[c.city] = (counts[c.city] ?? 0) + 1;
    }
    final entries = counts.entries
        .map((e) => (name: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return entries;
  }
}
