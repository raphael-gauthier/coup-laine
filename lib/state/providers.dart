import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../core/config/env.dart';
import '../core/routing/app_router.dart';
import '../data/consistency_check.dart';
import '../data/distance_matrix_sync.dart';
import '../data/repositories/client_repository.dart';
import '../data/repositories/distance_matrix_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/tour_repository.dart';
import '../domain/models/client.dart';
import '../domain/models/settings.dart';
import '../domain/use_cases/client_status.dart';
import '../infra/db/app_database.dart';
import '../infra/services/ban_geocoding_service.dart';
import '../infra/services/json_export_service.dart';
import '../infra/services/ors_routing_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(ref.watch(appDatabaseProvider));
});

final distanceMatrixRepositoryProvider =
    Provider<DistanceMatrixRepository>((ref) {
  return DistanceMatrixRepository(ref.watch(appDatabaseProvider));
});

final tourRepositoryProvider = Provider<TourRepository>((ref) {
  return TourRepository(ref.watch(appDatabaseProvider));
});

final banGeocodingServiceProvider = Provider<BanGeocodingService>((ref) {
  return BanGeocodingService(httpClient: ref.watch(httpClientProvider));
});

final orsRoutingServiceProvider = Provider<OrsRoutingService>((ref) {
  return OrsRoutingService(
    apiKey: Env.orsApiKey,
    httpClient: ref.watch(httpClientProvider),
  );
});

final distanceMatrixSyncProvider = Provider<DistanceMatrixSync>((ref) {
  return DistanceMatrixSync(
    clients: ref.watch(clientRepositoryProvider),
    matrix: ref.watch(distanceMatrixRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    ors: ref.watch(orsRoutingServiceProvider),
  );
});

final consistencyCheckProvider = Provider<ConsistencyCheck>((ref) {
  return ConsistencyCheck(
    db: ref.watch(appDatabaseProvider),
    clients: ref.watch(clientRepositoryProvider),
  );
});

final jsonExportServiceProvider = Provider<JsonExportService>((ref) {
  return JsonExportService(
    database: ref.watch(appDatabaseProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clients: ref.watch(clientRepositoryProvider),
    matrix: ref.watch(distanceMatrixRepositoryProvider),
    tours: ref.watch(tourRepositoryProvider),
  );
});

final goRouterProvider = Provider<GoRouter>((ref) => AppRouter.forRef(ref));

final themeModeProvider = FutureProvider<ThemeMode>((ref) async {
  final s = await ref.watch(settingsRepositoryProvider).read();
  if (s == null) return ThemeMode.system;
  return switch (s.themeMode) {
    ThemeModePreference.light => ThemeMode.light,
    ThemeModePreference.dark => ThemeMode.dark,
    ThemeModePreference.system => ThemeMode.system,
  };
});

final waitingPickerCandidatesProvider = FutureProvider.autoDispose<
    ({List<Client> eligible, int excludedCount})>((ref) async {
  final clients = ref.watch(clientRepositoryProvider);
  final settings = await ref.watch(settingsRepositoryProvider).read();
  final seasonStart = settings?.seasonStartedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  final withStatus = await clients.listAllWithStatus(seasonStart);
  final waiting = [
    for (final r in withStatus)
      if (r.$2 == ClientStatus.waiting) r.$1,
  ];
  final eligible = waiting.where((c) => !c.needsDistanceRecompute).toList();
  return (
    eligible: eligible,
    excludedCount: waiting.length - eligible.length,
  );
});
