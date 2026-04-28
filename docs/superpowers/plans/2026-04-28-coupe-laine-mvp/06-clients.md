# Phase 6 — Client management

**Goal:** Full client CRUD with BAN-driven address entry, waiting toggle, and an integrated distance-matrix sync that calls ORS on save and gracefully degrades on failure.

**Verification at end of phase:** From a fresh-onboarded app, the user can add 3 clients in real Brittany coordinates, toggle one as waiting, and see proper distance matrix rows in the database.

---

## Task 6.1: DistanceMatrixSync use case

The single point of orchestration between `ClientRepository`, `OrsRoutingService`, and `DistanceMatrixRepository`.

**Files:**
- Create: `lib/data/distance_matrix_sync.dart`
- Create: `test/data/distance_matrix_sync_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/distance_matrix_sync_test.dart
import 'package:coupe_laine/data/distance_matrix_sync.dart';
import 'package:coupe_laine/data/repositories/client_repository.dart';
import 'package:coupe_laine/data/repositories/distance_matrix_repository.dart';
import 'package:coupe_laine/data/repositories/settings_repository.dart';
import 'package:coupe_laine/domain/models/client.dart';
import 'package:coupe_laine/domain/models/coordinates.dart';
import 'package:coupe_laine/domain/models/settings.dart';
import 'package:coupe_laine/infra/db/app_database.dart';
import 'package:coupe_laine/infra/services/ors_routing_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrs extends Mock implements OrsRoutingService {}

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late ClientRepository clients;
  late DistanceMatrixRepository matrix;
  late _MockOrs ors;
  late DistanceMatrixSync sync;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = SettingsRepository(db);
    clients = ClientRepository(db);
    matrix = DistanceMatrixRepository(db);
    ors = _MockOrs();
    sync = DistanceMatrixSync(
      clients: clients,
      matrix: matrix,
      settings: settings,
      ors: ors,
    );
    await settings.save(const Settings(
      baseCoordinates: Coordinates(lat: 48.5, lon: -2.7),
      baseAddressLabel: 'base',
    ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> _addClient(double lat, double lon, {String name = 'C'}) {
    return clients.insert(Client(
      id: 0,
      name: name,
      addressLabel: 'a',
      postcode: '00000',
      city: 'X',
      coordinates: Coordinates(lat: lat, lon: lon),
    ));
  }

  test('after insert: outbound + inbound rows present, flag cleared',
      () async {
    final aId = await _addClient(48.4, -2.8, name: 'A');
    when(() => ors.matrix(
          locations: any(named: 'locations'),
          sources: any(named: 'sources'),
          destinations: any(named: 'destinations'),
        )).thenAnswer((inv) async {
      final src = inv.namedArguments[#sources] as List<int>;
      final dst = inv.namedArguments[#destinations] as List<int>;
      return OrsMatrixResult(
        distances: List.generate(
          src.length,
          (_) => List.generate(dst.length, (_) => 5000),
        ),
        durations: List.generate(
          src.length,
          (_) => List.generate(dst.length, (_) => 600),
        ),
      );
    });

    await sync.recomputeForClient(aId);

    expect(await matrix.distanceMeters(from: 0, to: aId), 5000);
    expect(await matrix.distanceMeters(from: aId, to: 0), 5000);
    final c = await clients.findById(aId);
    expect(c!.needsDistanceRecompute, isFalse);
  });

  test('on ORS failure: flag stays set, throws', () async {
    final aId = await _addClient(48.4, -2.8);
    when(() => ors.matrix(
          locations: any(named: 'locations'),
          sources: any(named: 'sources'),
          destinations: any(named: 'destinations'),
        )).thenThrow(OrsException('boom'));

    expect(
      () => sync.recomputeForClient(aId),
      throwsA(isA<OrsException>()),
    );
    final c = await clients.findById(aId);
    expect(c!.needsDistanceRecompute, isTrue);
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
flutter test test/data/distance_matrix_sync_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/data/distance_matrix_sync.dart
import '../domain/models/coordinates.dart';
import '../domain/models/distance_matrix_entry.dart';
import '../infra/services/ors_routing_service.dart';
import 'repositories/client_repository.dart';
import 'repositories/distance_matrix_repository.dart';
import 'repositories/settings_repository.dart';

class DistanceMatrixSync {
  final ClientRepository clients;
  final DistanceMatrixRepository matrix;
  final SettingsRepository settings;
  final OrsRoutingService ors;

  DistanceMatrixSync({
    required this.clients,
    required this.matrix,
    required this.settings,
    required this.ors,
  });

  /// Compute outbound (X→all) and inbound (all→X) rows for [clientId],
  /// where "all" = base + every other existing client.
  Future<void> recomputeForClient(int clientId) async {
    final settingsRow = await settings.read();
    if (settingsRow == null) {
      throw StateError('Cannot compute matrix without home base');
    }
    final target = await clients.findById(clientId);
    if (target == null) {
      throw StateError('Unknown client $clientId');
    }
    final others = (await clients.listAll())
        .where((c) => c.id != clientId)
        .toList();

    // Build the locations list: index 0 = X, then base, then every other.
    final locations = <Coordinates>[
      target.coordinates,
      settingsRow.baseCoordinates,
      ...others.map((c) => c.coordinates),
    ];
    final ids = <int>[
      clientId,
      DistanceMatrixEntry.baseId,
      ...others.map((c) => c.id),
    ];

    try {
      // Outbound: from X (index 0) to all (indices 1..n)
      final outbound = await ors.matrix(
        locations: locations,
        sources: const [0],
        destinations: List.generate(locations.length - 1, (i) => i + 1),
      );
      // Inbound: from all (indices 1..n) to X (index 0)
      final inbound = await ors.matrix(
        locations: locations,
        sources: List.generate(locations.length - 1, (i) => i + 1),
        destinations: const [0],
      );

      final now = DateTime.now();
      final rows = <DistanceMatrixEntry>[];
      for (var j = 0; j < ids.length - 1; j++) {
        rows.add(DistanceMatrixEntry(
          fromId: ids[0],
          toId: ids[j + 1],
          distanceMeters: outbound.distances[0][j],
          durationSeconds: outbound.durations[0][j],
          computedAt: now,
        ));
        rows.add(DistanceMatrixEntry(
          fromId: ids[j + 1],
          toId: ids[0],
          distanceMeters: inbound.distances[j][0],
          durationSeconds: inbound.durations[j][0],
          computedAt: now,
        ));
      }
      await matrix.upsertMany(rows);
      await clients.setRecomputeDone(clientId);
    } on OrsException {
      await clients.setRecomputePending(clientId);
      rethrow;
    }
  }

  /// Recompute base ↔ all clients (when the base address changes).
  Future<void> recomputeAllForBase() async {
    final settingsRow = await settings.read();
    if (settingsRow == null) return;
    final all = await clients.listAll();
    if (all.isEmpty) return;

    final locations = <Coordinates>[
      settingsRow.baseCoordinates,
      ...all.map((c) => c.coordinates),
    ];
    final ids = <int>[
      DistanceMatrixEntry.baseId,
      ...all.map((c) => c.id),
    ];

    final outbound = await ors.matrix(
      locations: locations,
      sources: const [0],
      destinations: List.generate(all.length, (i) => i + 1),
    );
    final inbound = await ors.matrix(
      locations: locations,
      sources: List.generate(all.length, (i) => i + 1),
      destinations: const [0],
    );

    final now = DateTime.now();
    final rows = <DistanceMatrixEntry>[];
    for (var j = 0; j < all.length; j++) {
      rows.add(DistanceMatrixEntry(
        fromId: ids[0],
        toId: ids[j + 1],
        distanceMeters: outbound.distances[0][j],
        durationSeconds: outbound.durations[0][j],
        computedAt: now,
      ));
      rows.add(DistanceMatrixEntry(
        fromId: ids[j + 1],
        toId: ids[0],
        distanceMeters: inbound.distances[j][0],
        durationSeconds: inbound.durations[j][0],
        computedAt: now,
      ));
    }
    await matrix.upsertMany(rows);
  }

  /// Retry every client flagged `needsDistanceRecompute`.
  Future<int> retryAllPending() async {
    final pending = await clients.listNeedingRecompute();
    var done = 0;
    for (final c in pending) {
      try {
        await recomputeForClient(c.id);
        done++;
      } on OrsException {
        // Leave it pending; banner stays.
      }
    }
    return done;
  }
}
```

