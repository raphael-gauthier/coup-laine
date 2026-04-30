// lib/state/map_controller.dart
import 'package:flutter_riverpod/legacy.dart';

import '../domain/use_cases/client_status.dart';

/// Statuses currently visible on the map. Default: all six.
final mapVisibleStatusesProvider = StateProvider<Set<ClientStatus>>(
  (_) => ClientStatus.values.toSet(),
);

/// Live search query for the map's search bar (debounced upstream).
final mapSearchQueryProvider = StateProvider<String>((_) => '');

/// id of the client whose pin popup is currently open. `null` = no popup.
final mapSelectedClientIdProvider = StateProvider<int?>((_) => null);

/// One-shot client id that, when set, makes the map fly to that client on
/// its next build and clear the value. Used by external screens (e.g. the
/// tour detail) to request "focus this client on the map" navigation.
final mapPendingFocusProvider = StateProvider<int?>((_) => null);
