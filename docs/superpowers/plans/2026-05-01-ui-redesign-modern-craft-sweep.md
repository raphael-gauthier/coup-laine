# UI Redesign v3 — Sweep + Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Appliquer le design system v3 Modern Craft aux 13 écrans non-prioritaires (sweep) et nettoyer les composants/assets obsolètes (`AppHeroCard`, font Fraunces).

**Architecture:** Pour chaque écran, remplacer `FHeader.nested` → `AppHeader`, remplacer `FTile` directs → `AppListTile` (variants compact/standard/rich selon densité), ajouter `AppFAB` là où des `FloatingActionButton` Material sont utilisés, brancher les KpiRows/ActionBars là où le spec le demande. Refactors plus lourds pour Onboarding (stepper 3 steps), Settings (split en sections cards), Tour draft (stepper). Aucun changement de logique métier ni de provider.

**Tech Stack:** Flutter 3.41+, Forui 0.21.3, composants signature de Plan 1 + helpers de Plan 2.

**Out-of-scope** : changements de routing/navigation, nouveaux providers (sauf si déjà fournis par Plan 2), tests widget pour les écrans (smoke manuel).

---

## File Structure

**Modifié** (sweep) :
- `lib/presentation/onboarding/onboarding_screen.dart`
- `lib/presentation/clients/clients_list_screen.dart`
- `lib/presentation/clients/client_form_screen.dart`
- `lib/presentation/clients/client_history_screen.dart`
- `lib/presentation/tours/tours_list_screen.dart`
- `lib/presentation/tours/tour_draft_screen.dart`
- `lib/presentation/tours/tour_optimized_config_screen.dart`
- `lib/presentation/tours/tour_manual_picker_screen.dart` (FHeader → AppHeader uniquement)
- `lib/presentation/settings/settings_screen.dart`
- `lib/presentation/settings/prestation_catalog_screen.dart`
- `lib/presentation/settings/prestation_edit_screen.dart`
- `lib/presentation/settings/species_management_screen.dart`
- `lib/presentation/settings/species_edit_screen.dart`
- `lib/presentation/proximity/proximity_screen.dart`
- `pubspec.yaml` (drop fonts.Fraunces block)

**Supprimé** :
- `lib/presentation/widgets/app_hero_card.dart`
- `assets/fonts/Fraunces.ttf`

---

## Phase A — Cleanup foundationnel

### Task 1: Drop `AppHeroCard` (utilisé uniquement par `tour_draft_screen.dart`)

