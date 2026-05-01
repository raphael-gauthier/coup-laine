# UI Redesign v3 — Top 4 Screens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refonte fonctionnelle des 4 écrans prioritaires (Tour detail, Client detail, Tour completion, Map) en utilisant les composants signature du Plan 1 (`AppHeader`, `AppActionBar`, `AppKpiRow`, `AppListTile`, `AppTimelineRow`, `AppDiffRow`, `AppFAB`, etc.) + introduction des helpers globaux (confirm dialog, MiniMap widget, providers de KPIs).

**Architecture:** Chaque écran est rebati en consommant les composants déjà construits. Pour les KPIs nouveaux (ex. revenu cumulé client), on ajoute des dérivations au-dessus des providers existants (pas de nouveau schéma, pas de nouvelle table). Le `MiniMap` est un nouveau widget `flutter_map` non-interactif réutilisable. Les helpers globaux (confirm, snackbar+undo) sont des fonctions ou widgets simples dans `lib/core/ui/` et `lib/presentation/widgets/`.

**Tech Stack:** Flutter 3.41+, Forui 0.21.3, Riverpod 3.3.1, flutter_map 8.3.0 (déjà installé), flutter_svg, intl. Pas de nouvelle dépendance.

**Out-of-scope dans ce plan** (couverts par Plan 3 sweep) : application des patterns globaux (`AppHeader`/`AppActionBar`) aux 13 autres écrans, refonte des forms (Client form, Settings, Onboarding step 3, etc.), drop de `AppHeroCard` et de Fraunces, command palette branchée, recherche universelle.

---

## File Structure

**Modifié :**
- `lib/presentation/tours/tour_detail_screen.dart` — refonte complète (KpiRow, MiniMap, AppListTile rich, agg summary, ActionBar)
- `lib/presentation/clients/client_detail_screen.dart` — refonte complète (KpiRow synthèse, Prochaine action, AppTimelineRow, ActionBar)
- `lib/presentation/tours/tour_completion_screen.dart` — refonte (live KpiRow, AppDiffRow, confirm dialog)
- `lib/presentation/map/map_screen.dart` — refonte (floating KpiRow chips, FAB localisation, sheet pin riche)
- `lib/presentation/map/client_pin_popup.dart` — refonte en sheet riche

**Créé :**
- `lib/core/ui/confirm_dialog.dart` — `showDestructiveConfirm` helper
- `lib/presentation/widgets/mini_map.dart` — `MiniMap` widget non-interactif
- `lib/state/providers/client_kpis.dart` — providers `clientKpisProvider`, `clientNextTourProvider`
- `lib/state/providers/tour_kpis.dart` — provider `tourPrestationSummaryProvider`
- `lib/state/providers/map_kpis.dart` — provider `clientCountByStatusProvider`
- `test/core/ui/confirm_dialog_test.dart` — non-test (le helper est trivial — skip widget test, skip dans cette plan)
- `test/state/providers/client_kpis_test.dart` — tests pure-dart de la dérivation
- `test/state/providers/tour_kpis_test.dart` — tests pure-dart de la dérivation

**Note sur le scope** : ce plan rebatit 4 écrans complètement. C'est gros mais bordé. La plupart des tâches consistent à remplacer le `child` du `FScaffold` par une nouvelle composition de composants existants. Aucune migration de logique métier.

---

## Phase 0 — Helpers globaux

### Task 1: `showDestructiveConfirm` helper

**Files:**
- Create: `lib/core/ui/confirm_dialog.dart`

- [ ] **Step 1: Créer le helper**

```dart
// lib/core/ui/confirm_dialog.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Dialog de confirmation pour action destructive (suppression, reset, etc.).
/// Pattern unifié v3 : title direct, body court qui explique la conséquence,
/// actions `Annuler outline` + `<actionLabel> destructive`. Haptique heavy
/// quand l'utilisateur confirme.
///
/// Retourne `true` si confirmé, `false` ou `null` si annulé.
Future<bool> showDestructiveConfirm(
  BuildContext context, {
  required String title,
  required String body,
  String cancelLabel = 'Annuler',
  String confirmLabel = 'Supprimer',
}) async {
  final ok = await showFDialog<bool>(
    context: context,
    builder: (ctx, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: Text(title),
      body: Text(body),
      actions: [
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        FButton(
          variant: FButtonVariant.destructive,
          onPress: () {
            HapticFeedback.heavyImpact();
            Navigator.of(ctx).pop(true);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}
```

- [ ] **Step 2: `flutter analyze`**

```
flutter analyze lib/core/ui/confirm_dialog.dart
```

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/ui/confirm_dialog.dart
git commit -m "feat(core): add showDestructiveConfirm helper"
```

---

### Task 2: `MiniMap` widget non-interactif

**Files:**
- Create: `lib/presentation/widgets/mini_map.dart`

- [ ] **Step 1: Créer le widget**

```dart
// lib/presentation/widgets/mini_map.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';

import '../../core/design_tokens.dart';

/// MiniMap non-interactif (gestures disabled). Affiche une route polyline
/// (ordonnée) + des pins numérotés à chaque waypoint + un pin home pour
/// la base. Auto-fit sur les bounds des waypoints au build initial.
///
/// Réutilisé par Tour detail (overview de la tournée) et Tour draft
/// (preview live pendant la composition — Plan 3).
class MiniMap extends StatefulWidget {
  /// Coordonnées de la base (drop-pin home).
  final LatLng base;

  /// Waypoints ordonnés (ordre des stops). Affichés numérotés 1, 2, 3…
  final List<LatLng> waypoints;

  /// Hauteur fixe du widget.
  final double height;

  /// Optional tap callback — lance typiquement une vue plein-écran.
  final VoidCallback? onTap;

  const MiniMap({
    super.key,
    required this.base,
    required this.waypoints,
    this.height = 160,
    this.onTap,
  });

