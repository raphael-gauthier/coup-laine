# Phase 7 — Proximity search

**Goal:** From a pivot client, show nearby waiting clients within an adjustable radius, in either list or map view, with a selection accumulator that feeds the tour-draft flow.

**Verification at end of phase:** With 5+ waiting clients, navigating to proximity from one of them shows correctly filtered results, the radius slider works, the map shows pins, and selecting clients enables a "Plan tour" CTA in the bottom bar.

---

## Task 7.1: ProximityResult use case

**Files:**
- Create: `lib/domain/use_cases/find_nearby_clients.dart`
- Create: `test/domain/find_nearby_clients_test.dart`

A pure-Dart helper that takes the matrix rows + waiting client list and produces a sorted result. Most of the filtering happens in SQL already (see `DistanceMatrixRepository.distancesFromPivot`); this use case combines them.

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/find_nearby_clients_test.dart
import 'package:coupe_laine/domain/models/client.dart';
import 'package:coupe_laine/domain/models/coordinates.dart';
import 'package:coupe_laine/domain/models/distance_matrix_entry.dart';
import 'package:coupe_laine/domain/use_cases/find_nearby_clients.dart';
import 'package:flutter_test/flutter_test.dart';

Client _c(int id, String name, {bool waiting = true}) => Client(
      id: id,
      name: name,
      addressLabel: 'a',
      postcode: '00000',
      city: 'X',
      coordinates: const Coordinates(lat: 48, lon: -3),
      isWaiting: waiting,
    );

DistanceMatrixEntry _e(int from, int to, int dist) =>
    DistanceMatrixEntry(
      fromId: from,
      toId: to,
      distanceMeters: dist,
      durationSeconds: dist ~/ 14,
      computedAt: DateTime(2026),
    );

void main() {
  test('FindNearbyClients sorts by distance and excludes pivot', () {
    final result = const FindNearbyClients().call(
      pivotId: 1,
      maxRadiusMeters: 15000,
      candidates: [
        _c(2, 'B'),
        _c(3, 'C'),
        _c(4, 'D'), // not waiting
        _c(5, 'E'),
      ],
      pivotDistances: [
        _e(1, 2, 10000),
        _e(1, 3, 5000),
        _e(1, 5, 20000), // out of radius
      ],
    );
    expect(result.map((r) => r.client.name), ['C', 'B']);
    expect(result.first.distanceMeters, 5000);
  });
}
```

- [ ] **Step 2: Implement**

```dart
// lib/domain/use_cases/find_nearby_clients.dart
import '../models/client.dart';
import '../models/distance_matrix_entry.dart';

