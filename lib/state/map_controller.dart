// lib/state/map_controller.dart
import 'package:flutter_riverpod/legacy.dart';

import '../domain/use_cases/client_status.dart';

/// Statuses currently visible on the map. Default: all four.
final mapVisibleStatusesProvider = StateProvider<Set<ClientStatus>>(
  (_) => ClientStatus.values.toSet(),
);

/// Live search query for the map's search bar (debounced upstream).
final mapSearchQueryProvider = StateProvider<String>((_) => '');

/// id of the client whose pin popup is currently open. `null` = no popup.
final mapSelectedClientIdProvider = StateProvider<int?>((_) => null);