- [ ] **Step 4: Add the provider**

In `lib/state/providers.dart` append:

```dart
import '../data/distance_matrix_sync.dart';

final distanceMatrixSyncProvider = Provider<DistanceMatrixSync>((ref) {
  return DistanceMatrixSync(
    clients: ref.watch(clientRepositoryProvider),
    matrix: ref.watch(distanceMatrixRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    ors: ref.watch(orsRoutingServiceProvider),
  );
});
```

- [ ] **Step 5: Run, expect PASS**

```bash
flutter test test/data/distance_matrix_sync_test.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/data/distance_matrix_sync.dart \
        lib/state/providers.dart \
        test/data/distance_matrix_sync_test.dart
git commit -m "feat(data): distance matrix sync orchestrator"
```

---

## Task 6.2: Clients list screen

**Files:**
- Create: `lib/presentation/clients/clients_list_screen.dart`
- Modify: `lib/core/routing/app_router.dart` (replace placeholder + add sub-routes)
- Modify: `lib/l10n/app_fr.arb` / `app_en.arb`

- [ ] **Step 1: Add strings**

`app_fr.arb`:
```json
{
  "clientsListTitle": "Clients",
  "clientsAddNew": "Nouveau client",
  "clientsFilterAll": "Tous",
  "clientsFilterWaiting": "En attente",
  "clientsBadgeWaiting": "En attente",
  "clientsBadgeRecompute": "Distances à recalculer",
  "clientsRetryRecompute": "Recalculer les distances manquantes",
  "clientsLastShearingNever": "Jamais tondu",
  "clientsLastShearingFmt": "Dernière tonte : {date}",
  "@clientsLastShearingFmt": {"placeholders": {"date": {"type": "String"}}}
}
```

