import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../core/config/env.dart';
import '../core/routing/app_router.dart';
import '../data/repositories/client_repository.dart';
import '../data/repositories/distance_matrix_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/tour_repository.dart';
import '../infra/db/app_database.dart';
import '../infra/services/ban_geocoding_service.dart';
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

final goRouterProvider = Provider<GoRouter>((ref) => AppRouter.forRef(ref));
