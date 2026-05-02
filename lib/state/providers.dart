import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/routing/app_router.dart';
import '../data/consistency_check.dart';
import '../data/distance_matrix_sync.dart';
import '../data/repositories/animal_category_repository.dart';
import '../data/repositories/client_repository.dart';
import '../data/repositories/distance_matrix_repository.dart';
import '../data/repositories/manual_history_repository.dart';
import '../data/repositories/prestation_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/species_repository.dart';
import '../data/repositories/tour_repository.dart';
import '../domain/models/animal_category.dart';
import '../domain/models/client.dart';
import '../domain/models/distance_matrix_entry.dart';
import '../domain/models/intervention.dart';
import '../domain/models/prestation.dart';
import '../domain/models/settings.dart';
import '../domain/models/species.dart';
import '../domain/use_cases/build_optimized_tour_proposal.dart';
import '../domain/use_cases/client_status.dart';
import '../domain/use_cases/find_clients_near_anchors.dart';
import '../domain/use_cases/find_communes_with_waiting.dart';
import '../infra/cloud/auth_service.dart';
import '../infra/cloud/backup_scheduler.dart';
import '../infra/cloud/backup_service.dart';
import '../infra/cloud/backups_repository.dart';
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

final settingsRepositoryFutureProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(settingsRepositoryProvider).read();
});

final manualHistoryRepositoryProvider =
    Provider<ManualHistoryRepository>((ref) {
  return ManualHistoryRepository(ref.watch(appDatabaseProvider));
});

final speciesRepositoryProvider = Provider<SpeciesRepository>((ref) {
  return SpeciesRepository(ref.watch(appDatabaseProvider));
});

final animalCategoryRepositoryProvider =
    Provider<AnimalCategoryRepository>((ref) {
  return AnimalCategoryRepository(ref.watch(appDatabaseProvider));
});

/// Active species (excludes archived). Watched by the species management
/// screen and the AnimalCountsEditor widget.
final activeSpeciesProvider = FutureProvider<List<Species>>((ref) {
  return ref.watch(speciesRepositoryProvider).listActive();
});

/// Archived species. Watched by the species management screen for the
/// archived section.
final archivedSpeciesProvider = FutureProvider<List<Species>>((ref) {
  return ref.watch(speciesRepositoryProvider).listArchived();
});

/// All categories (active + archived) keyed by id. Used by displays that
/// need to look up snapshot context for archived categories.
final allCategoriesByIdProvider =
    FutureProvider<Map<int, AnimalCategory>>((ref) async {
  final list = await ref.watch(animalCategoryRepositoryProvider).listAll();
  return {for (final c in list) c.id: c};
});

/// For a given category id, returns the species name + category name.
/// Used by widgets that need to display "Mouton/Petit" for an animal counter
/// or a snapshot id reference. Includes archived species/categories so that
/// historical references still resolve.
final categoryDisplayInfoProvider =
    FutureProvider<Map<int, ({String speciesName, String categoryName})>>(
        (ref) async {
  final species = await ref.watch(speciesRepositoryProvider).listAll();
  final speciesById = {for (final s in species) s.id: s};
  final cats = await ref.watch(animalCategoryRepositoryProvider).listAll();
  return {
    for (final c in cats)
      c.id: (
        speciesName: speciesById[c.speciesId]?.name ?? '',
        categoryName: c.name,
      ),
  };
});

/// Active categories grouped by speciesId. Used by AnimalCountsEditor.
final activeCategoriesBySpeciesProvider =
    FutureProvider<Map<int, List<AnimalCategory>>>((ref) async {
  final list =
      await ref.watch(animalCategoryRepositoryProvider).listAllActive();
  final out = <int, List<AnimalCategory>>{};
  for (final c in list) {
    out.putIfAbsent(c.speciesId, () => []).add(c);
  }
  return out;
});

final prestationRepositoryProvider = Provider<PrestationRepository>((ref) {
  return PrestationRepository(ref.watch(appDatabaseProvider));
});