Mirror in `app_en.arb`. Run `flutter gen-l10n`.

- [ ] **Step 2: Write the screen**

```dart
// lib/presentation/clients/clients_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/models/client.dart';
import '../../state/providers.dart';

enum _Filter { all, waiting }

final _filterProvider = StateProvider<_Filter>((_) => _Filter.all);

final _clientsAsyncProvider = FutureProvider<List<Client>>((ref) {
  return ref.watch(clientRepositoryProvider).listAll();
});

class ClientsListScreen extends ConsumerWidget {
  const ClientsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final filter = ref.watch(_filterProvider);
    final async = ref.watch(_clientsAsyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.clientsListTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<_Filter>(
              segments: [
                ButtonSegment(
                    value: _Filter.all, label: Text(l.clientsFilterAll)),
                ButtonSegment(
                    value: _Filter.waiting,
                    label: Text(l.clientsFilterWaiting)),
              ],
              selected: {filter},
              onSelectionChanged: (s) =>
                  ref.read(_filterProvider.notifier).state = s.first,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/clients/new'),
        icon: const Icon(Icons.add),
        label: Text(l.clientsAddNew),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final list = filter == _Filter.waiting
              ? all.where((c) => c.isWaiting).toList()
              : all;
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.emptyClientsTitle,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(l.emptyClientsBody,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_clientsAsyncProvider),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _ClientTile(client: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final Client client;
  const _ClientTile({required this.client});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lastShearing = client.lastShearingDate == null
        ? l.clientsLastShearingNever
        : l.clientsLastShearingFmt(
            DateFormat('dd/MM/yyyy').format(client.lastShearingDate!),
          );
    return ListTile(
      title: Text(client.name),
      subtitle: Text('${client.city} · $lastShearing'),
      trailing: Wrap(
        spacing: 4,
        children: [
          if (client.isWaiting)
            const Chip(label: Text('En attente'), visualDensity: VisualDensity.compact),
          if (client.needsDistanceRecompute)
            const Chip(
                label: Text('Distances'),
                visualDensity: VisualDensity.compact,
                backgroundColor: Color(0xFFFFE0B2)),
        ],
      ),
      onTap: () => context.push('/clients/${client.id}'),
    );
  }
}
```