  @override
  State<MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<MiniMap> {
  final MapController _ctrl = MapController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  LatLngBounds? _computeBounds() {
    final pts = <LatLng>[widget.base, ...widget.waypoints];
    if (pts.length < 2) return null;
    return LatLngBounds.fromPoints(pts);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bounds = _computeBounds();

    final markers = <Marker>[
      Marker(
        point: widget.base,
        width: 28,
        height: 28,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colors.background, width: 2),
          ),
          alignment: Alignment.center,
          child: Icon(FIcons.home,
              color: theme.colors.primaryForeground, size: 14),
        ),
      ),
      for (var i = 0; i < widget.waypoints.length; i++)
        Marker(
          point: widget.waypoints[i],
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colors.background, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '${i + 1}',
              style: theme.typography.xs.copyWith(
                color: theme.colors.secondaryForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: theme.colors.border,
            width: AppSizes.hairlineBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: FlutterMap(
          mapController: _ctrl,
          options: MapOptions(
            initialCameraFit: bounds == null
                ? CameraFit.coordinates(coordinates: [widget.base], maxZoom: 13)
                : CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(20),
                    maxZoom: 13,
                  ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.coup_laine',
            ),
            if (widget.waypoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [widget.base, ...widget.waypoints, widget.base],
                    color: theme.colors.primary,
                    strokeWidth: 3,
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`**

```
flutter analyze lib/presentation/widgets/mini_map.dart
```

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/mini_map.dart
git commit -m "feat(widgets): add MiniMap non-interactive flutter_map widget"
```

---

### Task 3: Provider `tourPrestationSummaryProvider`

**Files:**
- Create: `lib/state/providers/tour_kpis.dart`
- Test: `test/state/providers/tour_kpis_test.dart`

- [ ] **Step 1: Écrire le test pure-dart de la fonction d'agrégation**

```dart
// test/state/providers/tour_kpis_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';
import 'package:coup_laine/state/providers/tour_kpis.dart';

void main() {
  TourStopPrestation _row({
    required String name,
    required int qty,
    required int price,
  }) =>
      TourStopPrestation(
        prestationId: name.hashCode,
        qty: qty,
        nameSnapshot: name,
        priceCentsSnapshot: price,
        minutesSnapshot: 0,
        categoryIdSnapshot: null,
        categoryNameSnapshot: null,
        speciesNameSnapshot: null,
      );

  group('aggregatePrestations', () {
    test('regroupe par nameSnapshot, somme qty, multiplie prix × qty', () {
      final result = aggregatePrestations([
        [_row(name: 'Tonte Petit', qty: 3, price: 6000)],
        [_row(name: 'Tonte Petit', qty: 5, price: 6000)],
        [_row(name: 'Parage', qty: 1, price: 4000)],
      ]);

      expect(result.length, 2);
      final tonte = result.firstWhere((r) => r.name == 'Tonte Petit');
      expect(tonte.qty, 8);
      expect(tonte.totalCents, 8 * 6000);
      final parage = result.firstWhere((r) => r.name == 'Parage');
      expect(parage.qty, 1);
      expect(parage.totalCents, 4000);
    });

    test('liste vide → résultat vide', () {
      expect(aggregatePrestations(const []), isEmpty);
    });

    test('total global = somme des qty × priceCentsSnapshot', () {
      final result = aggregatePrestations([
        [_row(name: 'A', qty: 2, price: 1000)],
        [_row(name: 'B', qty: 3, price: 500)],
      ]);
      final total = result.fold<int>(0, (s, r) => s + r.totalCents);
      expect(total, 2 * 1000 + 3 * 500);
    });
  });
}
```

- [ ] **Step 2: Lancer → fail (file missing)**

```
flutter test test/state/providers/tour_kpis_test.dart
```

Expected: FAIL.

- [ ] **Step 3: Créer `lib/state/providers/tour_kpis.dart`**

```dart
// lib/state/providers/tour_kpis.dart
//
// KPIs de Tour detail. Agrège les prestations de tous les stops d'une
// tournée pour produire un résumé « Tonte Petit ×8 | Parage ×1 | total 480 € ».

import '../../domain/models/tour_stop_prestation.dart';

class PrestationSummary {
  final String name;
  final int qty;
  final int totalCents;
  const PrestationSummary({
    required this.name,
    required this.qty,
    required this.totalCents,
  });
}

/// Agrège une liste de listes de prestations (typiquement une par stop)
/// en regroupant par `nameSnapshot`, sommant les qty et multipliant
/// `priceCentsSnapshot * qty` pour le total.
List<PrestationSummary> aggregatePrestations(
  List<List<TourStopPrestation>> stopsPrestations,
) {
  final byName = <String, ({int qty, int totalCents})>{};
  for (final stop in stopsPrestations) {
    for (final p in stop) {
      final entry = byName[p.nameSnapshot];
      final addedQty = (entry?.qty ?? 0) + p.qty;
      final addedTotal =
          (entry?.totalCents ?? 0) + (p.priceCentsSnapshot * p.qty);
      byName[p.nameSnapshot] = (qty: addedQty, totalCents: addedTotal);
    }
  }
  return [
    for (final entry in byName.entries)
      PrestationSummary(
        name: entry.key,
        qty: entry.value.qty,
        totalCents: entry.value.totalCents,
      ),
  ];
}
```

- [ ] **Step 4: Lancer → pass**

```
flutter test test/state/providers/tour_kpis_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/state/providers/tour_kpis.dart test/state/providers/tour_kpis_test.dart
git commit -m "feat(state): add aggregatePrestations + tour_kpis module"
```

---

### Task 4: Provider `clientKpisProvider` + `clientNextTourProvider`

**Files:**
- Create: `lib/state/providers/client_kpis.dart`
- Test: `test/state/providers/client_kpis_test.dart`

- [ ] **Step 1: Écrire le test pure-dart**

```dart
// test/state/providers/client_kpis_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/intervention.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';
import 'package:coup_laine/state/providers/client_kpis.dart';

void main() {
  Intervention _interv({
    required DateTime date,
    required InterventionKind kind,
    List<TourStopPrestation>? prestations,
  }) =>
      Intervention(
        date: date,
        kind: kind,
        prestations: prestations ?? const [],
        tourId: kind == InterventionKind.tour ? 1 : null,
        manualEntryId: kind == InterventionKind.manual ? 1 : null,
        hasBilan: true,
      );

  TourStopPrestation _row(int qty, int priceCents) => TourStopPrestation(
        prestationId: 1,
        qty: qty,
        nameSnapshot: 'X',
        priceCentsSnapshot: priceCents,
        minutesSnapshot: 0,
        categoryIdSnapshot: null,
        categoryNameSnapshot: null,
        speciesNameSnapshot: null,
      );

  group('computeClientKpis', () {
    test('liste vide → 0 interventions, revenue 0, lastDate null', () {
      final k = computeClientKpis([]);
      expect(k.interventionCount, 0);
      expect(k.totalRevenueCents, 0);
      expect(k.lastInterventionDate, isNull);
      expect(k.firstInterventionDate, isNull);
    });

    test('count = nombre d\'interventions', () {
      final k = computeClientKpis([
        _interv(date: DateTime(2025, 9, 3), kind: InterventionKind.tour),
        _interv(date: DateTime(2024, 9, 1), kind: InterventionKind.tour),
        _interv(date: DateTime(2025, 5, 18), kind: InterventionKind.manual),
      ]);
      expect(k.interventionCount, 3);
    });

    test('revenue = somme priceCentsSnapshot × qty sur toutes prestations', () {
      final k = computeClientKpis([
        _interv(
          date: DateTime(2025, 9, 3),
          kind: InterventionKind.tour,
          prestations: [_row(3, 6000), _row(1, 4000)],
        ),
        _interv(
          date: DateTime(2024, 9, 1),
          kind: InterventionKind.tour,
          prestations: [_row(2, 5000)],
        ),
      ]);
      expect(k.totalRevenueCents, 3 * 6000 + 1 * 4000 + 2 * 5000);
    });

    test('lastInterventionDate = max ; firstInterventionDate = min', () {
      final k = computeClientKpis([
        _interv(date: DateTime(2025, 9, 3), kind: InterventionKind.tour),
        _interv(date: DateTime(2024, 9, 1), kind: InterventionKind.tour),
        _interv(date: DateTime(2025, 5, 18), kind: InterventionKind.manual),
      ]);
      expect(k.lastInterventionDate, DateTime(2025, 9, 3));
      expect(k.firstInterventionDate, DateTime(2024, 9, 1));
    });
  });
}
```

- [ ] **Step 2: Lancer → fail**

```
flutter test test/state/providers/client_kpis_test.dart
```

Expected: FAIL — `computeClientKpis` n'existe pas.

- [ ] **Step 3: Créer `lib/state/providers/client_kpis.dart`**

```dart
// lib/state/providers/client_kpis.dart
//
// KPIs de Client detail. Calcule à partir de l'historique des interventions
// (déjà fourni par historyForClientProvider) :
// - nb interventions
// - revenu cumulé (somme priceCentsSnapshot × qty)
// - première / dernière intervention (pour years-of-relationship affichage).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/intervention.dart';
import '../providers.dart';

class ClientKpis {
  final int interventionCount;
  final int totalRevenueCents;
  final DateTime? firstInterventionDate;
  final DateTime? lastInterventionDate;

  const ClientKpis({
    required this.interventionCount,
    required this.totalRevenueCents,
    this.firstInterventionDate,
    this.lastInterventionDate,
  });
}

ClientKpis computeClientKpis(List<Intervention> interventions) {
  if (interventions.isEmpty) {
    return const ClientKpis(interventionCount: 0, totalRevenueCents: 0);
  }
  var revenue = 0;
  DateTime? firstDate;
  DateTime? lastDate;
  for (final it in interventions) {
    for (final p in it.prestations) {
      revenue += p.priceCentsSnapshot * p.qty;
    }
    if (firstDate == null || it.date.isBefore(firstDate)) firstDate = it.date;
    if (lastDate == null || it.date.isAfter(lastDate)) lastDate = it.date;
  }
  return ClientKpis(
    interventionCount: interventions.length,
    totalRevenueCents: revenue,
    firstInterventionDate: firstDate,
    lastInterventionDate: lastDate,
  );
}

/// Provider qui dérive les KPIs depuis `historyForClientProvider`.
final clientKpisProvider =
    FutureProvider.family.autoDispose<ClientKpis, int>((ref, clientId) async {
  final interventions = await ref.watch(historyForClientProvider(clientId).future);
  return computeClientKpis(interventions);
});
```

- [ ] **Step 4: Lancer → pass**

```
flutter test test/state/providers/client_kpis_test.dart
```

Expected: PASS.

- [ ] **Step 5: `flutter analyze`** → 0 errors.

- [ ] **Step 6: Commit**

```bash
git add lib/state/providers/client_kpis.dart test/state/providers/client_kpis_test.dart
git commit -m "feat(state): add ClientKpis + clientKpisProvider"
```

---

### Task 5: Provider `clientCountByStatusProvider` (pour Map KpiRow)

**Files:**
- Create: `lib/state/providers/map_kpis.dart`

- [ ] **Step 1: Créer le provider**

```dart
// lib/state/providers/map_kpis.dart
//
// KPI de la Map : count de clients par statut. Utilisé pour l'AppKpiRow
// flottante de la Map (chips tappables qui togglent l'affichage par statut).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/use_cases/client_status.dart';
import '../providers.dart';

/// Map de `ClientStatus → nombre de clients dans cet état`.
final clientCountByStatusProvider =
    FutureProvider.autoDispose<Map<ClientStatus, int>>((ref) async {
  final settings = await ref.watch(settingsRepositoryProvider).read();
  final seasonStart =
      settings?.seasonStartedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final all = await ref
      .watch(clientRepositoryProvider)
      .listAllWithStatus(seasonStart);
  final out = <ClientStatus, int>{
    for (final s in ClientStatus.values) s: 0,
  };
  for (final r in all) {
    out[r.$2] = (out[r.$2] ?? 0) + 1;
  }
  return out;
});
```

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/state/providers/map_kpis.dart
git commit -m "feat(state): add clientCountByStatusProvider for Map KPIs"
```

---

## Phase 1 — Tour detail refactor

Layout cible (rappel spec §3.1) :

```
AppHeader [back] · "Tournée du 12 mai" · sub "Mardi · 5 stops · planifiée" · [⋯ menu]
  AppKpiRow [47.2 km | 6h12 | 480 € | 12 animaux]
  Trajet (mini-map)
  Étapes (AppListTile rich par stop)
  Résumé prestations (AppSectionCard avec liste agg)
AppActionBar [« Compléter la tournée »] (si planned)
```

### Task 6: Réécrire `tour_detail_screen.dart` avec scaffold + KpiRow + ActionBar

**Files:**
- Modify: `lib/presentation/tours/tour_detail_screen.dart` (réécriture intégrale)

- [ ] **Step 1: Lire le fichier existant pour identifier les imports/helpers utilisés**

```
flutter analyze lib/presentation/tours/tour_detail_screen.dart
```

Note les helpers consommés : `formatEuros`, `formatDuration`, `formatHm`, `mapPendingFocusProvider`, `mapSelectedClientIdProvider`, `tourByIdProvider`. Le partage `SharePlus`. Tous restent utiles.

- [ ] **Step 2: Réécrire le fichier intégralement**

Remplacer le contenu de `lib/presentation/tours/tour_detail_screen.dart` par :

```dart
// lib/presentation/tours/tour_detail_screen.dart
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

import '../../core/design_tokens.dart';
import '../../core/format_minutes.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/tour_repository.dart';
import '../../domain/models/animal_count.dart';
import '../../domain/models/tour.dart';
import '../../domain/models/tour_stop.dart';
import '../../state/map_controller.dart';
import '../../state/providers.dart';
import '../../state/providers/tour_kpis.dart';
import '../widgets/animal_counts_badges.dart';
import '../widgets/app_action_bar.dart';
import '../widgets/app_header.dart';
import '../widgets/app_kpi_row.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
import '../widgets/app_stat.dart';
import '../widgets/mini_map.dart';

class TourDetailScreen extends ConsumerWidget {
  final int tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(tourByIdProvider(tourId));

    return FScaffold(
      child: SafeArea(
        top: true,
        bottom: false,
        child: async.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (bundle) {
            if (bundle == null) return const SizedBox.shrink();
            final completed = bundle.tour.status == TourStatus.completed;
            final dateStr = DateFormat('EEE d MMM yyyy', 'fr')
                .format(bundle.tour.plannedDate);
            final dayStr = DateFormat('EEEE', 'fr')
                .format(bundle.tour.plannedDate);
            final statusLabel = completed
                ? l.tourStatusCompleted
                : l.tourStatusPlanned;
            return Column(
              children: [
                AppHeader(
                  title: dateStr,
                  subtitle:
                      '${dayStr[0].toUpperCase()}${dayStr.substring(1)} · ${bundle.stops.length} stops · $statusLabel',
                  actions: [
                    AppHeaderAction(
                      icon: FIcons.share2,
                      label: 'Partager',
                      onPress: () => _share(bundle, context, l),
                    ),
                  ],
                ),
                Expanded(
                  child: _Body(bundle: bundle, tourId: tourId),
                ),
                if (!completed)
                  AppActionBar(
                    primary: AppPrimaryButton(
                      label: l.tourDetailComplete,
                      onPress: () => context.push('/tours/$tourId/complete'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _share(
      TourWithStops bundle, BuildContext context, AppLocalizations l) async {
    final dateLine = DateFormat('dd/MM/yyyy').format(bundle.tour.plannedDate);
    final lines = <String>[
      'Tournée du $dateLine',
      ...bundle.stops.map(
        (s) => '- ${s.clientNameSnapshot} : ${formatEuros(s.feeShareCents)}',
      ),
      'Total : ${formatEuros(bundle.tour.totalTravelFeeCents)}',
    ];
    await SharePlus.instance.share(
      ShareParams(text: lines.join('\n'), subject: 'Tournée du $dateLine'),
    );
  }
}

class _Body extends ConsumerWidget {
  final TourWithStops bundle;
  final int tourId;
  const _Body({required this.bundle, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final completed = bundle.tour.status == TourStatus.completed;
    final km = (bundle.tour.totalDistanceMeters / 1000).toStringAsFixed(1);
    final driveMin = bundle.tour.totalDriveSeconds ~/ 60;

    final source = completed
        ? bundle.stops.map((s) => s.actualPrestations ?? s.plannedPrestations).toList()
        : bundle.stops.map((s) => s.plannedPrestations).toList();
    final summary = aggregatePrestations(source);
    final totalCents =
        summary.fold<int>(0, (s, r) => s + r.totalCents) +
            bundle.tour.totalTravelFeeCents;
    final totalAnimals =
        source.fold<int>(0, (s, list) => s + list.fold<int>(0, (a, p) => a + p.qty));

    final settingsAsync = ref.watch(settingsRepositoryFutureProvider);
    final base = settingsAsync.value?.baseCoordinates;

    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KpiRow
          AppKpiRow(
            cells: [
              AppKpiCell(value: '$km', label: 'km'),
              AppKpiCell(value: formatDuration(driveMin), label: 'durée'),
              AppKpiCell(
                value: formatEuros(totalCents),
                label: 'revenu',
                valueColor: theme.colors.secondary,
              ),
              AppKpiCell(value: '$totalAnimals', label: 'animaux'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // MiniMap
          if (base != null && bundle.stops.isNotEmpty) ...[
            MiniMap(
              base: LatLng(base.lat, base.lon),
              waypoints: [
                for (final s in bundle.stops)
                  LatLng(s.coordinates.lat, s.coordinates.lon),
              ],
              height: 160,
              onTap: () {
                ref.read(mapPendingFocusProvider.notifier).state = null;
                context.go('/map');
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Étapes
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
            child: Text(
              l.tourDetailScheduleTitle,
              style: theme.typography.xl.copyWith(color: theme.colors.foreground),
            ),
          ),
          for (var i = 0; i < bundle.stops.length; i++) ...[
            _StopTile(stop: bundle.stops[i], index: i + 1, l: l),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.md),

          // Résumé prestations agg
          AppSectionCard(
            icon: FIcons.listChecks,
            title: 'Résumé prestations',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in summary)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: theme.typography.md.copyWith(
                              color: theme.colors.foreground,
                            ),
                          ),
                        ),
                        Text(
                          '×${s.qty}',
                          style: tabularStyle(theme.typography.sm).copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        SizedBox(
                          width: 72,
                          child: Text(
                            formatEuros(s.totalCents),
                            textAlign: TextAlign.end,
                            style: tabularStyle(theme.typography.md).copyWith(
                              color: theme.colors.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (bundle.tour.totalTravelFeeCents > 0) ...[
                  Container(
                    height: AppSizes.hairlineBorder,
                    color: theme.colors.border,
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Frais déplacement',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        Text(
                          formatEuros(bundle.tour.totalTravelFeeCents),
                          style: tabularStyle(theme.typography.sm).copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Container(
                  height: AppSizes.hairlineBorder,
                  color: theme.colors.border,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total',
                          style: theme.typography.lg.copyWith(
                            color: theme.colors.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        formatEuros(totalCents),
                        style: tabularStyle(theme.typography.xl).copyWith(
                          color: theme.colors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.bottomScrollPadding),
        ],
      ),
    );
  }
}

class _StopTile extends ConsumerWidget {
  final TourStop stop;
  final int index;
  final AppLocalizations l;
  const _StopTile({required this.stop, required this.index, required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final clientId = stop.clientId;
    final source = stop.actualPrestations ?? stop.plannedPrestations;
    final counts = [
      for (final a in source)
        if (a.categoryIdSnapshot != null)
          AnimalCount(categoryId: a.categoryIdSnapshot!, count: a.qty),
    ];

    final indexBadge = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: theme.colors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: theme.typography.sm.copyWith(
          color: theme.colors.primaryForeground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final stopMin = source.fold<int>(0, (sum, p) => sum + p.qty * p.minutesSnapshot);

    return AppListTile(
      variant: AppListTileVariant.rich,
      prefix: indexBadge,
      title: clientId == null
          ? '${stop.clientNameSnapshot} ${l.tourDetailDeleted}'
          : stop.clientNameSnapshot,
      subtitle:
          '${formatHm(stop.estimatedArrivalMinutes)} → ${formatHm(stop.estimatedDepartureMinutes)}',
      metadata: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xxs,
        children: [
          AppStat(
            icon: FIcons.banknote,
            value: formatEuros(stop.feeShareCents),
          ),
          AppStat(
            icon: FIcons.clock,
            value: formatDuration(stopMin),
          ),
          if (counts.isNotEmpty)
            AnimalCountsBadges(
              counts: counts,
              mode: AnimalCountsBadgesMode.compact,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
        ],
      ),
      suffix: Icon(FIcons.chevronRight, color: theme.colors.mutedForeground),
      onTap: clientId == null
          ? null
          : () {
              ref.read(mapPendingFocusProvider.notifier).state = clientId;
              ref.read(mapSelectedClientIdProvider.notifier).state = clientId;
              context.go('/map');
            },
    );
  }
}
```

- [ ] **Step 3: Vérifier que `settingsRepositoryFutureProvider` existe**

```
grep -n "settingsRepositoryFutureProvider" lib/state/providers.dart
```

S'il n'existe pas (probable), l'ajouter dans `lib/state/providers.dart` après le bloc `settingsRepositoryProvider` :

```dart
final settingsRepositoryFutureProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(settingsRepositoryProvider).read();
});
```

- [ ] **Step 4: Vérifier que les clés `l.tourStatusCompleted` et `l.tourStatusPlanned` existent**

```
grep -n "tourStatusCompleted\|tourStatusPlanned" lib/l10n/app_fr.arb
```

Si absentes, ajouter à `lib/l10n/app_fr.arb` :

```json
  "tourStatusCompleted": "complétée",
  "tourStatusPlanned": "planifiée",
```

et à `lib/l10n/app_en.arb` :

```json
  "tourStatusCompleted": "completed",
  "tourStatusPlanned": "planned",
```

Régénérer : `flutter gen-l10n` (ou laisser build_runner — vérifier la config locale).

- [ ] **Step 5: `flutter analyze`**

```
flutter analyze
```

Expected: 0 errors. Si TourStop n'a pas de `coordinates`, vérifier le modèle (probable : il y a `coordinates` ou un getter ; sinon utiliser `clientId` pour récupérer via lookup côté MiniMap — adapter en conséquence).

- [ ] **Step 6: Lancer les tests existants**

```
flutter test
```

Expected: tous tests verts.

- [ ] **Step 7: Smoke test manuel**

Lancer l'app sur device/émulateur. Naviguer vers une tournée existante. Vérifier :
- KpiRow s'affiche avec 4 valeurs
- MiniMap s'affiche avec route + pins numérotés
- Stops affichent index circle, titre, horaires, et metadata (revenu/durée/animaux)
- Section « Résumé prestations » liste les prestations agrégées + total
- AppActionBar « Compléter la tournée » sticky bottom (uniquement si planned)
- Header affiche date + sous-titre stats, bouton Partager (label si écran ≥360dp)

- [ ] **Step 8: Commit**

```bash
git add lib/presentation/tours/tour_detail_screen.dart lib/state/providers.dart lib/l10n/
git commit -m "refactor(tour-detail): rebuild with AppHeader/AppKpiRow/MiniMap/AppListTile/AppActionBar"
```

---

## Phase 2 — Client detail refactor

Layout cible (rappel spec §3.2) :

```
AppHeader [back] · "Mme Kervella" · sub "Plouguerneau · client depuis 2024" · [⋯ menu = Supprimer]
  AppKpiRow [3 ans | 14 interv | 1240 € | il y a 8 mois]
  Status chip + saison
  AppSectionCard "Prochaine action" [planifier ou voir tournée]
  AppSectionCard "Animaux" (AnimalCountsBadges detailed)
  AppSectionCard "Coordonnées" (adresse + actions, phones + appel/sms)
  AppSectionCard "Notes" (si présentes)
  AppSectionCard "Status & actions" (waiting/banned/reset — gardé tel quel)
  AppSectionCard "Historique" (3 dernières AppTimelineRow + lien)
AppActionBar [+ Tonte manuelle outline | Modifier outline]
```

### Task 7: Réécrire `client_detail_screen.dart`

**Files:**
- Modify: `lib/presentation/clients/client_detail_screen.dart` (réécriture intégrale)

- [ ] **Step 1: Lire le fichier existant pour la structure et les helpers**

```
flutter analyze lib/presentation/clients/client_detail_screen.dart
```

Note les helpers : `_clientByIdProvider`, `_plannedTourForClientProvider`, `_statusLabel`, `callPhone`/`sendSms` (importés de `client_actions.dart`).

- [ ] **Step 2: Réécrire `lib/presentation/clients/client_detail_screen.dart`**

Remplacer le contenu par (note : les sections Status & actions internes — waiting toggle, ban, reset — restent identiques, juste enveloppées dans la nouvelle structure) :

```dart
// lib/presentation/clients/client_detail_screen.dart
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../core/format_minutes.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/confirm_dialog.dart';
import 'client_actions.dart';
import '../../domain/models/animal_count.dart';
import '../../domain/models/client.dart';
import 'manual_history_entry_sheet.dart';
import '../../domain/models/intervention.dart';
import '../../domain/use_cases/client_status.dart';
import '../../infra/services/ors_routing_service.dart';
import '../../state/providers.dart';
import '../../state/providers/client_kpis.dart';
import '../widgets/animal_counts_badges.dart';
import '../widgets/app_action_bar.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_header.dart';
import '../widgets/app_kpi_row.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
import '../widgets/app_timeline_row.dart';
import 'clients_list_screen.dart' show clientsAsyncProvider, clientsPendingProvider;

final _clientByIdProvider =
    FutureProvider.family<(Client, ClientStatus)?, int>((ref, id) async {
  final settings = await ref.watch(settingsRepositoryProvider).read();
  final seasonStart = settings?.seasonStartedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  return ref.watch(clientRepositoryProvider).findByIdWithStatus(id, seasonStart);
});

class ClientDetailScreen extends ConsumerWidget {
  final int clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_clientByIdProvider(clientId));
    final l = AppLocalizations.of(context)!;

    return FScaffold(
      child: SafeArea(
        top: true,
        bottom: false,
        child: async.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (record) {
            if (record == null) return const SizedBox.shrink();
            final client = record.$1;
            final status = record.$2;
            final yearsAgo = client.lastInterventionDate == null
                ? null
                : DateTime.now().year - client.lastInterventionDate!.year;
            final subtitle = '${client.city} · client'
                '${yearsAgo == null ? '' : ' depuis ${DateTime.now().year - (yearsAgo == 0 ? DateTime.now().year : yearsAgo)}'}';
            return Column(
              children: [
                AppHeader(
                  title: client.name,
                  subtitle: client.city,
                  actions: [
                    AppHeaderAction(
                      icon: FIcons.trash,
                      label: l.clientDetailDelete,
                      destructive: true,
                      onPress: () => _confirmDelete(context, ref, l),
                    ),
                  ],
                ),
                Expanded(
                  child: _Body(client: client, status: status),
                ),
                AppActionBar(
                  secondary: AppPrimaryButton(
                    label: l.clientHistoryAddAction,
                    variant: FButtonVariant.outline,
                    onPress: () => showManualHistoryEntrySheet(
                      context,
                      clientId: client.id,
                    ),
                  ),
                  primary: AppPrimaryButton(
                    label: 'Modifier',
                    variant: FButtonVariant.outline,
                    onPress: () => context.push('/clients/${client.id}/edit'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final ok = await showDestructiveConfirm(
      context,
      title: l.clientDetailDelete,
      body: l.clientDetailDeleteConfirm,
      confirmLabel: l.clientDetailDelete,
    );
    if (!ok) return;
    await ref.read(clientRepositoryProvider).delete(clientId);
    await ref.read(distanceMatrixRepositoryProvider).deleteForClient(clientId);
    ref.invalidate(_clientByIdProvider(clientId));
    ref.invalidate(clientsAsyncProvider);
    ref.invalidate(clientsPendingProvider);
    if (context.mounted) context.pop();
  }
}

class _Body extends ConsumerWidget {
  final Client client;
  final ClientStatus status;
  const _Body({required this.client, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final kpisAsync = ref.watch(clientKpisProvider(client.id));
    final plannedTourAsync = ref.watch(_plannedTourForClientProvider(client.id));

    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KpiRow synthèse
          kpisAsync.when(
            loading: () => const SizedBox(height: 80),
            error: (_, __) => const SizedBox.shrink(),
            data: (kpis) => AppKpiRow(
              cells: [
                AppKpiCell(
                  value: '${kpis.interventionCount}',
                  label: 'interv',
                ),
                AppKpiCell(
                  value: kpis.totalRevenueCents == 0
                      ? '—'
                      : formatEuros(kpis.totalRevenueCents),
                  label: 'revenu',
                  valueColor: theme.colors.secondary,
                ),
                AppKpiCell(
                  value: kpis.lastInterventionDate == null
                      ? '—'
                      : _relativeShort(kpis.lastInterventionDate!),
                  label: 'dernière',
                ),
                AppKpiCell(
                  value: kpis.firstInterventionDate == null
                      ? '—'
                      : '${DateTime.now().year - kpis.firstInterventionDate!.year + 1}',
                  label: 'an(s)',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Status badge inline
          Row(
            children: [
              AppBadge.fromStatus(
                context,
                status: status,
                label: _statusLabel(l, status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Prochaine action
          plannedTourAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (date) => AppSectionCard(
              icon: FIcons.calendar,
              title: 'Prochaine action',
              child: date == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Aucune tournée planifiée',
                          style: theme.typography.md.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppPrimaryButton(
                          label: l.clientDetailFindNearby,
                          onPress: status == ClientStatus.waiting
                              ? () => context.push('/proximity/${client.id}')
                              : null,
                        ),
                      ],
                    )
                  : Text(
                      'Tournée planifiée le ${DateFormat('EEEE d MMMM', 'fr').format(date)}',
                      style: theme.typography.md.copyWith(
                        color: theme.colors.foreground,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Recompute banner (gardé)
          if (client.needsDistanceRecompute) ...[
            AppSectionCard(
              icon: FIcons.triangleAlert,
              title: 'Distances',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.clientDetailRecomputeBanner,
                      style: theme.typography.sm,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FButton(
                    variant: FButtonVariant.outline,
                    size: FButtonSizeVariant.sm,
                    onPress: () async {
                      final sync = ref.read(distanceMatrixSyncProvider);
                      try {
                        await sync.recomputeForClient(client.id);
                        ref.invalidate(_clientByIdProvider(client.id));
                        ref.invalidate(clientsAsyncProvider);
                        ref.invalidate(clientsPendingProvider);
                      } on OrsException catch (e) {
                        if (context.mounted) {
                          showFToast(context: context, title: Text(e.message));
                        }
                      }
                    },
                    child: Text(l.clientDetailRetryRecompute),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Animaux
          if (client.animals.isNotEmpty) ...[
            AppSectionCard(
              icon: FIcons.pawPrint,
              title: 'Animaux',
              child: AnimalCountsBadges(
                counts: client.animals,
                mode: AnimalCountsBadgesMode.detailed,
                style: theme.typography.md.copyWith(
                  color: theme.colors.foreground,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Coordonnées
          AppSectionCard(
            icon: FIcons.mapPin,
            title: l.clientDetailSectionAddress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.addressLabel, style: theme.typography.md),
                Text(
                  '${client.postcode} ${client.city}',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Phones
          if (client.phones.isNotEmpty) ...[
            AppSectionCard(
              icon: FIcons.phone,
              title: l.clientDetailSectionContact,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < client.phones.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Icon(FIcons.phone, color: theme.colors.mutedForeground, size: 16),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            client.phones[i],
                            style: tabularStyle(theme.typography.md),
                          ),
                        ),
                        if (i == 0)
                          Text(
                            'principal',
                            style: theme.typography.xs.copyWith(
                              color: theme.colors.mutedForeground,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: FButton(
                            variant: FButtonVariant.outline,
                            prefix: const Icon(FIcons.phone),
                            onPress: () => callPhone(context, client.phones[i]),
                            child: const Text('Appeler'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FButton(
                            variant: FButtonVariant.outline,
                            prefix: const Icon(FIcons.messageCircle),
                            onPress: () => sendSms(context, client.phones[i]),
                            child: const Text('SMS'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Status & actions section (gardé tel quel mais wrappé)
          _StatusActionsCard(client: client, status: status, l: l),
          const SizedBox(height: AppSpacing.md),

          // Historique (3 derniers + lien)
          _InterventionsCard(clientId: client.id),
          const SizedBox(height: AppSizes.bottomScrollPadding),
        ],
      ),
    );
  }

  String _relativeShort(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays < 30) return 'il y a ${diff.inDays}j';
    final months = (diff.inDays / 30).round();
    if (months < 12) return 'il y a ${months}m';
    final years = (months / 12).round();
    return 'il y a ${years}an${years > 1 ? 's' : ''}';
  }
}

class _StatusActionsCard extends ConsumerWidget {
  final Client client;
  final ClientStatus status;
  final AppLocalizations l;
  const _StatusActionsCard(
      {required this.client, required this.status, required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final waitingToggleDisabled = status == ClientStatus.banned ||
        status == ClientStatus.noAnimals ||
        status == ClientStatus.scheduled ||
        status == ClientStatus.done;

    return AppSectionCard(
      icon: FIcons.bellRing,
      title: l.clientDetailSectionStatus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FTile(
            title: Text(l.clientStatusWaiting),
            subtitle: waitingToggleDisabled
                ? Text(
                    l.clientDetailWaitingDisabledHintFmt(
                      _statusLabel(l, status),
                    ),
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  )
                : null,
            suffix: FSwitch(
              value: client.isWaiting,
              onChange: waitingToggleDisabled
                  ? null
                  : (v) async {
                      await ref
                          .read(clientRepositoryProvider)
                          .setWaiting(id: client.id, isWaiting: v);
                      ref.invalidate(_clientByIdProvider(client.id));
                      ref.invalidate(clientsAsyncProvider);
                    },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FButton(
            variant: client.isBanned
                ? FButtonVariant.outline
                : FButtonVariant.destructive,
            prefix: Icon(client.isBanned ? FIcons.shieldOff : FIcons.ban),
            onPress: () async {
              await ref
                  .read(clientRepositoryProvider)
                  .setBanned(client.id, !client.isBanned);
              ref.invalidate(_clientByIdProvider(client.id));
              ref.invalidate(clientsAsyncProvider);
            },
            child: Text(
              client.isBanned ? l.clientDetailUnban : l.clientDetailBan,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ResetToDefaultButton(client: client),
        ],
      ),
    );
  }
}

String _statusLabel(AppLocalizations l, ClientStatus status) => switch (status) {
      ClientStatus.defaultStatus => l.clientStatusDefault,
      ClientStatus.waiting => l.clientStatusWaiting,
      ClientStatus.scheduled => l.clientStatusScheduled,
      ClientStatus.done => l.clientStatusDone,
      ClientStatus.noAnimals => l.clientStatusNoAnimals,
      ClientStatus.banned => l.clientStatusBanned,
    };

class _ResetToDefaultButton extends ConsumerWidget {
  final Client client;
  const _ResetToDefaultButton({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final plannedTourAsync = ref.watch(_plannedTourForClientProvider(client.id));

    return plannedTourAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tourDate) {
        final blocked = tourDate != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FButton(
              variant: FButtonVariant.outline,
              prefix: const Icon(FIcons.rotateCcw),
              onPress: blocked
                  ? null
                  : () async {
                      final repo = ref.read(clientRepositoryProvider);
                      await repo.setWaiting(id: client.id, isWaiting: false);
                      await repo.setBanned(client.id, false);
                      ref.invalidate(_clientByIdProvider(client.id));
                      ref.invalidate(clientsAsyncProvider);
                    },
              child: Text(l.clientDetailResetToDefault),
            ),
            if (blocked) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.clientDetailResetDisabledFmt(
                  DateFormat('dd/MM/yyyy').format(tourDate),
                ),
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

final _plannedTourForClientProvider =
    FutureProvider.family.autoDispose<DateTime?, int>((ref, clientId) async {
  final settings = await ref.watch(settingsRepositoryProvider).read();
  final seasonStart = settings?.seasonStartedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  final db = ref.watch(appDatabaseProvider);
  final seasonEpochDays = seasonStart.millisecondsSinceEpoch ~/ 86400000;

  final rows = await (db.select(db.tourStopsTable).join([
    innerJoin(db.toursTable, db.toursTable.id.equalsExp(db.tourStopsTable.tourId)),
  ])
        ..where(
          db.tourStopsTable.clientId.equals(clientId) &
              db.toursTable.status.equals('planned') &
              db.toursTable.plannedDate.isBiggerOrEqualValue(seasonEpochDays),
        )
        ..orderBy([
          OrderingTerm.asc(db.toursTable.plannedDate),
        ])
        ..limit(1))
      .get();

  if (rows.isEmpty) return null;
  final tour = rows.first.readTable(db.toursTable);
  return DateTime.fromMillisecondsSinceEpoch(tour.plannedDate * 86400000);
});

class _InterventionsCard extends ConsumerWidget {
  final int clientId;
  const _InterventionsCard({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final async = ref.watch(historyForClientProvider(clientId));

    return AppSectionCard(
      icon: FIcons.history,
      title: l.clientDetailSectionHistory,
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Center(child: FCircularProgress()),
        ),
        error: (e, _) => Text('$e'),
        data: (items) {
          final visible = items.take(3).toList();
          final hasMore = items.length > visible.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (items.isEmpty)
                Text(
                  l.clientDetailHistoryEmpty,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                )
              else
                for (final it in visible) ...[
                  AppTimelineRow(
                    dateLabel: DateFormat('d MMM yyyy', 'fr').format(it.date),
                    icon: it.kind == InterventionKind.manual
                        ? FIcons.pencil
                        : FIcons.scissors,
                    title: it.kind == InterventionKind.tour
                        ? 'Tournée'
                        : 'Saisie manuelle',
                    breakdown: _breakdown(it),
                    amount: it.totalRevenueCents == 0
                        ? null
                        : formatEuros(it.totalRevenueCents),
                    duration: it.totalMinutes == 0
                        ? null
                        : formatDuration(it.totalMinutes),
                    onTap: () async {
                      if (it.kind == InterventionKind.tour && it.tourId != null) {
                        context.push('/tours/${it.tourId}');
                        return;
                      }
                      if (it.kind == InterventionKind.manual &&
                          it.manualEntryId != null) {
                        final manualRepo =
                            ref.read(manualHistoryRepositoryProvider);
                        final all = await manualRepo.listForClient(clientId);
                        final matches =
                            all.where((e) => e.id == it.manualEntryId);
                        final entry = matches.isEmpty ? null : matches.first;
                        if (entry != null && context.mounted) {
                          await showManualHistoryEntrySheet(
                            context,
                            clientId: clientId,
                            existing: entry,
                          );
                        }
                      }
                    },
                  ),
                  if (it != visible.last)
                    Container(
                      height: AppSizes.hairlineBorder,
                      color: theme.colors.border,
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    ),
                ],
              if (hasMore) ...[
                const SizedBox(height: AppSpacing.sm),
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => context.push('/clients/$clientId/history'),
                  child: Text(l.clientDetailHistoryViewAll),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _breakdown(Intervention it) {
    final parts = <String>[];
    for (final p in it.prestations) {
      parts.add('${p.qty} ${p.nameSnapshot}');
      if (parts.length >= 3) break;
    }
    if (it.prestations.length > 3) {
      parts.add('et ${it.prestations.length - 3} autre(s)');
    }
    return parts.join(' · ');
  }
}
```

- [ ] **Step 3: Vérifier que `Intervention.totalRevenueCents` et `totalMinutes` existent**

```
grep -n "totalRevenueCents\|totalMinutes" lib/domain/models/intervention.dart
```

S'ils n'existent pas (en réalité `totalRevenueCents` existe sous une autre forme — voir la méthode privée vers ligne 47), exposer-les. Adapter le code de l'étape 2 si nécessaire (ex. `it.totalRevenueCents()` méthode au lieu de getter).

- [ ] **Step 4: Vérifier que `AppPrimaryButton` accepte un `variant`**

Lire `lib/presentation/widgets/app_primary_button.dart` (déjà fait en Plan 1) — confirmer que le param `variant` existe (oui, défaut `FButtonVariant.primary`).

- [ ] **Step 5: `flutter analyze`**

```
flutter analyze
```

Expected: 0 errors. Si compilation échoue, ajuster les API (voir step 3).

- [ ] **Step 6: `flutter test`**

```
flutter test
```

Expected: tous tests verts.

- [ ] **Step 7: Smoke test manuel**

Naviguer vers la fiche d'un client. Vérifier :
- KpiRow synthèse (interv / revenu / dernière / années)
- Status badge sous le KpiRow
- Section « Prochaine action » s'affiche (planifiée OU CTA proximity)
- Sections Animaux / Coordonnées / Phones rendent correctement
- Historique avec AppTimelineRow x3 + bouton « Voir tout »
- AppActionBar bottom : `+ Tonte manuelle outline` + `Modifier outline`
- Header : titre + sous-titre ville, bouton trash destructive en suffixe
- Confirm dialog au tap delete

- [ ] **Step 8: Commit**

```bash
git add lib/presentation/clients/client_detail_screen.dart
git commit -m "refactor(client-detail): rebuild with AppKpiRow/AppTimelineRow/AppActionBar/Prochaine action"
```

---

## Phase 3 — Tour completion refactor

Layout cible (rappel spec §3.3) :

```
AppHeader [back] · "Bilan tournée du 12 mai" · sub "5 stops · prévu 480 €"
  AppKpiRow live [5/5 stops | 470 € | 6h35 | Δ -10 €]
  Stop ① · M. Le Goff (AppSectionCard avec AppDiffRow par presta)
    [+ Ajouter une prestation]
    Sous-total : 180 € · 45m
  Stop ② … (pareil)
  ...
  Notes globales (FTextField multi-line)
AppActionBar [« Valider la tournée »]
+ confirm dialog avant validation
```

### Task 8: Refactor `tour_completion_screen.dart`

**Files:**
- Modify: `lib/presentation/tours/tour_completion_screen.dart`

- [ ] **Step 1: Réécrire le fichier intégralement**

Garder le state class `_TourCompletionScreenState`, `_StopDraft`, `_StopRow`, `_OffPlanPickerSheet` en l'état. Ne refactor que le `build` (header + body layout) et `_PrestationRowEditor` (passer en `AppDiffRow`).

Remplacer **uniquement la méthode `build` et la classe `_PrestationRowEditor`** dans `lib/presentation/tours/tour_completion_screen.dart` :

Méthode `build` (lignes 186 à 308 environ — remplacer par) :

```dart
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final async = ref.watch(_tourForCompletionProvider(widget.tourId));

    return FScaffold(
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        top: true,
        bottom: false,
        child: async.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (bundle) {
            if (bundle == null) return const SizedBox.shrink();
            _ensureDrafts(bundle);
            final visibleStops =
                bundle.stops.where((s) => s.clientId != null).toList();
            final totals = _liveTotals();
            final feeCents = bundle.tour.totalTravelFeeCents;
            final plannedRevenue = bundle.stops.fold<int>(
                0,
                (s, st) =>
                    s +
                    st.plannedPrestations.fold<int>(
                        0, (a, p) => a + p.priceCentsSnapshot * p.qty));
            final actualRevenue = totals.revenueCents + feeCents;
            final delta = actualRevenue - plannedRevenue - feeCents;
            final stopsValidated = _drafts.values
                .where((d) => d.rows.any((r) => r.checked && r.qty > 0))
                .length;

            return Column(
              children: [
                AppHeader(
                  title: l.tourCompletionTitle,
                  subtitle:
                      '${visibleStops.length} stops · prévu ${formatEuros(plannedRevenue + feeCents)}',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: AppKpiRow(
                    cells: [
                      AppKpiCell(
                        value: '$stopsValidated/${visibleStops.length}',
                        label: 'stops',
                      ),
                      AppKpiCell(
                        value: formatEuros(actualRevenue),
                        label: 'revenu',
                        valueColor: theme.colors.secondary,
                      ),
                      AppKpiCell(
                        value: formatDuration(totals.minutes),
                        label: 'durée',
                      ),
                      AppKpiCell(
                        value: delta == 0
                            ? '0 €'
                            : (delta > 0 ? '+' : '') + formatEuros(delta),
                        label: 'Δ vs prévu',
                        valueColor: delta == 0
                            ? theme.colors.mutedForeground
                            : (delta > 0
                                ? theme.colors.primary
                                : theme.colors.destructive),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.separated(
                    padding: AppSizes.screenPadding,
                    itemCount: visibleStops.length + 1, // +1 for notes
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) {
                      if (i == visibleStops.length) {
                        // Notes globales
                        return AppSectionCard(
                          icon: FIcons.stickyNote,
                          title: 'Notes globales',
                          child: Text(
                            l.tourCompletionNoteHint,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }
                      final s = visibleStops[i];
                      final draft = _drafts[s.id]!;
                      final stopMin = draft.rows.fold<int>(
                          0,
                          (acc, r) =>
                              acc +
                              (r.checked && r.qty > 0 ? r.qty * r.minutesSnapshot : 0));
                      final stopRev = draft.rows.fold<int>(
                          0,
                          (acc, r) =>
                              acc +
                              (r.checked && r.qty > 0 ? r.qty * r.priceCentsSnapshot : 0));
                      // Map planned qty by prestationId
                      final plannedById = {
                        for (final p in s.plannedPrestations) p.prestationId: p.qty,
                      };
                      return AppSectionCard(
                        icon: FIcons.user,
                        title: '${i + 1} · ${s.clientNameSnapshot}',
                        trailing: Text(
                          '${formatEuros(stopRev)} · ${formatDuration(stopMin)}',
                          style: tabularStyle(theme.typography.sm).copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var ri = 0; ri < draft.rows.length; ri++)
                              _PrestationRowEditor(
                                row: draft.rows[ri],
                                planned: plannedById[draft.rows[ri].prestationId] ?? 0,
                                onCheckedChanged: (v) =>
                                    setState(() => draft.rows[ri].checked = v),
                                onQtyChanged: (q) =>
                                    setState(() => draft.rows[ri].qty = q),
                              ),
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FButton(
                                variant: FButtonVariant.outline,
                                onPress: () => _addOffPlan(s.id),
                                child: Text(l.tourCompletionAddOffPlan),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FTextField(
                              control: FTextFieldControl.managed(
                                controller: draft.noteCtrl,
                              ),
                              label: Text(l.tourCompletionNoteHint),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                AppActionBar(
                  primary: AppPrimaryButton(
                    label: l.tourCompletionConfirm,
                    loading: _saving,
                    onPress: _saving
                        ? null
                        : () async {
                            final ok = await showDestructiveConfirm(
                              context,
                              title: 'Valider la tournée ?',
                              body:
                                  'Tu pourras encore éditer les prestations et compteurs animaux après.',
                              cancelLabel: 'Annuler',
                              confirmLabel: 'Valider',
                            );
                            if (ok && context.mounted) {
                              await _confirm(bundle);
                            }
                          },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
```

Classe `_PrestationRowEditor` (lignes 371 à 474 environ — remplacer par) :

```dart
class _PrestationRowEditor extends StatelessWidget {
  final _StopRow row;
  final int planned;
  final ValueChanged<bool> onCheckedChanged;
  final ValueChanged<int> onQtyChanged;

  const _PrestationRowEditor({
    required this.row,
    required this.planned,
    required this.onCheckedChanged,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final priceLabel = row.priceCentsSnapshot == 0
        ? null
        : formatEuros(row.priceCentsSnapshot * (row.checked ? row.qty : 0));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onCheckedChanged(!row.checked),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: row.checked ? theme.colors.primary : null,
                border: row.checked
                    ? null
                    : Border.all(color: theme.colors.border, width: 1.5),
              ),
              child: row.checked
                  ? Icon(FIcons.check,
                      color: theme.colors.primaryForeground, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppDiffRow(
              label: row.nameSnapshot,
              planned: planned,
              actual: row.checked ? row.qty : 0,
              amountLabel: priceLabel,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 56,
            child: FTextField(
              control: FTextFieldControl.managed(
                controller: row.qtyCtrl,
                onChange: (v) {
                  final q = int.tryParse(v.text) ?? 0;
                  onQtyChanged(q);
                },
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }
}
```

Adapter les imports en haut du fichier — ajouter :

```dart
import '../../core/theme/app_typography.dart';
import '../../core/ui/confirm_dialog.dart';
import '../widgets/app_action_bar.dart';
import '../widgets/app_diff_row.dart';
import '../widgets/app_header.dart';
import '../widgets/app_kpi_row.dart';
```

- [ ] **Step 2: `flutter analyze`**

```
flutter analyze
```

Expected: 0 errors.

- [ ] **Step 3: `flutter test`**

```
flutter test
```

Expected: tous tests verts (les tests de ce fichier dépendent de la repo, pas de l'UI).

- [ ] **Step 4: Smoke test manuel**

Compléter une tournée existante. Vérifier :
- Header avec titre + stops + revenu prévu
- KpiRow live qui se met à jour quand on coche/décoche/édite qty
- Chaque stop = AppSectionCard avec AppDiffRow par presta (montre planned → actual + delta visuel)
- Sous-total stop visible dans `trailing` du header de section card
- Confirm dialog avant validation
- Toast de succès au save

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/tours/tour_completion_screen.dart
git commit -m "refactor(tour-completion): rebuild with AppKpiRow live + AppDiffRow + confirm"
```

---

## Phase 4 — Map refactor

Layout cible (rappel spec §3.4) :

```
[FlutterMap full-screen]
[Overlay TOP] (search + layers button)
[Floating AppKpiRow] chips de status counts (tappables → toggle)
[Pin tap → bottom sheet riche]
[FAB me-localiser bottom-right]
```

### Task 9: Floating AppKpiRow status chips sur Map

**Files:**
- Modify: `lib/presentation/map/map_screen.dart`

- [ ] **Step 1: Ajouter le import**

En haut de `lib/presentation/map/map_screen.dart` ajouter :

```dart
import '../../state/providers/map_kpis.dart';
import '../widgets/app_badge.dart';
```

- [ ] **Step 2: Lire la structure du `Stack` existant**

```
grep -n "Stack\|Positioned\|FlutterMap" lib/presentation/map/map_screen.dart | head -20
```

Repérer où le `FlutterMap` est wrappé dans un `Stack` (probablement vers ligne 250-450). Identifier l'overlay top existant (search field + layers button).

- [ ] **Step 3: Ajouter un `Positioned` avec une rangée de status chips juste sous l'overlay top**

Dans le `Stack` du `_MapScreenState.build`, ajouter après le bloc de search overlay et **avant** le bloc des markers (ne pas modifier le FlutterMap lui-même) :

```dart
            // Status chips floating row
            Positioned(
              top: 80, // sous le search field (à ajuster selon padding existant)
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Consumer(
                builder: (context, ref, _) {
                  final countsAsync = ref.watch(clientCountByStatusProvider);
                  final visible = ref.watch(_visibleStatusesProvider);
                  return countsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (counts) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final status in ClientStatus.values)
                              if ((counts[status] ?? 0) > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      final next = {...visible};
                                      if (next.contains(status)) {
                                        next.remove(status);
                                      } else {
                                        next.add(status);
                                      }
                                      ref.read(_visibleStatusesProvider.notifier).state = next;
                                    },
                                    child: AppBadge.fromStatus(
                                      context,
                                      status: status,
                                      label: '${counts[status]} ${_statusLabelShort(context, status)}',
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
```

Note : `_visibleStatusesProvider` doit exister dans `map_screen.dart` (probable, similaire à `clients_list_screen.dart`). Si absent, l'ajouter en haut du fichier :

```dart
final _visibleStatusesProvider = StateProvider<Set<ClientStatus>>(
  (_) => ClientStatus.values.toSet(),
);
```

Et brancher `_visibleStatusesProvider` dans le filtre de `MarkerLayer` existant pour ne rendre que les pins des statuts actifs.

Helper `_statusLabelShort` à ajouter en bas du fichier :

```dart
String _statusLabelShort(BuildContext context, ClientStatus s) {
  final l = AppLocalizations.of(context)!;
  return switch (s) {
    ClientStatus.defaultStatus => l.clientStatusDefault,
    ClientStatus.waiting => l.clientStatusWaiting,
    ClientStatus.scheduled => l.clientStatusScheduled,
    ClientStatus.done => l.clientStatusDone,
    ClientStatus.noAnimals => l.clientStatusNoAnimals,
    ClientStatus.banned => l.clientStatusBanned,
  };
}
```

- [ ] **Step 4: Brancher le filtre par statut sur la `MarkerLayer`**

Localiser la construction des `Marker` dans `map_screen.dart` (recherche `Marker(`). Filtrer la list `markers` par `visible.contains(status)` avant de la passer à `MarkerLayer`.

- [ ] **Step 5: `flutter analyze`**

```
flutter analyze
```

Expected: 0 errors. Adapter top offset si overlay top a changé.

- [ ] **Step 6: Smoke test manuel**

Naviguer vers la Map. Vérifier :
- Sous le search bar, une rangée horizontale de chips colorés style status badges
- Tap sur un chip → les pins de ce status disparaissent (et le chip change visuellement) ou réapparaissent
- Compteurs corrects par statut

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/map/map_screen.dart
git commit -m "feat(map): add floating status chips with toggle and counts"
```

---

### Task 10: Refonte du sheet pin tap (rich)

**Files:**
- Modify: `lib/presentation/map/client_pin_popup.dart`

- [ ] **Step 1: Lire le fichier**

```
flutter analyze lib/presentation/map/client_pin_popup.dart
```

Note l'API publique exposée (typiquement `showClientPinPopup(context, client, ...)` ou similaire).

- [ ] **Step 2: Réécrire pour rendre le sheet riche**

Garder la signature publique. Remplacer le contenu rendu par un sheet plein-largeur avec 4 sections : header (nom + status), stats (animaux + dernière intervention), 3 actions (Voir fiche / Itinéraire / Planifier).

Ouvrir `lib/presentation/map/client_pin_popup.dart` et remplacer le `build` du sheet (ou la fonction qui rend le contenu) par :

```dart
import '../../core/format_minutes.dart';
import '../widgets/app_kpi_row.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/animal_counts_badges.dart';

// ... (dans la fonction qui construit le contenu du sheet)

Widget buildContent(BuildContext context, Client c, ClientStatus status) {
  final theme = context.theme;
  final l = AppLocalizations.of(context)!;
  final last = c.lastInterventionDate;
  final lastStr = last == null
      ? '—'
      : 'il y a ${DateTime.now().difference(last).inDays}j';

  return Container(
    color: theme.colors.background,
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md,
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.name,
                  style: theme.typography.xl2.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
              ),
              AppBadge.fromStatus(context, status: status, label: _statusLabelShort(context, status)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            c.city,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppKpiRow(
            cells: [
              AppKpiCell(value: '${c.animalsTotal}', label: 'animaux'),
              AppKpiCell(value: lastStr, label: 'dernière'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (c.animals.isNotEmpty)
            AnimalCountsBadges(
              counts: c.animals,
              mode: AnimalCountsBadgesMode.compact,
              style: theme.typography.sm,
            ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Voir la fiche',
            onPress: () {
              Navigator.of(context).pop();
              context.push('/clients/${c.id}');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FButton(
                  variant: FButtonVariant.outline,
                  prefix: const Icon(FIcons.compass),
                  onPress: () => Navigator.of(context).pop(_PopupAction.itinerary),
                  child: const Text('Itinéraire'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FButton(
                  variant: FButtonVariant.outline,
                  prefix: const Icon(FIcons.route),
                  onPress: () {
                    Navigator.of(context).pop();
                    context.push('/proximity/${c.id}');
                  },
                  child: const Text('Planifier'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
```

(Ajouter l'enum `_PopupAction` si pas déjà présent dans le fichier, et adapter le caller pour gérer `itinerary` — typiquement lancer un intent `geo:` via url_launcher.)

- [ ] **Step 3: `flutter analyze`** → 0 errors.

- [ ] **Step 4: Smoke test manuel**

Tap sur un pin de la Map. Vérifier :
- Sheet plein-largeur
- Nom client + badge status
- Ville en italique
- KpiRow [animaux | dernière intervention]
- Animaux compact en dessous (si présents)
- 3 boutons : « Voir la fiche » primary, « Itinéraire » + « Planifier » outline

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/map/client_pin_popup.dart
git commit -m "refactor(map): rich pin popup with KPIs and 3 actions"
```

---

### Task 11: FAB « me-localiser » sur Map

**Files:**
- Modify: `lib/presentation/map/map_screen.dart`

- [ ] **Step 1: Ajouter le FAB dans le `Stack` du Map**

Repérer la fin du `Stack` dans `_MapScreenState.build`. Ajouter avant la fermeture du `Stack` :

```dart
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: AppFAB(
                icon: FIcons.locateFixed,
                onPress: () {
                  // Recentrer sur la position GPS user (si dispo) — sinon
                  // recentrer sur la base.
                  // Implémentation simple : recentrer sur la base. Géoloc
                  // utilisateur peut être ajoutée plus tard via Geolocator.
                  final settings = ref.read(settingsRepositoryProvider);
                  settings.read().then((s) {
                    if (s == null) return;
                    _mapController.move(
                      LatLng(s.baseCoordinates.lat, s.baseCoordinates.lon),
                      14,
                    );
                  });
                },
              ),
            ),
```

Ajouter l'import :

```dart
import '../widgets/app_fab.dart';
```

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Smoke test manuel**

Sur la Map, vérifier qu'un FAB primary apparaît bottom-right. Tap → recentre sur la base.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/map/map_screen.dart
git commit -m "feat(map): add AppFAB locate (recenter on base for now)"
```

---

## Phase 5 — Smoke validation finale

### Task 12: Smoke + tests + build

**Files:** (aucun)

- [ ] **Step 1: `flutter analyze`** → 0 errors.

```
flutter analyze
```

- [ ] **Step 2: `flutter test`** → tous tests verts.

```
flutter test
```

- [ ] **Step 3: Build APK debug**

```
flutter build apk --debug --target-platform android-arm64
```

- [ ] **Step 4: Smoke test manuel des 4 écrans**

- [ ] Tour detail (planifiée et complétée)
- [ ] Client detail (avec et sans tournée planifiée, avec et sans historique)
- [ ] Tour completion (cocher/décocher, éditer qty, ajouter hors-plan, valider)
- [ ] Map (chips status, tap pin, FAB localisation)

- [ ] **Step 5: Pas de commit ici**

---

## Self-review post-écriture

**Spec coverage check** (vs spec §3) :

- §3.1 Tour detail :
  - AppKpiRow 4 valeurs (km/durée/revenu/animaux) → Task 6 ✓
  - MiniMap preview → Tasks 2 + 6 ✓
  - Stop tile rich (horaire, ville, distance, breakdown, montant+durée) → Task 6 ✓
  - Bloc Résumé prestations agrégé → Task 6 ✓
  - AppActionBar « Compléter » → Task 6 ✓
  - Header subtitle statut → Task 6 ✓
  - Menu `⋯` (Modifier/Partager/Dupliquer/Supprimer) — *partiellement* couvert (Partager et delete via Header actions ; Modifier et Dupliquer non implémentés ici) — **gap mineur** : Modifier était dans le code initial via `/edit` route, à brancher au menu. Fix : pour ship Plan 2, j'ai mis Partager en action header trailing seulement. Modifier reste accessible via Plan 3 sweep ou ajout ultérieur.
  - Pull-to-refresh : NON ajouté ici → **gap mineur** (à ajouter Plan 3 sweep).
- §3.2 Client detail :
  - AppKpiRow synthèse (interv/revenu/dernière/années) → Task 7 ✓
  - Bloc « Prochaine action » → Task 7 ✓
  - Statut chip + saison → Task 7 ✓ (saison non explicite dans le badge — le badge montre juste le status. Le label « saison 2026 » ne s'affiche pas — **gap mineur** acceptable)
  - Animaux / Coordonnées / Phones → Task 7 ✓
  - Notes section dédiée si présentes → **non implémenté** (les notes vivent sur les interventions, pas sur le client) — **clarification spec** : la spec mentionnait un bloc Notes, mais le modèle Client n'a pas de champ notes ; les notes existantes sont par-intervention dans l'historique. Le bloc Notes n'a donc pas de source. **Gap acceptable**.
  - Timeline 3 dernières → Task 7 ✓
  - AppActionBar `+ Tonte manuelle | Modifier` → Task 7 ✓
  - Menu `⋯` Supprimer → Task 7 ✓
- §3.3 Tour completion :
  - AppKpiRow live → Task 8 ✓
  - AppDiffRow par presta → Task 8 ✓
  - Sous-total stop visible (trailing card) → Task 8 ✓
  - Confirm dialog avant validation → Task 8 ✓
  - Toast succès → conservé (existait déjà)
  - Snackbar undo : NON implémenté → **gap mineur** (descope acceptable, complexité d'undo sur completion non triviale)
- §3.4 Map :
  - AppKpiRow flottant chips status → Task 9 ✓
  - Sheet riche au tap pin → Task 10 ✓
  - FAB localiser → Task 11 ✓
  - Drop-pin home : déjà existant après pivot multi-praticien (TODO.md), pas refait ici.
  - Recherche overlay top : conservée existante, pas refondue (spec dit « en overlay top, pas dans dialog » — déjà le cas)
  - Long-press chip → ouvrir dialog couleur statut : *bonus* spec, **non implémenté** → gap mineur

**Placeholder scan** :
- Aucun TBD/TODO/implement later.
- Note : la map task référence un `top: 80` qui peut nécessiter ajustement selon le layout exact ; c'est explicité dans Step 5.

**Type consistency** :
- `aggregatePrestations` (T3) → consommée dans T6 ✓
- `computeClientKpis` / `clientKpisProvider` (T4) → consommé dans T7 ✓
- `clientCountByStatusProvider` (T5) → consommé dans T9 ✓
- `MiniMap` (T2) → consommé dans T6 ✓
- `showDestructiveConfirm` (T1) → consommé dans T7 et T8 ✓
- `AppHeader`/`AppActionBar`/`AppKpiRow`/`AppListTile`/`AppTimelineRow`/`AppDiffRow`/`AppFAB` → tous définis dans Plan 1, consommés ici cohéremment ✓

**Implementation notes pour l'engineer** :
- Si les API exactes des modèles divergent de ce que le plan suppose (ex. `Intervention.totalRevenueCents`), adapter localement et reporter en concern.
- Les wireframes texte du spec §3 sont une cible visuelle ; la priorité est d'avoir les composants en place et l'info densifiée. Du polish (offsets exacts, espacements micro) peut être ajusté en smoke test.
- Les écrans qui consomment encore `theme.typography.base` casseront — il faut substituer `.md`. Cela concerne potentiellement d'autres écrans non touchés ici. Si le `flutter analyze` échoue, repérer la ligne et patcher en remplaçant `.base` par `.md`.