**Files:**
- Modify: `lib/presentation/tours/tour_draft_screen.dart` (retirer l'usage)
- Delete: `lib/presentation/widgets/app_hero_card.dart`

- [ ] **Step 1: Identifier l'usage dans tour_draft_screen**

```
grep -n "AppHeroCard" lib/presentation/tours/tour_draft_screen.dart
```

Repérer le `AppHeroCard(...)` (probable : un bloc summary de la tournée draft avec total revenue/distance).

- [ ] **Step 2: Remplacer par `AppKpiRow`**

Remplacer le bloc `AppHeroCard(...)` par un `AppKpiRow` avec 2-4 cells selon ce que le hero affichait. Si l'AppHeroCard avait `bigNumber` (revenu) + `subtitle` (km/durée/clients), le KpiRow équivalent est :

```dart
AppKpiRow(
  cells: [
    AppKpiCell(value: '${stops.length}', label: 'stops'),
    AppKpiCell(value: '$kmStr', label: 'km'),
    AppKpiCell(value: formatDuration(driveMin), label: 'durée'),
    AppKpiCell(
      value: formatEuros(totalCents),
      label: 'revenu',
      valueColor: theme.colors.secondary,
    ),
  ],
),
```

Adapter les imports : ajouter `import '../widgets/app_kpi_row.dart';` et retirer `import '../widgets/app_hero_card.dart';`.

- [ ] **Step 3: Supprimer le fichier `AppHeroCard`**

```
rm lib/presentation/widgets/app_hero_card.dart
```

- [ ] **Step 4: `flutter analyze`** → 0 errors.

- [ ] **Step 5: `flutter test`** → tous tests verts.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/tours/tour_draft_screen.dart lib/presentation/widgets/app_hero_card.dart
git commit -m "cleanup(widgets): drop AppHeroCard (replaced by AppKpiRow everywhere)"
```

---

### Task 2: Drop la font Fraunces

**Files:**
- Modify: `pubspec.yaml` (retirer le bloc `fonts:`)
- Delete: `assets/fonts/Fraunces.ttf`

- [ ] **Step 1: Vérifier qu'aucun code ne référence `'Fraunces'` comme `fontFamily`**

```
grep -rn "Fraunces" lib/ test/
```

Expected: aucune occurrence (Plan 1 a déjà droppé Fraunces du theme).

- [ ] **Step 2: Modifier `pubspec.yaml`**

Supprimer le bloc :

```yaml
  fonts:
    - family: Fraunces
      fonts:
        - asset: assets/fonts/Fraunces.ttf
```

Le bloc `flutter:` doit rester avec `uses-material-design: true`, `generate: true`, et le bloc `assets:` (ne pas toucher aux assets).

- [ ] **Step 3: Supprimer le fichier TTF**

```
rm assets/fonts/Fraunces.ttf
rmdir assets/fonts
```

(Si `assets/fonts/` ne contient plus rien, supprimer le dossier.)

- [ ] **Step 4: `flutter pub get`** → no errors.

```
flutter pub get
```

- [ ] **Step 5: `flutter analyze` + `flutter test`** → 0 errors / tous verts.

- [ ] **Step 6: Smoke test build**

```
flutter build apk --debug --target-platform android-arm64
```

Expected: build OK.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml assets/
git commit -m "cleanup(assets): drop Fraunces font (no longer used in v3 theme)"
```

---

## Phase B — List screens refactor

### Task 3: Clients list — AppHeader + AppListTile rich + AppFAB extended

**Files:**
- Modify: `lib/presentation/clients/clients_list_screen.dart`

- [ ] **Step 1: Lire le fichier pour repérer le scaffold actuel**

```
grep -n "FScaffold\|FHeader\|FloatingActionButton\|FTile\|_ClientTile" lib/presentation/clients/clients_list_screen.dart
```

Le current state : pas de FHeader (titre rendu inline avec `theme.typography.xl3`), un `FloatingActionButton` Material en bas, un `_ClientTile` qui retourne un `FTile`.

- [ ] **Step 2: Convertir le titre inline en `AppHeader`**

Remplacer le bloc qui rend le titre `Text(l.clientsListTitle, style: theme.typography.xl3...)` + le sous-titre stats + le `Row(_SearchField, _StatusFilterButton)` par :

```dart
AppHeader(
  title: l.clientsListTitle,
  subtitle: '${all.length} clients · ${waiting.length} en attente',
  showBackButton: false,
),
const SizedBox(height: AppSpacing.sm),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  child: Row(
    children: const [
      Expanded(child: _SearchField()),
      SizedBox(width: AppSpacing.sm),
      _StatusFilterButton(),
    ],
  ),
),
```

Ajouter l'import : `import '../widgets/app_header.dart';`

- [ ] **Step 3: Convertir `_ClientTile` (qui retourne `FTile`) en `AppListTile rich`**

Remplacer le `return FTile(...)` du `_ClientTile.build` par :

```dart
return AppListTile(
  variant: AppListTileVariant.rich,
  prefix: Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
  ),
  title: client.name,
  subtitle: client.city,
  metadata: AnimalCountsBadges(
    counts: client.animals,
    mode: AnimalCountsBadgesMode.compact,
  ),
  suffix: client.needsDistanceRecompute
      ? AppBadge.recompute(context)
      : Icon(FIcons.chevronRight, color: theme.colors.mutedForeground),
  onTap: () => context.push('/clients/${client.id}'),
);
```

Ajouter l'import : `import '../widgets/app_list_tile.dart';`

- [ ] **Step 4: Remplacer le `FloatingActionButton` Material par `AppFAB.extended`**

Remplacer le bloc :

```dart
Positioned(
  bottom: 16,
  right: 16,
  child: FloatingActionButton(
    onPressed: () => context.push('/clients/new'),
    child: const Icon(FIcons.userPlus),
  ),
),
```

Par :

```dart
Positioned(
  bottom: 16,
  right: 16,
  child: AppFAB(
    icon: FIcons.userPlus,
    label: l.clientsAddNew,
    extended: true,
    onPress: () => context.push('/clients/new'),
  ),
),
```

Ajouter l'import : `import '../widgets/app_fab.dart';`. Retirer `import 'package:flutter/material.dart' show FloatingActionButton, ...;` (garder `Material, MaterialType, RefreshIndicator` qui restent utilisés).

- [ ] **Step 5: `flutter analyze`** → 0 errors.

- [ ] **Step 6: `flutter test`** → tous verts.

- [ ] **Step 7: Smoke test manuel : tap sur une tile, FAB extended, scroll, refresh.**

- [ ] **Step 8: Commit**

```bash
git add lib/presentation/clients/clients_list_screen.dart
git commit -m "refactor(clients-list): use AppHeader + AppListTile rich + AppFAB extended"
```

---

### Task 4: Tours list — AppHeader + AppListTile rich + AppFAB

**Files:**
- Modify: `lib/presentation/tours/tours_list_screen.dart`

- [ ] **Step 1: Reconnaissance**

```
grep -n "FScaffold\|FHeader\|FloatingActionButton\|FTile\|FCard" lib/presentation/tours/tours_list_screen.dart
```

- [ ] **Step 2: Apply pattern**

Remplacer la même chose que Task 3 :
- Titre inline → `AppHeader(title: l.toursListTitle, subtitle: '${total} tournées · ${planned} planifiées', showBackButton: false)`
- Tile (probablement un FCard ou FTile par tournée) → `AppListTile rich` avec :
  - `prefix` : badge date verticale (jour bold + mois muted)
  - `title` : `Tournée du DD MMM · N stops`
  - `subtitle` : 3 premières villes en italique
  - `metadata` : `AppStat(icon: FIcons.route, value: '${km} km')`, `AppStat(icon: FIcons.clock, value: formatDuration(min))`, `AppStat(value: formatEuros(cents))` + `AppBadge.fromStatus` ou `.completed`/`.planned`
  - `onTap` → push `/tours/:id`
- FAB Material → `AppFAB.extended(icon: FIcons.plus, label: 'Tournée', onPress: () => _showCreateSheet(context))` (ouvre une sheet « Manuelle / Optimisée »)

Pour la sheet de choix, ajouter un helper local :

```dart
Future<void> _showCreateSheet(BuildContext context) async {
  await showFSheet<void>(
    context: context,
    side: FLayout.btt,
    builder: (sheetCtx) {
      final theme = sheetCtx.theme;
      return ColoredBox(
        color: theme.colors.background,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Nouvelle tournée',
                    style: theme.typography.xl2.copyWith(
                      color: theme.colors.foreground,
                    )),
                const SizedBox(height: AppSpacing.md),
                FButton(
                  prefix: const Icon(FIcons.list),
                  onPress: () {
                    Navigator.of(sheetCtx).pop();
                    context.push('/tours/new/manual');
                  },
                  child: const Text('Manuelle'),
                ),
                const SizedBox(height: AppSpacing.sm),
                FButton(
                  variant: FButtonVariant.outline,
                  prefix: const Icon(FIcons.zap),
                  onPress: () {
                    Navigator.of(sheetCtx).pop();
                    context.push('/tours/new/optimized');
                  },
                  child: const Text('Optimisée par commune'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
```

- [ ] **Step 3: `flutter analyze`** → 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/tours/tours_list_screen.dart
git commit -m "refactor(tours-list): AppHeader + AppListTile rich + AppFAB sheet de choix"
```

---

### Task 5: Catalogue prestations — AppHeader + AppListTile + AppFAB

**Files:**
- Modify: `lib/presentation/settings/prestation_catalog_screen.dart`

- [ ] **Step 1: Reconnaissance + remplacements**

Pattern : remplacer `FHeader.nested` → `AppHeader(title: 'Catalogue de prestations', subtitle: '$activeCount actives · $archivedCount archivées')`. Remplacer chaque `FTile` du catalogue par `AppListTile.standard(title: presta.name, subtitle: '${spec}/${cat}', metadata: AppStat(value: formatEuros(presta.priceCents)) + AppStat(value: '${presta.minutes} min'), onTap)`. Ajouter `AppFAB(icon: FIcons.plus, label: 'Prestation', extended: true, onPress: () => context.push('/settings/prestations/new'))` en `Stack > Positioned bottom-right`.

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/settings/prestation_catalog_screen.dart
git commit -m "refactor(prestation-catalog): AppHeader + AppListTile + AppFAB"
```

---

### Task 6: Species management — AppHeader + AppFAB

**Files:**
- Modify: `lib/presentation/settings/species_management_screen.dart`

- [ ] **Step 1: Reconnaissance + remplacements**

Pattern : `FHeader.nested` → `AppHeader(title: 'Espèces & catégories', subtitle: '$active actives · $archived archivées')`. `FTile` par espèce → `AppListTile.standard(title: species.name, subtitle: '$N catégories', suffix: chevron, onTap → species_edit)`. Ajouter `AppFAB(icon: FIcons.plus, label: 'Espèce', extended: true, onPress: () => _showAddSheet(context))` (sheet : Restaurer template / Ajouter custom).

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/settings/species_management_screen.dart
git commit -m "refactor(species-mgmt): AppHeader + AppListTile + AppFAB"
```

---

## Phase C — Sub-screens

### Task 7: Client history — KpiRow + chips season + group by month + AppTimelineRow

**Files:**
- Modify: `lib/presentation/clients/client_history_screen.dart`

- [ ] **Step 1: Réécrire le `build` du screen**

Remplacer le scaffold existant par :

```dart
return FScaffold(
  child: SafeArea(
    top: true,
    bottom: false,
    child: Column(
      children: [
        AppHeader(
          title: 'Historique de ${client.name}',
          subtitle: '${interventions.length} interventions',
        ),
        // KpiRow synthèse
        kpisAsync.when(
          loading: () => const SizedBox(height: 80),
          error: (_, __) => const SizedBox.shrink(),
          data: (k) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppKpiRow(
              cells: [
                AppKpiCell(value: '${k.interventionCount}', label: 'interv'),
                AppKpiCell(
                  value: formatEuros(k.totalRevenueCents),
                  label: 'revenu',
                  valueColor: theme.colors.secondary,
                ),
                AppKpiCell(
                  value: k.lastInterventionDate == null
                      ? '—'
                      : DateFormat('MMM yyyy', 'fr').format(k.lastInterventionDate!),
                  label: 'dernière',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.builder(
            padding: AppSizes.screenPadding,
            itemCount: groupedItems.length,
            itemBuilder: (_, i) {
              final group = groupedItems[i];
              if (group is _MonthHeader) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    group.label.toUpperCase(),
                    style: captionStyle(theme.typography.xs).copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                );
              }
              final it = (group as _Entry).intervention;
              return AppTimelineRow(
                dateLabel: DateFormat('d MMM', 'fr').format(it.date),
                icon: it.kind == InterventionKind.manual
                    ? FIcons.pencil
                    : FIcons.scissors,
                title: it.kind == InterventionKind.tour ? 'Tournée' : 'Saisie manuelle',
                breakdown: _shortBreakdown(it),
                amount: it.totalRevenueCents == 0 ? null : formatEuros(it.totalRevenueCents),
                duration: it.totalMinutes == 0 ? null : formatDuration(it.totalMinutes),
                onTap: () => _onTapItem(context, ref, it, client.id),
              );
            },
          ),
        ),
      ],
    ),
  ),
);
```

Ajouter au-dessus du `build` un helper de groupement :

```dart
sealed class _Group {}
class _MonthHeader extends _Group {
  final String label;
  _MonthHeader(this.label);
}
class _Entry extends _Group {
  final Intervention intervention;
  _Entry(this.intervention);
}

List<_Group> _groupByMonth(List<Intervention> items) {
  final out = <_Group>[];
  String? currentMonth;
  for (final it in items) {
    final m = DateFormat('MMMM yyyy', 'fr').format(it.date);
    if (m != currentMonth) {
      out.add(_MonthHeader(m));
      currentMonth = m;
    }
    out.add(_Entry(it));
  }
  return out;
}

String _shortBreakdown(Intervention it) {
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
```

Ajouter un `AppFAB` extended bottom-right via Stack pour « + Tonte manuelle » qui ouvre `showManualHistoryEntrySheet`.

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/clients/client_history_screen.dart
git commit -m "refactor(client-history): KpiRow + group by month + AppTimelineRow + AppFAB"
```

---

### Task 8: Settings — split en sections cards + AppActionBar save

**Files:**
- Modify: `lib/presentation/settings/settings_screen.dart`

- [ ] **Step 1: Reconnaissance**

Lire le fichier (~631 lignes). Repérer les sections (adresse, theme mode, couleurs status, optimisation, espèces, prestations, données).

- [ ] **Step 2: Structurer en `AppSectionCard` repliables**

Remplacer le scaffold racine par :

```dart
return FScaffold(
  child: SafeArea(
    top: true,
    bottom: false,
    child: Column(
      children: [
        AppHeader(
          title: l.settingsTitle,
          showBackButton: false,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: AppSizes.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AddressSection(...),
                const SizedBox(height: AppSpacing.md),
                _AppearanceSection(...),
                const SizedBox(height: AppSpacing.md),
                _StatusColorsSection(...),
                const SizedBox(height: AppSpacing.md),
                _TourOptimizationSection(...),
                const SizedBox(height: AppSpacing.md),
                _SpeciesShortcutSection(...),
                const SizedBox(height: AppSpacing.md),
                _PrestationsShortcutSection(...),
                const SizedBox(height: AppSpacing.md),
                _DataSection(...),
                const SizedBox(height: AppSizes.bottomScrollPadding),
              ],
            ),
          ),
        ),
        if (hasChanges)
          AppActionBar(
            primary: AppPrimaryButton(
              label: l.settingsSave,
              onPress: _save,
            ),
          ),
      ],
    ),
  ),
);
```

Chaque `_XxxSection` est un `AppSectionCard(icon, title, child: ...)`. Les sections « espèces » et « prestations » sont juste un `AppListTile.compact(title: '5 actives', suffix: chevron, onTap → push)`.

Pour le bouton « Réinitialiser » (`_DataSection`) : `FButton.destructive` qui ouvre `showDestructiveConfirm` avec saisie de confirmation manuelle (typer "SUPPRIMER" pour activer le bouton).

- [ ] **Step 3: `flutter analyze`** → 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/settings/settings_screen.dart
git commit -m "refactor(settings): split en sections cards + AppActionBar save"
```

---

### Task 9: Onboarding — stepper visuel 3 steps + Step 3 welcome

**Files:**
- Modify: `lib/presentation/onboarding/onboarding_screen.dart`

- [ ] **Step 1: Reconnaissance**

Lire le fichier. Identifier les 2 steps actuels (Adresse, Espèces) — probable IndexedStack ou bool stepIndex.

- [ ] **Step 2: Ajouter un Stepper widget en haut**

Créer un widget local `_Stepper(int currentIndex, int total)` qui affiche `[●]──[○]──[○]` avec labels sous chaque pastille. Pastille active = `theme.colors.primary` filled, sinon outline `theme.colors.subtleForeground`.

```dart
class _Stepper extends StatelessWidget {
  final int currentIndex;
  final List<String> labels;
  const _Stepper({required this.currentIndex, required this.labels});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: i <= currentIndex ? theme.colors.primary : null,
                      shape: BoxShape.circle,
                      border: i <= currentIndex
                          ? null
                          : Border.all(color: theme.colors.border, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: theme.typography.sm.copyWith(
                        color: i <= currentIndex
                            ? theme.colors.primaryForeground
                            : theme.colors.mutedForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: theme.typography.xs.copyWith(
                      color: i == currentIndex
                          ? theme.colors.foreground
                          : theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            if (i < labels.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  width: 24,
                  child: Container(
                    height: AppSizes.hairlineBorder,
                    color: i < currentIndex ? theme.colors.primary : theme.colors.border,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
```

Insérer `_Stepper(currentIndex: stepIndex, labels: ['Adresse', 'Espèces', 'Bienvenue'])` en haut de l'écran sous le header.

- [ ] **Step 3: Ajouter Step 3 (Bienvenue)**

```dart
class _Step3Welcome extends StatelessWidget {
  final String city;
  final int speciesCount;
  final VoidCallback onStart;
  const _Step3Welcome({required this.city, required this.speciesCount, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tu es prêt !',
            style: theme.typography.xl3.copyWith(color: theme.colors.foreground),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tu vas gérer $speciesCount espèce(s) depuis $city.',
            style: theme.typography.md.copyWith(color: theme.colors.mutedForeground),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppSectionCard(
            icon: FIcons.userPlus,
            title: 'Premiers pas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Text('• Ajouter ton premier client'),
                SizedBox(height: AppSpacing.xs),
                Text('• Planifier ta première tournée'),
                SizedBox(height: AppSpacing.xs),
                Text('• Ouvrir le catalogue de prestations'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(label: 'Démarrer', onPress: onStart),
        ],
      ),
    );
  }
}
```

L'`onStart` appelle la persistence "first run done" + push vers `/clients` (ou `/tours` selon ce que fait l'app aujourd'hui à la fin de l'onboarding).

- [ ] **Step 4: ActionBar bottom selon le step**

```dart
AppActionBar(
  secondary: stepIndex > 0
      ? AppPrimaryButton(label: 'Retour', variant: FButtonVariant.outline, onPress: _back)
      : null,
  primary: AppPrimaryButton(
    label: stepIndex == 2 ? 'Démarrer' : 'Suivant',
    onPress: _next,
  ),
),
```

- [ ] **Step 5: `flutter analyze`** → 0 errors.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/onboarding/onboarding_screen.dart
git commit -m "refactor(onboarding): 3-step stepper + step 3 welcome"
```

---

### Task 10: Client form — sections numérotées + validation inline + AppActionBar

**Files:**
- Modify: `lib/presentation/clients/client_form_screen.dart`

- [ ] **Step 1: Réécrire le scaffold + sections**

Remplacer FHeader par `AppHeader(title: editing ? 'Modifier client' : 'Nouveau client')`. Wrapper le form dans des `AppSectionCard` numérotées :

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    AppSectionCard(
      icon: FIcons.user,
      title: '1. Identité',
      child: FTextField(
        control: FTextFieldControl.managed(controller: nameCtrl),
        label: const Text('NOM'),
        // validation onBlur — afficher erreur sous le champ
      ),
    ),
    const SizedBox(height: AppSpacing.md),
    AppSectionCard(icon: FIcons.mapPin, title: '2. Adresse', child: ...),
    const SizedBox(height: AppSpacing.md),
    AppSectionCard(icon: FIcons.phone, title: '3. Téléphones', child: ...),
    const SizedBox(height: AppSpacing.md),
    AppSectionCard(icon: FIcons.pawPrint, title: '4. Animaux', child: ...),
    const SizedBox(height: AppSpacing.md),
    AppSectionCard(icon: FIcons.palette, title: '5. Couleur du marqueur', child: ...),
  ],
),
```

ActionBar bottom : `[Annuler outline] [Enregistrer primary]`.

Validation inline : pour chaque champ required, garder un `String? errorText` dans le state, afficher en `Text` rouge sous le champ si non null. Mettre à jour onBlur (via `Focus(onFocusChange:)`).

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/clients/client_form_screen.dart
git commit -m "refactor(client-form): sections numérotées + validation inline + AppActionBar"
```

---

### Task 11: Tour draft — stepper 3 steps + AppHeader

**Files:**
- Modify: `lib/presentation/tours/tour_draft_screen.dart`

- [ ] **Step 1: Reconnaissance**

Lire le fichier (~493 lignes). Identifier les 3 phases logiques (date/heure, sélection clients, prestations + ordre + résumé).

- [ ] **Step 2: Convertir en stepper 3 steps**

Réutiliser le widget `_Stepper` introduit en T9 (le déplacer dans `lib/presentation/widgets/app_stepper.dart` pour réutilisation, et adapter T9 pour l'importer). 

Créer `lib/presentation/widgets/app_stepper.dart` :

```dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

class AppStepper extends StatelessWidget {
  final int currentIndex;
  final List<String> labels;
  const AppStepper({
    super.key,
    required this.currentIndex,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: i <= currentIndex ? theme.colors.primary : null,
                      shape: BoxShape.circle,
                      border: i <= currentIndex
                          ? null
                          : Border.all(color: theme.colors.border, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: theme.typography.sm.copyWith(
                        color: i <= currentIndex
                            ? theme.colors.primaryForeground
                            : theme.colors.mutedForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: theme.typography.xs.copyWith(
                      color: i == currentIndex
                          ? theme.colors.foreground
                          : theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            if (i < labels.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  width: 24,
                  child: Container(
                    height: AppSizes.hairlineBorder,
                    color: i < currentIndex
                        ? theme.colors.primary
                        : theme.colors.border,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
```

Adapter T9 pour utiliser `AppStepper`. Adapter T11 pour utiliser `AppStepper(labels: ['Quand', 'Qui', 'Quoi'])` en haut.

Pour le step `Quand` : un seul écran avec date picker + time picker côte à côte.
Pour le step `Qui` : `WaitingClientsMultiPicker` existant (avec count en titre d'onglet).
Pour le step `Quoi` : reorderable list des stops + bouton « Optimiser l'ordre » + sticky `AppKpiRow` bottom + `AppActionBar` bottom.

C'est un refactor significatif. Si l'engineer trouve que le scope est trop large, le découper en 2 sous-tâches : (a) ajouter le stepper visuel et le routing entre steps, (b) intégrer mini-map preview.

- [ ] **Step 3: `flutter analyze`** → 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/app_stepper.dart lib/presentation/tours/tour_draft_screen.dart lib/presentation/onboarding/onboarding_screen.dart
git commit -m "refactor(tour-draft): 3-step stepper (Quand/Qui/Quoi) + AppHeader + extract AppStepper"
```

---

### Task 12: Tour optimized config — preview live + AppHeader

**Files:**
- Modify: `lib/presentation/tours/tour_optimized_config_screen.dart`

- [ ] **Step 1: Apply pattern**

Remplacer FHeader → AppHeader. Au-dessus du selector commune, afficher un `Text('5 clients waiting à $city')` qui se met à jour quand la commune change (via provider/state existant). Si aucune match : `AppEmptyState(icon: FIcons.search, title: 'Pas assez de clients waiting', body: 'Élargis le rayon ou choisis une autre commune.')` à la place du sélecteur.

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/tours/tour_optimized_config_screen.dart
git commit -m "refactor(tour-optimized-config): AppHeader + preview live commune"
```

---

### Task 13: Tour manual picker — AppHeader uniquement

**Files:**
- Modify: `lib/presentation/tours/tour_manual_picker_screen.dart`

- [ ] **Step 1: Remplacement minimal**

Replacer `FHeader.nested(title: ...)` par `AppHeader(title: ...)`. Pas d'autre changement requis.

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/tours/tour_manual_picker_screen.dart
git commit -m "refactor(tour-manual-picker): AppHeader"
```

---

### Task 14: Prestation edit — sections + validation + AppActionBar

**Files:**
- Modify: `lib/presentation/settings/prestation_edit_screen.dart`

- [ ] **Step 1: Refactor**

Pattern identique à Task 10 (Client form) : `AppHeader(title: editing ? 'Modifier prestation' : 'Nouvelle prestation')`, sections en `AppSectionCard` (Identité, Catégorie, Tarif & durée, Archive si édit), `AppActionBar(primary: Enregistrer, secondary: Annuler, tertiary: Supprimer destructive si édit)`. Validation inline sur le nom (required) avec `errorText` en state.

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/settings/prestation_edit_screen.dart
git commit -m "refactor(prestation-edit): sections + validation inline + AppActionBar"
```

---

### Task 15: Species edit — AppHeader + AppFAB

**Files:**
- Modify: `lib/presentation/settings/species_edit_screen.dart`

- [ ] **Step 1: Refactor**

`FHeader.nested` → `AppHeader(title: species.name, subtitle: '$catCount catégories · $prestaCount prestations')`. Si l'écran a un FAB Material → `AppFAB.extended(icon: FIcons.plus, label: 'Catégorie', onPress)`. Les `FTile` par catégorie → `AppListTile.standard(title: cat.name, subtitle: 'Variantes…', suffix: menu ⋯)`.

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/settings/species_edit_screen.dart
git commit -m "refactor(species-edit): AppHeader + AppListTile + AppFAB"
```

---

### Task 16: Proximity — slider sticky + KpiRow live + tabs + AppHeader

**Files:**
- Modify: `lib/presentation/proximity/proximity_screen.dart`

- [ ] **Step 1: Refactor**

`FHeader.nested` → `AppHeader(title: 'À proximité de ${pivot.name}')`. Slider rayon sticky en haut sous le header. `AppKpiRow` live avec `(found, selected, avg km)` au-dessus des tabs Liste/Carte. Tabs visibles (FTabs ou Row de chips actifs). `AppActionBar(primary: 'Planifier la tournée ($selectedCount)', secondary: 'Annuler outline')`.

Pour la liste : remplacer les `FTile` ou `FCard` candidats par `AppListTile.rich(prefix: checkbox, title: name, subtitle: city, metadata: AppStat(value: '${km} km'), onTap: toggleSelection)`.

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/proximity/proximity_screen.dart
git commit -m "refactor(proximity): AppHeader + AppKpiRow live + AppListTile + AppActionBar"
```

---

## Phase D — Smoke validation finale

### Task 17: Full smoke

**Files:** (aucun)

- [ ] **Step 1: `flutter analyze`** → 0 errors.

- [ ] **Step 2: `flutter test`** → tous tests verts.

- [ ] **Step 3: `flutter build apk --debug --target-platform android-arm64`** → OK.

- [ ] **Step 4: Smoke test manuel — naviguer chaque écran touché**

- [ ] Onboarding (3 steps + step 3 welcome)
- [ ] Clients list (FAB extended, AppListTile rich)
- [ ] Client form (validation inline)
- [ ] Client history (KpiRow, group by month)
- [ ] Tours list (FAB sheet, AppListTile rich)
- [ ] Tour draft (3-step stepper)
- [ ] Tour optimized config (preview live)
- [ ] Tour manual picker (AppHeader)
- [ ] Settings (sections cards, save sticky)
- [ ] Catalogue prestations (FAB, AppListTile)
- [ ] Prestation edit (sections, validation)
- [ ] Species mgmt (FAB, AppListTile)
- [ ] Species edit (AppHeader, AppListTile)
- [ ] Proximity (KpiRow live, tabs)

- [ ] **Step 5: Vérifier qu'aucune référence à `AppHeroCard` ne subsiste**

```
grep -rn "AppHeroCard" lib/ test/
```

Expected: aucun résultat.

- [ ] **Step 6: Vérifier qu'aucune référence à Fraunces ne subsiste**

```
grep -rn "Fraunces" lib/ test/ pubspec.yaml
```

Expected: aucun résultat.

- [ ] **Step 7: Pas de commit**

---

## Self-review post-écriture

**Spec coverage** (vs spec §4) :

- §4.1 Clients list : Header + count subtitle + AppListTile rich + AppFAB extended → Task 3 ✓
- §4.2 Tours list : Header + KpiRow + AppListTile rich + FAB sheet → Task 4 ✓
- §4.3 Settings : sections numérotées + AppActionBar save → Task 8 ✓
- §4.4 Onboarding : stepper 3 steps + Step 3 welcome → Task 9 ✓
- §4.5 Client form : sections numérotées + validation inline → Task 10 ✓
- §4.6 Client history : KpiRow + group by month + AppTimelineRow → Task 7 ✓
- §4.7 Tour draft : stepper 3 steps Quand/Qui/Quoi → Task 11 ✓ (mini-map preview noté comme sub-task possible)
- §4.8 Tour optimized config : preview live + empty state → Task 12 ✓
- §4.9 Catalogue prestations : Header + KpiRow + sections + AppFAB → Task 5 ✓
- §4.10 Prestation edit : sections + validation + AppActionBar → Task 14 ✓
- §4.11 Species mgmt : Header + KpiRow + AppFAB → Task 6 ✓
- §4.12 Species edit : Header + AppListTile + AppFAB → Task 15 ✓
- §4.13 Proximity : slider sticky + KpiRow live + tabs + AppActionBar → Task 16 ✓

**Cleanup** (spec §5 phase 6) :
- Drop `AppHeroCard` → Task 1 ✓
- Drop Fraunces font → Task 2 ✓
- Code mort éventuel : pas explicite ici ; le grep final en Task 17 valide.

**Placeholder scan** : aucun TBD/TODO.

**Type consistency** :
- `AppStepper` introduit en Task 11 et utilisé aussi en Task 9 (rétrocompatibilité) ✓
- `AppHeader`, `AppActionBar`, `AppFAB`, `AppListTile`, `AppKpiRow`, `AppKpiCell`, `AppTimelineRow`, `AppPrimaryButton.variant` — tous définis dans Plans 1+2 ✓
- `showDestructiveConfirm` utilisé dans Settings (T8) ✓

**Notes pour l'engineer** :
- Tasks 8, 9, 11 sont les plus volumineux. Si un blocage survient, escalader pour découper en sous-tâches plus petites.
- Pour les tasks « apply pattern » (T4, T5, T6, T13, T14, T15, T16), le code n'est pas fourni intégralement — l'engineer doit lire le fichier existant, identifier les blocs à remplacer, et appliquer le pattern décrit. Si un fichier est très différent de ce que le plan suppose (ex. structure inattendue), reporter en NEEDS_CONTEXT.
- Validation inline (T10, T14) : le pattern « errorText en state mis à jour onBlur » est documenté dans le spec §2.4. La forme exacte d'implémentation est laissée à l'engineer (FocusNode listener, FormField, etc.).