- [ ] **Step 3: Wire route**

In `app_router.dart` replace the clients placeholder branch:

```dart
import '../../presentation/clients/clients_list_screen.dart';
// ...
StatefulShellBranch(routes: [
  GoRoute(
    path: '/clients',
    builder: (_, __) => const ClientsListScreen(),
    routes: [
      GoRoute(
        path: 'new',
        builder: (_, __) => const ClientFormScreen(),
      ),
      GoRoute(
        path: ':id',
        builder: (_, state) => ClientDetailScreen(
          clientId: int.parse(state.pathParameters['id']!),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) => ClientFormScreen(
              clientId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
    ],
  ),
]),
```

(The two referenced screens are added in tasks 6.3 and 6.4. Add the imports as you go.)

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/clients/clients_list_screen.dart \
        lib/core/routing/app_router.dart lib/l10n/
git commit -m "feat(clients): list screen with filter and FAB"
```

---

## Task 6.3: Client form (create + edit)

**Files:**
- Create: `lib/presentation/clients/client_form_screen.dart`

- [ ] **Step 1: Add strings**

`app_fr.arb`:
```json
{
  "clientFormTitleNew": "Nouveau client",
  "clientFormTitleEdit": "Modifier le client",
  "clientFormName": "Nom",
  "clientFormPhone": "Téléphone",
  "clientFormSheepCount": "Nombre de moutons",
  "clientFormMinPerSheepHint": "Minutes par mouton (laisser vide pour défaut)",
  "clientFormNotes": "Notes",
  "clientFormSave": "Enregistrer",
  "clientFormDelete": "Supprimer",
  "clientFormErrorNoCoords": "Sélectionnez une adresse dans les suggestions",
  "clientFormErrorRecompute":
    "Client enregistré, mais les distances n'ont pas pu être calculées. Réessayez plus tard."
}
```

Mirror EN, regenerate.

- [ ] **Step 2: Write the screen**

```dart
// lib/presentation/clients/client_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/client.dart';
import '../../domain/models/coordinates.dart';
import '../../infra/services/ban_geocoding_service.dart';
import '../../infra/services/ors_routing_service.dart';
import '../../state/providers.dart';
import '../widgets/address_autocomplete_field.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  final int? clientId;
  const ClientFormScreen({super.key, this.clientId});

  bool get isEdit => clientId != null;

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _sheep = TextEditingController(text: '0');
  final _minOverride = TextEditingController();
  final _notes = TextEditingController();

  String? _addressLabel;
  String? _postcode;
  String? _city;
  Coordinates? _coords;
  bool _saving = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final c = await ref
        .read(clientRepositoryProvider)
        .findById(widget.clientId!);
    if (c == null) return;
    _name.text = c.name;
    _phone.text = c.phone ?? '';
    _sheep.text = c.sheepCount.toString();
    _minOverride.text = c.minutesPerSheepOverride?.toString() ?? '';
    _notes.text = c.notes ?? '';
    _addressLabel = c.addressLabel;
    _postcode = c.postcode;
    _city = c.city;
    _coords = c.coordinates;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.clientFormErrorNoCoords)),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(clientRepositoryProvider);
    final sync = ref.read(distanceMatrixSyncProvider);

    int id;
    if (widget.isEdit) {
      id = widget.clientId!;
      await repo.updateBasics(
        id: id,
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        sheepCount: int.parse(_sheep.text),
        minutesPerSheepOverride: _minOverride.text.trim().isEmpty
            ? null
            : int.parse(_minOverride.text),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      await repo.updateAddress(
        id: id,
        addressLabel: _addressLabel!,
        postcode: _postcode!,
        city: _city!,
        coordinates: _coords!,
      );
    } else {
      id = await repo.insert(Client(
        id: 0,
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        addressLabel: _addressLabel!,
        postcode: _postcode!,
        city: _city!,
        coordinates: _coords!,
        sheepCount: int.parse(_sheep.text),
        minutesPerSheepOverride: _minOverride.text.trim().isEmpty
            ? null
            : int.parse(_minOverride.text),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ));
    }

    try {
      await sync.recomputeForClient(id);
    } on OrsException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.clientFormErrorRecompute)),
        );
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? l.clientFormTitleEdit : l.clientFormTitleNew),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l.clientFormName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(labelText: l.clientFormPhone),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            AddressAutocompleteField(
              initialLabel: _addressLabel,
              onPicked: (r) => setState(() {
                _addressLabel = r.label;
                _postcode = r.postcode;
                _city = r.city;
                _coords = r.coordinates;
              }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sheep,
              decoration: InputDecoration(labelText: l.clientFormSheepCount),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 0) ? 'Nombre invalide' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minOverride,
              decoration: InputDecoration(
                  labelText: l.clientFormMinPerSheepHint),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v);
                return (n == null || n <= 0) ? 'Nombre invalide' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: l.clientFormNotes),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.clientFormSave),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run on Android**, add a real client, watch the matrix populate (you can verify by running a manual SQL query via the drift debug if you set one up, or just confirm no error banner).

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/clients/client_form_screen.dart lib/l10n/
git commit -m "feat(clients): create/edit form with BAN address + matrix sync"
```

---

## Task 6.4: Client detail screen

**Files:**
- Create: `lib/presentation/clients/client_detail_screen.dart`

- [ ] **Step 1: Add strings**

`app_fr.arb`:
```json
{
  "clientDetailWaitingToggle": "En attente",
  "clientDetailRecomputeBanner":
    "Distances non calculées. Touchez pour réessayer.",
  "clientDetailEdit": "Modifier",
  "clientDetailDelete": "Supprimer",
  "clientDetailDeleteConfirm": "Supprimer ce client ?",
  "clientDetailFindNearby": "Voir les clients à proximité"
}
```

Mirror EN, regenerate.

- [ ] **Step 2: Write the screen**

```dart
// lib/presentation/clients/client_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/client.dart';
import '../../infra/services/ors_routing_service.dart';
import '../../state/providers.dart';

