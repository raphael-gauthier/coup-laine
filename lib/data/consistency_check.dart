import 'package:drift/drift.dart';

import 'repositories/client_repository.dart';
import '../infra/db/app_database.dart';

class ConsistencyCheck {
  final AppDatabase db;
  final ClientRepository clients;
  ConsistencyCheck({required this.db, required this.clients});

  Future<int> run() async {
    final allClients = await clients.listAll();
    final n = allClients.length;
    if (n == 0) return 0;
    var fixed = 0;
    for (final c in allClients) {
      if (c.needsDistanceRecompute) continue;
      final result = await db.customSelect(
        'SELECT COUNT(*) AS c FROM distance_matrix '
        'WHERE from_id = ? OR to_id = ?',
        variables: [Variable.withInt(c.id), Variable.withInt(c.id)],
        readsFrom: {db.distanceMatrixTable},
      ).getSingle();
      final rows = result.data['c'] as int;
      // Each client should have 2 * n rows (out + in for base + n-1 others).
      // Off-by-one tolerated: simply require >= 2*(n-1).
      if (rows < 2 * (n - 1)) {
        await clients.setRecomputePending(c.id);
        fixed++;
      }
    }
    return fixed;
  }
}