class NearbyClient {
  final Client client;
  final int distanceMeters;
  final int durationSeconds;
  const NearbyClient({
    required this.client,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class FindNearbyClients {
  const FindNearbyClients();

  List<NearbyClient> call({
    required int pivotId,
    required int maxRadiusMeters,
    required List<Client> candidates,
    required List<DistanceMatrixEntry> pivotDistances,
  }) {
    final byId = {for (final c in candidates) c.id: c};
    final results = <NearbyClient>[];
    for (final e in pivotDistances) {
      if (e.distanceMeters > maxRadiusMeters) continue;
      if (e.toId == pivotId) continue;
      final c = byId[e.toId];
      if (c == null || !c.isWaiting) continue;
      results.add(NearbyClient(
        client: c,
        distanceMeters: e.distanceMeters,
        durationSeconds: e.durationSeconds,
      ));
    }
    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }
}
```

- [ ] **Step 3: Run, expect PASS**

```bash
flutter test test/domain/find_nearby_clients_test.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/domain/use_cases/find_nearby_clients.dart \
        test/domain/find_nearby_clients_test.dart
git commit -m "feat(domain): find nearby clients use case"
```

---

## Task 7.2: ProximityController and providers

**Files:**
- Create: `lib/state/proximity_controller.dart`

- [ ] **Step 1: Write the controller**

```dart
// lib/state/proximity_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/client.dart';
import '../domain/use_cases/find_nearby_clients.dart';
import 'providers.dart';

class ProximityRequest {
  final int pivotId;
  final int radiusKm;
  const ProximityRequest({required this.pivotId, required this.radiusKm});
}

final proximityRequestProvider = StateProvider<ProximityRequest?>((_) => null);

final proximityResultsProvider =
    FutureProvider.autoDispose<List<NearbyClient>>((ref) async {
  final req = ref.watch(proximityRequestProvider);
  if (req == null) return const [];
  final clients = ref.watch(clientRepositoryProvider);
  final matrix = ref.watch(distanceMatrixRepositoryProvider);
  final candidates = await clients.listAll();
  final entries = await matrix.distancesFromPivot(
    pivotId: req.pivotId,
    maxDistanceMeters: req.radiusKm * 1000,
  );
  return const FindNearbyClients().call(
    pivotId: req.pivotId,
    maxRadiusMeters: req.radiusKm * 1000,
    candidates: candidates,
    pivotDistances: entries,
  );
});

final pivotClientProvider =
    FutureProvider.autoDispose.family<Client?, int>((ref, id) {
  return ref.watch(clientRepositoryProvider).findById(id);
});

/// Selected client ids to add to a draft tour. The pivot is implicitly
/// always included.
final tourSelectionProvider =
    StateNotifierProvider<TourSelection, Set<int>>((_) => TourSelection());

class TourSelection extends StateNotifier<Set<int>> {
  TourSelection() : super(const {});

  void toggle(int id) {
    final next = {...state};
    if (!next.add(id)) next.remove(id);
    state = next;
  }

  void clear() => state = const {};
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/state/proximity_controller.dart
git commit -m "feat(state): proximity providers + tour selection"
```

---

## Task 7.3: Proximity screen — list view

**Files:**
- Create: `lib/presentation/proximity/proximity_screen.dart`
- Create: `lib/presentation/proximity/proximity_list_view.dart`
- Modify: `lib/core/routing/app_router.dart`
- Modify: `lib/l10n/app_fr.arb`, `app_en.arb`

- [ ] **Step 1: Strings**

`app_fr.arb`:
```json
{
  "proximityTitle": "Clients à proximité",
  "proximityRadiusLabel": "Rayon : {km} km",
  "@proximityRadiusLabel": {"placeholders": {"km": {"type": "int"}}},
  "proximityTabList": "Liste",
  "proximityTabMap": "Carte",
  "proximityNoneInRadius": "Aucun client en attente dans ce rayon.",
  "proximitySelectedCount": "{n} sélectionné(s)",
  "@proximitySelectedCount": {"placeholders": {"n": {"type": "int"}}},
  "proximityPlanTour": "Composer la tournée",
  "proximityDistanceFmt": "{km} km · {min} min",
  "@proximityDistanceFmt": {"placeholders": {"km": {"type": "String"}, "min": {"type": "int"}}}
}
```

Mirror EN, regenerate.

- [ ] **Step 2: Write the list view**

```dart
// lib/presentation/proximity/proximity_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/proximity_controller.dart';

class ProximityListView extends ConsumerWidget {
  const ProximityListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(proximityResultsProvider);
    final selection = ref.watch(tourSelectionProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (results) {
        if (results.isEmpty) {
          return Center(child: Text(l.proximityNoneInRadius));
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final r = results[i];
            final selected = selection.contains(r.client.id);
            return CheckboxListTile(
              value: selected,
              onChanged: (_) => ref
                  .read(tourSelectionProvider.notifier)
                  .toggle(r.client.id),
              title: Text(r.client.name),
              subtitle: Text(
                '${r.client.city} · ${l.proximityDistanceFmt(
                  (r.distanceMeters / 1000).toStringAsFixed(1),
                  (r.durationSeconds / 60).round(),
                )} · ${r.client.sheepCount} moutons',
              ),
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 3: Write the screen scaffolding (radius slider + tabs + bottom bar)**

```dart
// lib/presentation/proximity/proximity_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/proximity_controller.dart';
import 'proximity_list_view.dart';
import 'proximity_map_view.dart';

class ProximityScreen extends ConsumerStatefulWidget {
  final int pivotId;
  const ProximityScreen({super.key, required this.pivotId});

  @override
  ConsumerState<ProximityScreen> createState() => _ProximityScreenState();
}

class _ProximityScreenState extends ConsumerState<ProximityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _radiusKm = 15;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proximityRequestProvider.notifier).state = ProximityRequest(
        pivotId: widget.pivotId,
        radiusKm: _radiusKm,
      );
      ref.read(tourSelectionProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _setRadius(int km) {
    setState(() => _radiusKm = km);
    ref.read(proximityRequestProvider.notifier).state = ProximityRequest(
      pivotId: widget.pivotId,
      radiusKm: km,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selection = ref.watch(tourSelectionProvider);
    final pivotAsync = ref.watch(pivotClientProvider(widget.pivotId));

    return Scaffold(
      appBar: AppBar(
        title: Text(pivotAsync.value?.name ?? l.proximityTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l.proximityTabList),
            Tab(text: l.proximityTabMap),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(l.proximityRadiusLabel(_radiusKm)),
                Expanded(
                  child: Slider(
                    min: 5,
                    max: 30,
                    divisions: 5,
                    value: _radiusKm.toDouble(),
                    label: '$_radiusKm km',
                    onChanged: (v) => _setRadius(v.round()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                const ProximityListView(),
                ProximityMapView(pivotId: widget.pivotId),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: selection.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(l.proximitySelectedCount(selection.length)),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => context
                          .push('/tours/draft?pivot=${widget.pivotId}'),
                      child: Text(l.proximityPlanTour),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
```

- [ ] **Step 4: Replace the proximity placeholder route**

In `app_router.dart`:

```dart
import '../../presentation/proximity/proximity_screen.dart';
// ...
GoRoute(
  path: '/proximity/:pivotId',
  builder: (_, state) => ProximityScreen(
    pivotId: int.parse(state.pathParameters['pivotId']!),
  ),
),
```

- [ ] **Step 5: Commit (without map view yet)**

```bash
git add lib/presentation/proximity/proximity_screen.dart \
        lib/presentation/proximity/proximity_list_view.dart \
        lib/core/routing/app_router.dart \
        lib/l10n/
git commit -m "feat(proximity): screen scaffold + list view"
```

---

## Task 7.4: Proximity map view

**Files:**
- Create: `lib/presentation/proximity/proximity_map_view.dart`

- [ ] **Step 1: Write the map view**

```dart
// lib/presentation/proximity/proximity_map_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../state/proximity_controller.dart';

class ProximityMapView extends ConsumerWidget {
  final int pivotId;
  const ProximityMapView({super.key, required this.pivotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pivot = ref.watch(pivotClientProvider(pivotId)).value;
    final results = ref.watch(proximityResultsProvider).value ?? const [];
    if (pivot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final pivotLatLng =
        LatLng(pivot.coordinates.lat, pivot.coordinates.lon);
    final selection = ref.watch(tourSelectionProvider);

    return FlutterMap(
      options: MapOptions(
        initialCenter: pivotLatLng,
        initialZoom: 11,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'fr.coupelaine',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: pivotLatLng,
              width: 36,
              height: 36,
              child: const Icon(Icons.star, color: Colors.deepOrange, size: 36),
            ),
            for (final r in results)
              Marker(
                point: LatLng(r.client.coordinates.lat, r.client.coordinates.lon),
                width: 28,
                height: 28,
                child: GestureDetector(
                  onTap: () => ref
                      .read(tourSelectionProvider.notifier)
                      .toggle(r.client.id),
                  child: Icon(
                    selection.contains(r.client.id)
                        ? Icons.check_circle
                        : Icons.location_on,
                    color: selection.contains(r.client.id)
                        ? Colors.green
                        : Colors.blue,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
```

> Tile provider note: OpenStreetMap's standard tile server is fine for low-volume personal use but has [a usage policy](https://operations.osmfoundation.org/policies/tiles/) — you must set a clear `User-Agent`, which we do via `userAgentPackageName`. For higher traffic, switch to a commercial provider.

- [ ] **Step 2: Run on Android, switch to map tab**, verify the pivot star, the result pins, and that tapping a pin toggles selection.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/proximity/proximity_map_view.dart
git commit -m "feat(proximity): map view with OSM tiles"
```

---

## Task 7.5: Proximity entry point — list waiting clients

**Files:**
- Modify: `lib/presentation/clients/clients_list_screen.dart`

The "find nearby" entry point already exists from the client detail screen. Add an extra path: from the Tours tab's "Plan a tour" entry, the user picks any waiting client to be the pivot. Implement that on the Tours tab in Phase 8 (we leave it as-is here).

- [ ] **Step 1: No code change.** Acknowledge that proximity flows are entered from the client detail screen built in Phase 6.

- [ ] **Step 2: Commit a marker (optional)** — skip if nothing changed.

---

**Phase 7 done.** Proximity search is fully functional. Selecting clients populates `tourSelectionProvider`, ready for the tour-draft flow in Phase 8.