final _clientByIdProvider =
    FutureProvider.family<Client?, int>((ref, id) {
  return ref.watch(clientRepositoryProvider).findById(id);
});

class ClientDetailScreen extends ConsumerWidget {
  final int clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_clientByIdProvider(clientId));
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(async.value?.name ?? '...'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/clients/$clientId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref, l),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (c) =>
            c == null ? const SizedBox.shrink() : _Body(client: c),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(l.clientDetailDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.clientDetailDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(clientRepositoryProvider).delete(clientId);
      await ref
          .read(distanceMatrixRepositoryProvider)
          .deleteForClient(clientId);
      ref.invalidate(_clientByIdProvider(clientId));
      if (context.mounted) context.pop();
    }
  }
}

class _Body extends ConsumerWidget {
  final Client client;
  const _Body({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (client.needsDistanceRecompute)
          Card(
            color: const Color(0xFFFFF3E0),
            child: ListTile(
              leading: const Icon(Icons.warning_amber),
              title: Text(l.clientDetailRecomputeBanner),
              onTap: () async {
                final sync = ref.read(distanceMatrixSyncProvider);
                try {
                  await sync.recomputeForClient(client.id);
                  ref.invalidate(_clientByIdProvider(client.id));
                } on OrsException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
            ),
          ),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(client.addressLabel),
          subtitle: Text('${client.postcode} ${client.city}'),
        ),
        if (client.phone != null)
          ListTile(
            leading: const Icon(Icons.phone),
            title: Text(client.phone!),
          ),
        ListTile(
          leading: const Icon(Icons.pets),
          title: Text('${client.sheepCount} moutons'),
          subtitle: client.minutesPerSheepOverride == null
              ? null
              : Text('${client.minutesPerSheepOverride} min/mouton'),
        ),
        if (client.notes != null)
          ListTile(
            leading: const Icon(Icons.note),
            title: Text(client.notes!),
          ),
        SwitchListTile(
          value: client.isWaiting,
          title: Text(l.clientDetailWaitingToggle),
          onChanged: (v) async {
            await ref
                .read(clientRepositoryProvider)
                .setWaiting(id: client.id, isWaiting: v);
            ref.invalidate(_clientByIdProvider(client.id));
          },
        ),
        const SizedBox(height: 16),
        if (client.isWaiting && !client.needsDistanceRecompute)
          FilledButton.icon(
            onPressed: () => context.push('/proximity/${client.id}'),
            icon: const Icon(Icons.travel_explore),
            label: Text(l.clientDetailFindNearby),
          ),
      ],
    );
  }
}
```

- [ ] **Step 3: Add the proximity route stub** (real screen comes in Phase 7)

In `app_router.dart`, alongside the clients shell branch (top-level, accessible from any tab):

```dart
GoRoute(
  path: '/proximity/:pivotId',
  builder: (_, state) => _Placeholder(
    'Proximité ${state.pathParameters['pivotId']}',
  ),
),
```

- [ ] **Step 4: Run on Android**, click into a client, toggle waiting, see the recompute banner if applicable.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/clients/client_detail_screen.dart \
        lib/core/routing/app_router.dart lib/l10n/
git commit -m "feat(clients): client detail screen with waiting toggle and recompute"
```