/// Active prestations ordered by id. Used by the catalog screen and the
/// stop picker.
final activePrestationsProvider = FutureProvider<List<Prestation>>((ref) {
  return ref.watch(prestationRepositoryProvider).listActive();
});

/// Archived prestations.
final archivedPrestationsProvider = FutureProvider<List<Prestation>>((ref) {
  return ref.watch(prestationRepositoryProvider).listArchived();
});

/// Active prestations grouped : `categoryId` (or `null` for libres) → list.
/// Convenient for the catalog screen's grouped layout.
final activePrestationsByCategoryProvider =
    FutureProvider<Map<int?, List<Prestation>>>((ref) async {
  final list = await ref.watch(activePrestationsProvider.future);
  final out = <int?, List<Prestation>>{};
  for (final p in list) {
    out.putIfAbsent(p.categoryId, () => []).add(p);
  }
  return out;
});

/// Count of active prestations. Cheap; surfaced in Settings.
final prestationCountActiveProvider = FutureProvider<int>((ref) {
  return ref.watch(prestationRepositoryProvider).countActive();
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(
    ref.watch(appDatabaseProvider),
    manualHistory: ref.watch(manualHistoryRepositoryProvider),
  );
});

final historyForClientProvider =
    FutureProvider.family.autoDispose<List<Intervention>, int>((ref, id) {
  return ref.watch(clientRepositoryProvider).listInterventionsForClient(id);
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
    functions: ref.watch(supabaseClientProvider).functions,
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

final tourByIdProvider =
    FutureProvider.autoDispose.family<TourWithStops?, int>((ref, id) {
  return ref.watch(tourRepositoryProvider).findById(id);
});

/// Distance in meters from the base (id 0) to a given client. Returns null
/// if the matrix entry is missing (e.g., client added but distance not yet
/// recomputed).
final clientDistanceFromBaseProvider =
    FutureProvider.autoDispose.family<int?, int>((ref, clientId) {
  return ref
      .watch(distanceMatrixRepositoryProvider)
      .distanceMeters(from: 0, to: clientId);
});

/// Computes the set of waiting client ids that are routing-close to any of
/// the anchor client ids passed via [key]. The key is a sorted, comma-joined
/// string of anchor ids — Sets / Lists in Dart have identity equality, which
/// would re-trigger the family on every rebuild even when the contents are
/// unchanged. Returns an empty set if settings or any anchor's matrix rows
/// are unavailable.
final nearbyToAnchorsProvider = FutureProvider.autoDispose
    .family<Set<int>, String>((ref, key) async {
  if (key.isEmpty) return const <int>{};
  final anchorIds = key.split(',').map(int.parse).toSet();
  final settings = await ref.watch(settingsRepositoryProvider).read();
  if (settings == null) return const <int>{};
  final radiusMeters = settings.defaultRadiusKm * 1000;
  final matrix = ref.watch(distanceMatrixRepositoryProvider);
  final clientsRepo = ref.watch(clientRepositoryProvider);

  // Pull every entry "from anchor → other client" within radius. This is
  // exactly what `distancesFromPivot` returns. We also add reverse-direction
  // entries by querying each non-anchor → each anchor (cheap lookup, the
  // matrix is ~Nclients^2 which is fine in-memory).
  final entries = <DistanceMatrixEntry>[];
  for (final aid in anchorIds) {
    entries.addAll(
      await matrix.distancesFromPivot(
        pivotId: aid,
        maxDistanceMeters: radiusMeters,
      ),
    );
  }

  // Build the candidate list: every waiting client.
  final allClients = await clientsRepo.listAll();
  final candidates = [
    for (final c in allClients)
      if (c.isWaiting && !c.needsDistanceRecompute) c.id,
  ];

  return const FindClientsNearAnchors().call(
    anchorIds: anchorIds,
    candidateIds: candidates,
    matrix: entries,
    radiusMeters: radiusMeters,
  );
});

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

final waitingCommunesProvider =
    FutureProvider.autoDispose<List<({String name, int count})>>(
        (ref) async {
  final clients = ref.watch(clientRepositoryProvider);
  final settings = await ref.watch(settingsRepositoryProvider).read();
  final seasonStart = settings?.seasonStartedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  final withStatus = await clients.listAllWithStatus(seasonStart);
  final clientList = [for (final r in withStatus) r.$1];
  final statusByClientId = {
    for (final r in withStatus) r.$1.id: r.$2,
  };
  return const FindCommunesWithWaiting().call(
    clients: clientList,
    statusByClientId: statusByClientId,
  );
});

class OptimizedRequest {
  final String communeName;
  final int targetMinutes;
  const OptimizedRequest({
    required this.communeName,
    required this.targetMinutes,
  });

  @override
  bool operator ==(Object other) =>
      other is OptimizedRequest &&
      other.communeName == communeName &&
      other.targetMinutes == targetMinutes;

  @override
  int get hashCode => Object.hash(communeName, targetMinutes);
}

final optimizedProposalProvider = FutureProvider.autoDispose
    .family<OptimizedProposal, OptimizedRequest>((ref, req) async {
  // All ref.watch calls happen synchronously up-front. Awaiting before all
  // dependencies are registered would risk the ref being disposed by the
  // time we come back from the await.
  final clientsRepo = ref.watch(clientRepositoryProvider);
  final matrixRepo = ref.watch(distanceMatrixRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);

  final settings = await settingsRepo.read();
  if (settings == null) return OptimizedProposal.empty();
  final seasonStart = settings.seasonStartedAt;
  final withStatus = await clientsRepo.listAllWithStatus(seasonStart);
  final waiting = [
    for (final r in withStatus)
      if (r.$2 == ClientStatus.waiting) r.$1,
  ];
  // Pull the full pairwise matrix between base and every waiting client
  // (eligibility filtered inside the use case).
  final ids = [0, ...waiting.map((c) => c.id)];
  final entries = <DistanceMatrixEntry>[];
  for (final from in ids) {
    for (final to in ids) {
      if (from == to) continue;
      final m = await matrixRepo.distanceMeters(from: from, to: to);
      final s = await matrixRepo.durationSeconds(from: from, to: to);
      if (m == null || s == null) continue;
      entries.add(DistanceMatrixEntry(
        fromId: from,
        toId: to,
        distanceMeters: m,
        durationSeconds: s,
        computedAt: DateTime.now(),
      ));
    }
  }
  return const BuildOptimizedTourProposal().call(
    communeName: req.communeName,
    targetMinutes: req.targetMinutes,
    startTimeMinutes: 8 * 60,
    waitingClients: waiting,
    matrix: entries,
    settings: settings,
  );
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

/// Stream de l'état d'auth Supabase. Émet à chaque sign-in/sign-out
/// et à chaque refresh JWT.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Session courante (anon ou email). Null pendant l'init de Supabase.
final currentSessionProvider = Provider<Session?>((ref) {
  // Réagit au stream pour rebuild quand l'état change.
  ref.watch(authStateChangesProvider);
  return ref.watch(authServiceProvider).currentSession;
});

/// `true` ssi une session non-anonyme est active. Pilote l'affichage
/// des fonctionnalités cloud (bouton « Sauvegarder maintenant », liste
/// des backups, etc.).
final isCloudOptedInProvider = Provider<bool>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(authServiceProvider).isCloudOptedIn;
});

final backupsRepositoryProvider = Provider<BackupsRepository>((ref) {
  return BackupsRepositoryImpl(ref.watch(supabaseClientProvider));
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    repo: ref.watch(backupsRepositoryProvider),
    exporter: ref.watch(jsonExportServiceProvider),
    settings: ref.watch(settingsRepositoryProvider),
  );
});

final backupSchedulerProvider = Provider<BackupScheduler>((ref) {
  final scheduler = BackupScheduler(
    ref.watch(backupServiceProvider),
    ref.watch(settingsRepositoryProvider),
    ref,
  );
  scheduler.start();
  ref.onDispose(scheduler.stop);
  return scheduler;
});
