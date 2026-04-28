# Phase 9 — Tour lifecycle

**Goal:** Tours list (planned + completed), tour detail screen with schedule + fee split, mark-as-completed flow that updates clients, and share-text export.

**Verification at end of phase:** A planned tour can be opened, viewed, marked completed; the visited clients lose their `is_waiting` flag and gain a `last_shearing_date`; the share button copies a French summary to the clipboard.

---

## Task 9.1: Tours list screen

**Files:**
- Create: `lib/presentation/tours/tours_list_screen.dart`
- Modify: `lib/core/routing/app_router.dart` (replace placeholder)
- Modify: `lib/l10n/app_fr.arb` / `app_en.arb`

- [ ] **Step 1: Strings**

`app_fr.arb`:
```json
{
  "toursListTitle": "Tournées",
  "toursStatusPlanned": "Planifiée",
  "toursStatusCompleted": "Réalisée",
  "toursListItemFmt": "{date} · {n} client(s) · {km} km",
  "@toursListItemFmt": {"placeholders": {"date": {"type": "String"}, "n": {"type": "int"}, "km": {"type": "String"}}}
}
```

Mirror EN, regenerate.

- [ ] **Step 2: Write the screen**

```dart
// lib/presentation/tours/tours_list_screen.dart
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/models/tour.dart';
import '../../state/providers.dart';

final _toursAsyncProvider = FutureProvider<List<Tour>>((ref) {
  return ref.watch(tourRepositoryProvider).listAll();
});

class ToursListScreen extends ConsumerWidget {
  const ToursListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(_toursAsyncProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.toursListTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (tours) {
          if (tours.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.emptyToursTitle,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(l.emptyToursBody, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_toursAsyncProvider),
            child: ListView.separated(
              itemCount: tours.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final t = tours[i];
                return ListTile(
                  leading: Icon(
                    t.status == TourStatus.completed
                        ? Icons.check_circle
                        : Icons.alt_route,
                    color: t.status == TourStatus.completed
                        ? Colors.green
                        : null,
                  ),
                  title: Text(DateFormat('EEE dd/MM/yyyy', 'fr')
                      .format(t.plannedDate)),
                  subtitle: Text(
                    '${t.status == TourStatus.completed ? l.toursStatusCompleted : l.toursStatusPlanned} · ${(t.totalDistanceMeters / 1000).toStringAsFixed(1)} km',
                  ),
                  onTap: () => context.push('/tours/${t.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Wire route — replace tours placeholder**

```dart
StatefulShellBranch(routes: [
  GoRoute(
    path: '/tours',
    builder: (_, __) => const ToursListScreen(),
    routes: [
      GoRoute(
        path: ':id',
        builder: (_, state) => TourDetailScreen(
          tourId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  ),
]),
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/tours/tours_list_screen.dart \
        lib/core/routing/app_router.dart lib/l10n/
git commit -m "feat(tours): tours list screen"
```

---

## Task 9.2: Tour detail screen + complete + share

**Files:**
- Create: `lib/presentation/tours/tour_detail_screen.dart`
- Modify: `lib/l10n/app_fr.arb` / `app_en.arb`

- [ ] **Step 1: Strings**

`app_fr.arb`:
```json
{
  "tourDetailComplete": "Marquer comme réalisée",
  "tourDetailCompleteConfirmTitle": "Confirmer",
  "tourDetailCompleteConfirmBody":
    "Cette action met à jour la dernière tonte de {n} client(s) et les retire des clients en attente.",
  "@tourDetailCompleteConfirmBody": {"placeholders": {"n": {"type": "int"}}},
  "tourDetailShare": "Partager",
  "tourDetailScheduleTitle": "Planning",
  "tourDetailFeeTitle": "Partage des frais",
  "tourDetailDeleted": "(client supprimé)"
}
```

Mirror EN, regenerate.

- [ ] **Step 2: Write the screen**

```dart
// lib/presentation/tours/tour_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format_minutes.dart';
import '../../data/repositories/tour_repository.dart';
import '../../domain/models/tour.dart';
import '../../state/providers.dart';

final _tourByIdProvider =
    FutureProvider.autoDispose.family<TourWithStops?, int>((ref, id) {
  return ref.watch(tourRepositoryProvider).findById(id);
});

class TourDetailScreen extends ConsumerWidget {
  final int tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(_tourByIdProvider(tourId));
    return Scaffold(
      appBar: AppBar(
        title: Text(async.value == null
            ? '...'
            : DateFormat('EEE dd/MM/yyyy', 'fr')
                .format(async.value!.tour.plannedDate)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: async.value == null
                ? null
                : () => _share(async.value!, context),
            tooltip: l.tourDetailShare,
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (bundle) {
          if (bundle == null) return const SizedBox.shrink();
          return _Body(bundle: bundle, tourId: tourId);
        },
      ),
    );
  }

  Future<void> _share(TourWithStops bundle, BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final dateLine =
        DateFormat('dd/MM/yyyy').format(bundle.tour.plannedDate);
    final lines = <String>[
      'Tournée du $dateLine',
      ...bundle.stops.map(
        (s) =>
            '- ${s.clientNameSnapshot} : ${formatEuros(s.feeShareCents)}',
      ),
      'Total : ${formatEuros(bundle.tour.totalTravelFeeCents)}',
    ];
    await Share.share(lines.join('\n'), subject: 'Tournée du $dateLine');
  }
}

class _Body extends ConsumerWidget {
  final TourWithStops bundle;
  final int tourId;
  const _Body({required this.bundle, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final completed = bundle.tour.status == TourStatus.completed;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(
              completed ? Icons.check_circle : Icons.alt_route,
              color: completed ? Colors.green : null,
            ),
            title: Text(completed
                ? l.toursStatusCompleted
                : l.toursStatusPlanned),
            subtitle: Text(
              '${(bundle.tour.totalDistanceMeters / 1000).toStringAsFixed(1)} km · '
              '${formatDuration(bundle.tour.totalDriveSeconds ~/ 60)} de trajet · '
              'Départ ${formatHm(bundle.tour.startTimeMinutes)}',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(l.tourDetailScheduleTitle,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < bundle.stops.length; i++)
          ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(bundle.stops[i].clientId == null
                ? '${bundle.stops[i].clientNameSnapshot} ${l.tourDetailDeleted}'
                : bundle.stops[i].clientNameSnapshot),
            subtitle: Text(
              '${formatHm(bundle.stops[i].estimatedArrivalMinutes)} → '
              '${formatHm(bundle.stops[i].estimatedDepartureMinutes)} · '
              '${bundle.stops[i].sheepCountSnapshot} moutons',
            ),
            trailing: Text(formatEuros(bundle.stops[i].feeShareCents)),
          ),
        const SizedBox(height: 16),
        Text(l.tourDetailFeeTitle,
            style: Theme.of(context).textTheme.titleMedium),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Total : ${formatEuros(bundle.tour.totalTravelFeeCents)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!completed)
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: Text(l.tourDetailComplete),
            onPressed: () => _confirmComplete(context, ref),
          ),
      ],
    );
  }

  Future<void> _confirmComplete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.tourDetailCompleteConfirmTitle),
        content: Text(l.tourDetailCompleteConfirmBody(bundle.stops.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.tourDetailComplete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(tourRepositoryProvider).markCompleted(tourId);
      ref.invalidate(_tourByIdProvider(tourId));
    }
  }
}
```

- [ ] **Step 3: Run on Android end-to-end**:
1. From the tour created in Phase 8, open detail.
2. Verify schedule, fee split, totals.
3. Tap **Marquer comme réalisée** — confirm.
4. Go to Clients tab — visited clients should no longer be waiting; their last-shearing date should be today.
5. Tap **Partager** — Android share sheet appears with the recap text.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/tours/tour_detail_screen.dart lib/l10n/
git commit -m "feat(tours): detail screen with completion + share"
```

---

## Task 9.3: Phase 9 sweep

- [ ] **Step 1: Run all tests**

```bash
flutter test
```

- [ ] **Step 2: Manual smoke pass**

Walk the full happy path: onboard → 3 clients → 2 waiting → proximity → draft → save → detail → complete → list shows it as completed.

---

**Phase 9 done.** Tour lifecycle is complete. The remaining phases harden edge cases and prepare for release.