---

## Task 6.5: Global recompute-pending banner on Clients list

**Files:**
- Modify: `lib/presentation/clients/clients_list_screen.dart`

- [ ] **Step 1: Add the banner above the list**

Inject a top banner in the `body` of `ClientsListScreen` that shows when there are pending-recompute clients:

```dart
final pendingProvider = FutureProvider<int>((ref) async {
  final clients = ref.watch(clientRepositoryProvider);
  return (await clients.listNeedingRecompute()).length;
});
```

In the list view (right above the SegmentedButton or above the ListView builder), add:

```dart
final pending = ref.watch(pendingProvider).value ?? 0;
if (pending > 0)
  MaterialBanner(
    content: Text('$pending client(s) sans distances calculées'),
    leading: const Icon(Icons.warning_amber),
    actions: [
      TextButton(
        onPressed: () async {
          final sync = ref.read(distanceMatrixSyncProvider);
          final fixed = await sync.retryAllPending();
          ref.invalidate(pendingProvider);
          ref.invalidate(_clientsAsyncProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$fixed client(s) recalculés')),
            );
          }
        },
        child: const Text('Recalculer'),
      ),
    ],
  ),
```

(Place it inside the `Scaffold.body`'s `Column` above the `Expanded(child: ListView(...))`. You'll need to restructure the body into a `Column` if it isn't already.)

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/clients/clients_list_screen.dart
git commit -m "feat(clients): banner to retry pending matrix recomputes"
```

---

## Task 6.6: Phase 6 sweep

- [ ] **Step 1: Run all tests**

```bash
flutter test
```

- [ ] **Step 2: Manual smoke**

1. Add 3 real clients in different Brittany communes.
2. Confirm the matrix has rows: open the database via `dart run drift_dev schema dump` or rely on the absence of recompute banners.
3. Toggle one client waiting; the segmented filter "En attente" shows it.

---

**Phase 6 done.** Clients are first-class; matrix is automatically maintained. Proximity search (Phase 7) can now query.
