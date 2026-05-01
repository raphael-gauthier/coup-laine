# UI Redesign v3 — Foundations + Components Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Établir les fondations Modern Craft (palette vert forêt + cuivre, Inter sans-serif unique, tokens v3, motion, icon set) et construire/refactorer la bibliothèque de composants signature, sans modifier les écrans existants.

**Architecture:** Le `FThemeData` Forui consomme `FColors` et `FTypography` ; on remplace ces deux primitives. Les design tokens vivent dans `lib/core/design_tokens.dart` (existant, étendu) + un nouveau `lib/core/motion.dart`. Les composants signature vivent dans `lib/presentation/widgets/` aux côtés des composants existants. Les écrans existants continuent de fonctionner (les composants conservés gardent leur API publique ; seules les internes changent). Aucun changement de logique métier, de provider, ni de routing.

**Tech Stack:** Flutter 3.41+, Forui 0.21.3, Riverpod 3.3.1, flutter_svg 2.2.4 (déjà installé), aucune nouvelle dépendance.

**Out-of-scope dans ce plan** (couverts par Plans 2 et 3) : refonte des écrans, application des patterns globaux (`AppHeader`/`AppActionBar` aux écrans, validation inline, confirms unifiés), drop de `AppHeroCard` et de Fraunces (les fichiers restent en place jusqu'au cleanup).

---

## File Structure

**Modifié :**
- `lib/core/design_tokens.dart` — étendu (`xxxs`, `huge`, nouveaux radius/sizes)
- `lib/core/theme/app_color_scheme.dart` — palette remplacée
- `lib/core/theme/app_typography.dart` — typographie remplacée (drop Fraunces tiers, Inter only, tabular figures)
- `lib/core/theme/app_themes.dart` — adapté pour consommer le nouveau scheme
- `lib/presentation/widgets/app_primary_button.dart` — refactor (hauteur 52, dropForced prefixIcon)
- `lib/presentation/widgets/app_section_card.dart` — refactor (border 0.5px, plus d'iconBackground forcé)
- `lib/presentation/widgets/app_empty_state.dart` — refactor (tokens v3, illustrationHeight default 120)
- `lib/presentation/widgets/app_badge.dart` — refactor (couleurs sémantiques nouvelles, icon+label default)
- `lib/presentation/widgets/animal_counts_badges.dart` — refactor (nouvelles icônes espèces)
- `pubspec.yaml` — ajouter `assets/icons/` aux assets

**Créé :**
- `lib/core/motion.dart` — `AppMotion` (durations + curves)
- `lib/core/animal_icons.dart` — helper `iconForSpeciesKey(String key)` qui retourne le picto ou le fallback FIcons
- `lib/presentation/widgets/app_stat.dart` — `AppStat` (icon + number + unit inline)
- `lib/presentation/widgets/app_kpi_card.dart` — `AppKpiCard` (single big KPI)
- `lib/presentation/widgets/app_kpi_row.dart` — `AppKpiRow` (2-4 KPIs côte à côte)
- `lib/presentation/widgets/app_list_tile.dart` — `AppListTile` (compact/standard/rich variants)
- `lib/presentation/widgets/app_header.dart` — `AppHeader` (header avec actions label-aware)
- `lib/presentation/widgets/app_action_bar.dart` — `AppActionBar` (sticky bottom)
- `lib/presentation/widgets/app_timeline_row.dart` — `AppTimelineRow` (history dense)
- `lib/presentation/widgets/app_diff_row.dart` — `AppDiffRow` (prévu → effectué)
- `lib/presentation/widgets/app_fab.dart` — `AppFAB` (regular + extended)
- `lib/presentation/widgets/app_skeleton.dart` — `AppSkeleton` (shimmer placeholders)
- `lib/presentation/widgets/app_error_state.dart` — `AppErrorState`
- `lib/presentation/widgets/app_command_palette.dart` — `AppCommandPalette` (full-screen sheet)
- `assets/icons/cl_sheep.svg` — silhouette mouton
- `assets/icons/cl_horse.svg` — silhouette cheval
- `assets/icons/cl_cow.svg` — silhouette bovin
- `assets/icons/cl_goat.svg` — silhouette caprin
- `test/core/theme/app_color_scheme_test.dart`
- `test/core/theme/app_typography_test.dart`
- `test/core/design_tokens_test.dart`
- `test/core/motion_test.dart`
- `test/core/animal_icons_test.dart`
- `test/presentation/widgets/app_diff_row_test.dart` — test du computeDelta pure-dart

**Note pictogrammes** : la spec liste 9 pictogrammes custom. Pragmatique : on garde **4 silhouettes animales** en SVG custom (pas d'équivalent dans Lucide) et on **alias les 5 autres sur FIcons** existants (`scissors`, `clipboardCheck`, `mapPin`, `route`, `home`) — un designer pourra polir plus tard sans bloquer l'impl. La distinction passe par `lib/core/animal_icons.dart`.

---

## Phase A — Design tokens & theme primitives

### Task 1: Étendre les design tokens

**Files:**
- Modify: `lib/core/design_tokens.dart`
- Test: `test/core/design_tokens_test.dart`

- [ ] **Step 1: Écrire le test**

```dart
// test/core/design_tokens_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/design_tokens.dart';

void main() {
  group('AppSpacing', () {
    test('échelle multiples de 4 + extras hairline et huge', () {
      expect(AppSpacing.xxxs, 2);
      expect(AppSpacing.xxs, 4);
      expect(AppSpacing.xs, 8);
      expect(AppSpacing.sm, 12);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.lg, 24);
      expect(AppSpacing.xl, 32);
      expect(AppSpacing.xxl, 48);
      expect(AppSpacing.huge, 64);
    });
  });

  group('AppBorderRadius', () {
    test('radius v3 resserrés', () {
      expect(AppBorderRadius.sm, 6);
      expect(AppBorderRadius.md, 10);
      expect(AppBorderRadius.lg, 16);
      expect(AppBorderRadius.pill, 999);
    });
  });

  group('AppSizes', () {
    test('touch targets v3', () {
      expect(AppSizes.primaryButtonHeight, 52);
      expect(AppSizes.secondaryButtonHeight, 44);
      expect(AppSizes.iconButtonSize, 44);
      expect(AppSizes.textFieldMinHeight, 48);
      expect(AppSizes.sectionIconCircle, 28);
      expect(AppSizes.heroIconCircle, 56);
    });

    test('hairline border width', () {
      expect(AppSizes.hairlineBorder, 0.5);
      expect(AppSizes.standardBorder, 1.0);
    });
  });
}
```

- [ ] **Step 2: Lancer le test → fail**

```
flutter test test/core/design_tokens_test.dart
```

Expected: FAIL — `AppSpacing.xxxs`, `AppSpacing.huge`, `AppSizes.hairlineBorder`, `AppSizes.standardBorder` n'existent pas, `AppBorderRadius.sm` est 8 (attend 6), etc.

- [ ] **Step 3: Mettre à jour `lib/core/design_tokens.dart`**

```dart
// lib/core/design_tokens.dart
import 'package:flutter/widgets.dart';

/// Spacing scale en pixels logiques (multiples de 4 + hairline + huge).
abstract final class AppSpacing {
  AppSpacing._();
  static const double hairline = 2.0;
  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double huge = 64;
}

/// Border radii (v3 resserrés).
abstract final class AppBorderRadius {
  AppBorderRadius._();
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
  static const double pill = 999;
}

/// Common animation durations (deprecated — voir AppMotion dans motion.dart).
abstract final class AppDuration {
  AppDuration._();
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
}

abstract final class AppSizes {
  AppSizes._();

  static const double primaryButtonHeight = 52;
  static const double secondaryButtonHeight = 44;
  static const double iconButtonSize = 44;
  static const double textFieldMinHeight = 48;
  static const double sectionIconCircle = 28;
  static const double heroIconCircle = 56;

  static const double hairlineBorder = 0.5;
  static const double standardBorder = 1.0;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(20, 24, 20, 40);
  static const EdgeInsets rootScreenPadding = EdgeInsets.fromLTRB(20, 40, 20, 40);
  static const EdgeInsets heroCardPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 32);
  static const EdgeInsets cardPadding = EdgeInsets.all(20);
  static const EdgeInsets listTilePadding = EdgeInsets.fromLTRB(16, 14, 16, 14);
  static const double bottomScrollPadding = 80.0;
}
```

- [ ] **Step 4: Lancer le test → pass**

```
flutter test test/core/design_tokens_test.dart
```

Expected: PASS.

- [ ] **Step 5: Lancer `flutter analyze`**

```
flutter analyze lib/core/design_tokens.dart
```

Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/core/design_tokens.dart test/core/design_tokens_test.dart
git commit -m "refactor(tokens): extend AppSpacing/Radius/Sizes for v3 Modern Craft"
```

---

### Task 2: Créer `AppMotion`

**Files:**
- Create: `lib/core/motion.dart`
- Test: `test/core/motion_test.dart`

- [ ] **Step 1: Écrire le test**

```dart
// test/core/motion_test.dart
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/motion.dart';

void main() {
  group('AppMotion', () {
    test('durées', () {
      expect(AppMotion.instant, Duration.zero);
      expect(AppMotion.fast, const Duration(milliseconds: 120));
      expect(AppMotion.normal, const Duration(milliseconds: 200));
      expect(AppMotion.emphasized, const Duration(milliseconds: 280));
    });

    test('courbes', () {
      expect(AppMotion.fastCurve, Curves.easeOut);
      expect(AppMotion.normalCurve, Curves.easeOutCubic);
      expect(AppMotion.emphasizedCurve, Curves.easeInOutCubicEmphasized);
    });
  });
}
```

- [ ] **Step 2: Lancer → fail (file missing)**

```
flutter test test/core/motion_test.dart
```

Expected: FAIL — `AppMotion` undefined.

- [ ] **Step 3: Créer `lib/core/motion.dart`**

```dart
// lib/core/motion.dart
import 'package:flutter/animation.dart';

/// Motion tokens v3 — durées et courbes standardisées.
abstract final class AppMotion {
  AppMotion._();

  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration emphasized = Duration(milliseconds: 280);

  static const Curve fastCurve = Curves.easeOut;
  static const Curve normalCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;
}
```

- [ ] **Step 4: Lancer → pass**

```
flutter test test/core/motion_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/motion.dart test/core/motion_test.dart
git commit -m "feat(tokens): add AppMotion (durations + curves)"
```

---

### Task 3: Réécrire la palette

**Files:**
- Modify: `lib/core/theme/app_color_scheme.dart`
- Test: `test/core/theme/app_color_scheme_test.dart`

- [ ] **Step 1: Écrire le test**

```dart
// test/core/theme/app_color_scheme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/theme/app_color_scheme.dart';

void main() {
  group('appLightColors — Modern Craft', () {
    test('background, surface, foreground', () {
      expect(appLightColors.background, const Color(0xFFFAF8F3));
      expect(appLightColors.card, const Color(0xFFFFFFFF));
      expect(appLightColors.foreground, const Color(0xFF1B1F1A));
      expect(appLightColors.mutedForeground, const Color(0xFF6B6F66));
    });

    test('primary vert forêt + accent (secondary) cuivre', () {
      expect(appLightColors.primary, const Color(0xFF1F3A2E));
      expect(appLightColors.primaryForeground, const Color(0xFFFAF8F3));
      expect(appLightColors.secondary, const Color(0xFFB8895C));
      expect(appLightColors.secondaryForeground, const Color(0xFFFAF8F3));
    });

    test('borders & destructive', () {
      expect(appLightColors.border, const Color(0xFFE8E4DA));
      expect(appLightColors.destructive, const Color(0xFFA8403E));
      expect(appLightColors.destructiveForeground, const Color(0xFFFAF8F3));
    });

    test('brightness light', () {
      expect(appLightColors.brightness, Brightness.light);
    });
  });

  group('appDarkColors', () {
    test('background, surface, foreground', () {
      expect(appDarkColors.background, const Color(0xFF0F1311));
      expect(appDarkColors.card, const Color(0xFF1A1F1C));
      expect(appDarkColors.foreground, const Color(0xFFEDEAE2));
    });

    test('primary + accent dark', () {
      expect(appDarkColors.primary, const Color(0xFF7DA08B));
      expect(appDarkColors.secondary, const Color(0xFFD4A47A));
    });

    test('brightness dark', () {
      expect(appDarkColors.brightness, Brightness.dark);
    });
  });
}
```

- [ ] **Step 2: Lancer → fail**

```
flutter test test/core/theme/app_color_scheme_test.dart
```

Expected: FAIL — palette actuelle (sage/terracotta).

- [ ] **Step 3: Réécrire `lib/core/theme/app_color_scheme.dart`**

```dart
// lib/core/theme/app_color_scheme.dart
//
// Palette « Modern Craft » v3 — vert forêt + cuivre. Remplace la palette
// « Pastoral Chic » sage/terracotta. Cf. spec §1.1.
//
// Mapping FColors :
// - card        ↔ surface      (#FFFFFF / #1A1F1C)
// - muted       ↔ surfaceMuted (#F2EFE8 / #222825)
// - secondary   ↔ accent cuivre (#B8895C / #D4A47A)
// - destructive ↔ destructive  (#A8403E / #D46B68)
//
// Note : `error` = `destructive` (pas de distinction côté Forui).
//
// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

final FColors appLightColors = FColors(
  brightness: Brightness.light,
  systemOverlayStyle: SystemUiOverlayStyle.dark,
  background: const Color(0xFFFAF8F3),
  foreground: const Color(0xFF1B1F1A),
  primary: const Color(0xFF1F3A2E),
  primaryForeground: const Color(0xFFFAF8F3),
  secondary: const Color(0xFFB8895C),
  secondaryForeground: const Color(0xFFFAF8F3),
  muted: const Color(0xFFF2EFE8),
  mutedForeground: const Color(0xFF6B6F66),
  destructive: const Color(0xFFA8403E),
  destructiveForeground: const Color(0xFFFAF8F3),
  error: const Color(0xFFA8403E),
  errorForeground: const Color(0xFFFAF8F3),
  border: const Color(0xFFE8E4DA),
  barrier: const Color(0x801B1F1A),
  card: const Color(0xFFFFFFFF),
);

final FColors appDarkColors = FColors(
  brightness: Brightness.dark,
  systemOverlayStyle: SystemUiOverlayStyle.light,
  background: const Color(0xFF0F1311),
  foreground: const Color(0xFFEDEAE2),
  primary: const Color(0xFF7DA08B),
  primaryForeground: const Color(0xFF0F1311),
  secondary: const Color(0xFFD4A47A),
  secondaryForeground: const Color(0xFF0F1311),
  muted: const Color(0xFF222825),
  mutedForeground: const Color(0xFF9CA09A),
  destructive: const Color(0xFFD46B68),
  destructiveForeground: const Color(0xFF0F1311),
  error: const Color(0xFFD46B68),
  errorForeground: const Color(0xFF0F1311),
  border: const Color(0xFF2A302D),
  barrier: const Color(0x80EDEAE2),
  card: const Color(0xFF1A1F1C),
);
```

- [ ] **Step 4: Lancer → pass**

```
flutter test test/core/theme/app_color_scheme_test.dart
```

Expected: PASS.

- [ ] **Step 5: Smoke compile l'app entière**

```
flutter analyze
```

Expected: 0 errors. Warnings éventuels sur deprecated `FColors.toApproximateMaterialTheme()` etc., toléré.

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme/app_color_scheme.dart test/core/theme/app_color_scheme_test.dart
git commit -m "refactor(theme): swap palette to Modern Craft (forest + copper)"
```

---

### Task 4: Réécrire la typographie (Inter only, drop Fraunces)

**Files:**
- Modify: `lib/core/theme/app_typography.dart`
- Test: `test/core/theme/app_typography_test.dart`

- [ ] **Step 1: Écrire le test**

```dart
// test/core/theme/app_typography_test.dart
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:coup_laine/core/theme/app_typography.dart';

void main() {
  group('buildAppTypography — v3 Inter only', () {
    final base = FThemes.blue.light.touch.typography;
    final t = buildAppTypography(base);

    test('xl4 = display 36/700 sans serif', () {
      expect(t.xl4.fontSize, 36);
      expect(t.xl4.fontWeight, FontWeight.w700);
      expect(t.xl4.fontFamily, isNot('Fraunces'));
      expect(t.xl4.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('xl3 = title-xl 28/600', () {
      expect(t.xl3.fontSize, 28);
      expect(t.xl3.fontWeight, FontWeight.w600);
      expect(t.xl3.fontFamily, isNot('Fraunces'));
    });

    test('xl2 = title-lg 22/600', () {
      expect(t.xl2.fontSize, 22);
      expect(t.xl2.fontWeight, FontWeight.w600);
      expect(t.xl2.fontFamily, isNot('Fraunces'));
    });

    test('xl = title-md 18/600', () {
      expect(t.xl.fontSize, 18);
      expect(t.xl.fontWeight, FontWeight.w600);
    });

    test('lg = title-sm 16/600', () {
      expect(t.lg.fontSize, 16);
      expect(t.lg.fontWeight, FontWeight.w600);
    });

    test('base = body 15/400', () {
      expect(t.base.fontSize, 15);
      expect(t.base.fontWeight, FontWeight.w400);
    });

    test('sm = body-sm 13/400', () {
      expect(t.sm.fontSize, 13);
      expect(t.sm.fontWeight, FontWeight.w400);
    });

    test('xs = label 12/500', () {
      expect(t.xs.fontSize, 12);
      expect(t.xs.fontWeight, FontWeight.w500);
    });
  });
}
```

- [ ] **Step 2: Lancer → fail**

```
flutter test test/core/theme/app_typography_test.dart
```

Expected: FAIL — `xl4` reste à 40 et family Fraunces, etc.

- [ ] **Step 3: Réécrire `lib/core/theme/app_typography.dart`**

```dart
// lib/core/theme/app_typography.dart
//
// Modern Craft v3 — Inter sans-serif unique. Tabular figures activées
// systématiquement via FontFeature.tabularFigures(). La famille Fraunces
// est droppée du theme (le fichier d'asset reste en place jusqu'au
// cleanup de Plan 3).
import 'package:flutter/painting.dart';
import 'package:forui/forui.dart';

/// Re-shape la typo Forui pour v3 Modern Craft. Toutes les tier sont
/// Inter (héritée de Forui) ; Fraunces est droppé.
FTypography buildAppTypography(FTypography base) {
  const tabular = [FontFeature.tabularFigures()];

  return base.copyWith(
    // display 36 / 700 — tabular pour hero numbers
    xl4: base.xl4.copyWith(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -1.0,
      fontFeatures: tabular,
      // Pas de fontFamily explicite → garde la famille héritée (Inter via Forui).
      // Le test vérifie qu'on n'a PAS Fraunces.
    ),
    // title-xl 28 / 600
    xl3: base.xl3.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: -0.5,
    ),
    // title-lg 22 / 600
    xl2: base.xl2.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.3,
    ),
    // title-md 18 / 600
    xl: base.xl.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.2,
    ),
    // title-sm 16 / 600
    lg: base.lg.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.1,
    ),
    // body 15 / 400
    base: base.base.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    // body-sm 13 / 400
    sm: base.sm.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    // label 12 / 500
    xs: base.xs.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0.2,
    ),
  );
}

/// Style helper pour caption UPPERCASE (group headers, chip labels).
/// Construit à partir de `xs` du thème courant.
TextStyle captionStyle(TextStyle baseLabel) {
  return baseLabel.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );
}

/// Style helper pour les chiffres tabular partout (montants, durées, distances).
TextStyle tabularStyle(TextStyle base) {
  final existing = base.fontFeatures ?? const <FontFeature>[];
  if (existing.contains(const FontFeature.tabularFigures())) return base;
  return base.copyWith(
    fontFeatures: [...existing, const FontFeature.tabularFigures()],
  );
}
```

- [ ] **Step 4: Lancer → pass**

```
flutter test test/core/theme/app_typography_test.dart
```

Expected: PASS.

- [ ] **Step 5: `flutter analyze`**

```
flutter analyze lib/core/theme/
```

Expected: 0 errors.

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme/app_typography.dart test/core/theme/app_typography_test.dart
git commit -m "refactor(theme): drop Fraunces, Inter only with tabular figures"
```

---

### Task 5: Adapter `app_themes.dart`

**Files:**
- Modify: `lib/core/theme/app_themes.dart`

- [ ] **Step 1: Lire le fichier actuel**

```
cat lib/core/theme/app_themes.dart
```

Le fichier consomme `appLightColors`/`appDarkColors` et `buildAppTypography`. Le bloc `buttonColors` (qui swappe `secondaryForeground` par `foreground`) **n'est plus nécessaire** : avec la nouvelle palette, `secondaryForeground = #FAF8F3` (clair) sur `card = #FFFFFF` reste lisible *uniquement parce qu'on ne posera plus jamais de bouton outline secondaire sur card*. Mais pour ne pas casser un usage Forui caché, on **garde** le swap par sécurité.

- [ ] **Step 2: Mettre à jour le commentaire d'en-tête uniquement**

Remplacer le commentaire d'en-tête (lignes 1-19) par :

```dart
// lib/core/theme/app_themes.dart
//
// Construit FThemeData v3 Modern Craft via le factory FThemeData. On
// reconstruit chaque widget style avec notre palette (cuivre + vert forêt)
// pour éviter que les styles capturés par Forui restent sur la palette
// par défaut.
//
// `buttonColors` swap `secondaryForeground` par `foreground` : Forui's
// outline button utilise `secondaryForeground` comme couleur de label sur
// un fond `card` (blanc). Notre `secondaryForeground` est clair → label
// invisible. Ce swap n'affecte que les boutons.
import 'package:forui/forui.dart';

import 'app_color_scheme.dart';
import 'app_typography.dart';

FThemeData _buildTheme(FColors colors, FTypography baseTypography) {
  final typography = buildAppTypography(baseTypography);
  final style = FStyle.inherit(colors: colors, typography: typography, touch: true);
  final buttonColors = colors.copyWith(secondaryForeground: colors.foreground);
  return FThemeData(
    colors: colors,
    touch: true,
    typography: typography,
    buttonStyles: FButtonStyles.inherit(
      colors: buttonColors,
      typography: typography,
      style: style,
      touch: true,
    ),
  );
}

final FThemeData appLightTheme = _buildTheme(
  appLightColors,
  FThemes.blue.light.touch.typography,
);

final FThemeData appDarkTheme = _buildTheme(
  appDarkColors,
  FThemes.blue.dark.touch.typography,
);
```

- [ ] **Step 3: `flutter analyze`**

```
flutter analyze lib/core/theme/app_themes.dart
```

Expected: 0 errors.

- [ ] **Step 4: Smoke build entière**

```
flutter analyze
```

Expected: 0 errors. Si des écrans cassent à cause de couleurs renommées, NOTER mais ne pas corriger ici (les écrans sont du scope du Plan 2).

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_themes.dart
git commit -m "refactor(theme): rewire FThemeData for Modern Craft palette"
```

---

## Phase B — Icon assets (silhouettes animales custom)

### Task 6: Créer les 4 SVGs animaux + helper `iconForSpeciesKey`

**Files:**
- Create: `assets/icons/cl_sheep.svg`, `cl_horse.svg`, `cl_cow.svg`, `cl_goat.svg`
- Modify: `pubspec.yaml`
- Create: `lib/core/animal_icons.dart`
- Test: `test/core/animal_icons_test.dart`

- [ ] **Step 1: Créer le dossier `assets/icons/`**

```
mkdir -p assets/icons
```

- [ ] **Step 2: Créer `assets/icons/cl_sheep.svg`**

Stroke 1.75, viewBox 24×24, style cohérent Lucide. Silhouette mouton : corps en nuage + 4 pattes + tête.

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">
  <path d="M5 13a3 3 0 0 1 0-6 3 3 0 0 1 2.4 1.2A3.5 3.5 0 0 1 11 7a3.5 3.5 0 0 1 3.6 1.2A3 3 0 0 1 17 7a3 3 0 0 1 0 6"/>
  <path d="M5 13c0 2.5 2.7 4 7 4s7-1.5 7-4"/>
  <path d="M7 17v3"/>
  <path d="M10 18v2"/>
  <path d="M14 18v2"/>
  <path d="M17 17v3"/>
  <circle cx="17.5" cy="9" r="0.5" fill="currentColor"/>
</svg>
```

- [ ] **Step 3: Créer `assets/icons/cl_horse.svg`**

Silhouette cheval : corps + tête haute + crinière + 4 pattes + queue.

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3 14c0-2 2-4 5-4h6l3-4 1 1-1 3 2 1 2 2v3"/>
  <path d="M3 14h18"/>
  <path d="M5 14v5"/>
  <path d="M8 14v5"/>
  <path d="M14 14v5"/>
  <path d="M17 14v5"/>
  <path d="M21 14c-1 1-2 1-3 0"/>
  <path d="M16 7l1-2"/>
  <circle cx="18" cy="8" r="0.5" fill="currentColor"/>
</svg>
```

- [ ] **Step 4: Créer `assets/icons/cl_cow.svg`**

Silhouette bovin : corps trapu + cornes + 4 pattes + queue + pis.

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 13c0-2 2-3 4-3h7c2 0 4 1 4 3v3"/>
  <path d="M4 13v3"/>
  <path d="M4 16h15"/>
  <path d="M6 16v4"/>
  <path d="M9 16v4"/>
  <path d="M14 16v4"/>
  <path d="M17 16v4"/>
  <path d="M19 13c1 1 2 1 2 0"/>
  <path d="M3 9c1-1 2-1 3 0"/>
  <path d="M16 9c1-1 2-1 3 0"/>
  <circle cx="6" cy="11" r="0.5" fill="currentColor"/>
  <path d="M11 19c0 1 0 2-1 2"/>
</svg>
```

- [ ] **Step 5: Créer `assets/icons/cl_goat.svg`**

Silhouette caprin : corps moyen + cornes recourbées + barbe + 4 pattes.

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 14c0-2 2-3 4-3h6c2 0 4 1 4 3v2"/>
  <path d="M4 14v2"/>
  <path d="M4 16h14"/>
  <path d="M6 16v4"/>
  <path d="M9 16v4"/>
  <path d="M13 16v4"/>
  <path d="M16 16v4"/>
  <path d="M18 11l1-3"/>
  <path d="M19 8c1-1 2-2 1-3"/>
  <path d="M16 8c1-1 1-2 0-3"/>
  <path d="M15 11v3"/>
  <path d="M14 14l-1 2"/>
  <circle cx="17" cy="10" r="0.4" fill="currentColor"/>
</svg>
```

- [ ] **Step 6: Modifier `pubspec.yaml` pour exposer le dossier**

Remplacer le bloc `assets:` (lignes 45-47 actuellement) par :

```yaml
  assets:
    - .env
    - assets/illustrations/
    - assets/icons/
```

- [ ] **Step 7: Écrire le test du helper**

```dart
// test/core/animal_icons_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/animal_icons.dart';

void main() {
  group('iconAssetForSpeciesKey', () {
    test('mouton, cheval, bovin, caprin → asset SVG', () {
      expect(iconAssetForSpeciesKey('mouton'), 'assets/icons/cl_sheep.svg');
      expect(iconAssetForSpeciesKey('cheval'), 'assets/icons/cl_horse.svg');
      expect(iconAssetForSpeciesKey('bovin'), 'assets/icons/cl_cow.svg');
      expect(iconAssetForSpeciesKey('caprin'), 'assets/icons/cl_goat.svg');
    });

    test('case-insensitive', () {
      expect(iconAssetForSpeciesKey('Mouton'), 'assets/icons/cl_sheep.svg');
      expect(iconAssetForSpeciesKey('CHEVAL'), 'assets/icons/cl_horse.svg');
    });

    test('clé inconnue → null (fallback à FIcons côté caller)', () {
      expect(iconAssetForSpeciesKey('lama'), isNull);
      expect(iconAssetForSpeciesKey(''), isNull);
    });
  });
}
```

- [ ] **Step 8: Lancer → fail (file missing)**

```
flutter test test/core/animal_icons_test.dart
```

Expected: FAIL.

- [ ] **Step 9: Créer `lib/core/animal_icons.dart`**

```dart
// lib/core/animal_icons.dart
//
// Mapping d'une `Species.iconKey` vers un asset SVG custom (silhouette
// animale). Les espèces seed utilisent les clés `mouton`/`cheval`/`bovin`/
// `caprin`. Les espèces custom retournent `null` ; le caller doit utiliser
// un fallback (typiquement `FIcons.pawPrint`).

const _kSpeciesIconAssets = <String, String>{
  'mouton': 'assets/icons/cl_sheep.svg',
  'cheval': 'assets/icons/cl_horse.svg',
  'bovin': 'assets/icons/cl_cow.svg',
  'caprin': 'assets/icons/cl_goat.svg',
};

/// Retourne le chemin de l'asset SVG associé à une `iconKey` d'espèce, ou
/// `null` si la clé est inconnue (custom species, vide).
/// La comparaison est case-insensitive.
String? iconAssetForSpeciesKey(String? key) {
  if (key == null || key.isEmpty) return null;
  return _kSpeciesIconAssets[key.toLowerCase()];
}
```

- [ ] **Step 10: Lancer → pass**

```
flutter test test/core/animal_icons_test.dart
```

Expected: PASS.

- [ ] **Step 11: `flutter analyze` + smoke build app**

```
flutter analyze
flutter build apk --debug --target-platform android-arm64
```

Expected: build OK (assets/icons/ référencés sans erreur).

- [ ] **Step 12: Commit**

```bash
git add assets/icons/ pubspec.yaml lib/core/animal_icons.dart test/core/animal_icons_test.dart
git commit -m "feat(assets): add 4 animal silhouette SVGs + iconAssetForSpeciesKey helper"
```

---

## Phase C — Refactor des composants existants

### Task 7: Refactor `AppPrimaryButton` (52dp, drop forced prefixIcon)

**Files:**
- Modify: `lib/presentation/widgets/app_primary_button.dart`

Le seul changement : la hauteur descend de 56 à 52 (déjà via `AppSizes.primaryButtonHeight` mis à 52 en Task 1). On vérifie que ça compile et on n'introduit pas de régression.

- [ ] **Step 1: `flutter analyze` (vérifier que le composant compile avec les nouveaux tokens)**

```
flutter analyze lib/presentation/widgets/app_primary_button.dart
```

Expected: 0 errors. Aucune ligne à modifier — `AppSizes.primaryButtonHeight` est consommée ; la valeur a changé en Task 1.

- [ ] **Step 2: Mettre à jour le commentaire d'en-tête**

Remplacer la docstring actuelle (lignes 6-8) par :

```dart
/// Primary CTA button with consistent height (`AppSizes.primaryButtonHeight`,
/// 52dp en v3 Modern Craft), generous horizontal padding from Forui's FButton,
/// and Inter 600 from theme typography. Optional loading shows a small
/// circular progress in place of the label and disables the press.
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_primary_button.dart
git commit -m "docs(widgets): update AppPrimaryButton docstring for v3 height"
```

---

### Task 8: Refactor `AppSectionCard` (border 0.5px hairline, no forced iconBackground)

**Files:**
- Modify: `lib/presentation/widgets/app_section_card.dart`

- [ ] **Step 1: Réécrire**

Remplacer le contenu par :

```dart
// lib/presentation/widgets/app_section_card.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// Card de section v3 Modern Craft : surface (card), 0.5px hairline border,
/// padding 20dp, header avec icon 28dp + title-md (`theme.typography.xl`).
///
/// L'icône a un fond `surfaceMuted` par défaut (au lieu de secondary forcé).
/// Le caller peut override avec `iconBackground`/`iconForeground`.
class AppSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color? iconBackground;
  final Color? iconForeground;
  final Widget? trailing;

  const AppSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.iconBackground,
    this.iconForeground,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bg = iconBackground ?? theme.colors.muted;
    final fg = iconForeground ?? theme.colors.foreground;

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: theme.colors.border,
          width: AppSizes.hairlineBorder,
        ),
      ),
      padding: AppSizes.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.sectionIconCircle,
                height: AppSizes.sectionIconCircle,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: fg, size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.typography.xl.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`**

```
flutter analyze lib/presentation/widgets/app_section_card.dart
```

Expected: 0 errors.

- [ ] **Step 3: Smoke build app entière (les écrans qui consomment `AppSectionCard` doivent toujours compiler)**

```
flutter analyze
```

Expected: 0 errors. Si un écran passait `iconBackground: theme.colors.destructive` (cas du recompute banner dans Clients list), c'est OK — le param reste supporté.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/app_section_card.dart
git commit -m "refactor(widgets): AppSectionCard v3 (hairline border, muted icon bg, optional trailing)"
```

---

### Task 9: Refactor `AppEmptyState` (illustration plus petite, support pictogramme)

**Files:**
- Modify: `lib/presentation/widgets/app_empty_state.dart`

- [ ] **Step 1: Réécrire**

```dart
// lib/presentation/widgets/app_empty_state.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// État vide v3 Modern Craft. Centré, généreux. Soit une illustration
/// (asset SVG existant `assets/illustrations/`) soit un pictogramme
/// `IconData` (Lucide via FIcons) en `subtleForeground`.
class AppEmptyState extends StatelessWidget {
  final String? illustrationAsset;
  final IconData? icon;
  final String title;
  final String body;
  final Widget? action;
  final Widget? secondaryAction;
  final double illustrationHeight;

  const AppEmptyState({
    super.key,
    this.illustrationAsset,
    this.icon,
    required this.title,
    required this.body,
    this.action,
    this.secondaryAction,
    this.illustrationHeight = 120,
  }) : assert(
          (illustrationAsset != null) ^ (icon != null),
          'fournir soit illustrationAsset soit icon (exclusif)',
        );

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.huge,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (illustrationAsset != null)
            SvgPicture.asset(
              illustrationAsset!,
              height: illustrationHeight,
              fit: BoxFit.contain,
            )
          else
            Icon(
              icon!,
              size: AppSizes.heroIconCircle,
              // subtleForeground n'existe pas dans FColors ; on utilise muted
              // comme proxy. Plan 2 introduira un wrapper si besoin.
              color: theme.colors.mutedForeground,
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.typography.xl2.copyWith(
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.typography.base.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
          if (secondaryAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            secondaryAction!,
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze` + check appelants**

```
flutter analyze
```

Si l'app casse parce qu'un appelant passait juste `illustrationAsset:` (cas le plus courant), c'est OK — l'API existante reste valide. Le nouveau param `icon` est additionnel.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_empty_state.dart
git commit -m "refactor(widgets): AppEmptyState v3 (smaller illustration, optional icon, secondary action)"
```

---

### Task 10: Refactor `AppBadge` (couleurs sémantiques nouvelles, dot bare déprécié)

**Files:**
- Modify: `lib/presentation/widgets/app_badge.dart`

- [ ] **Step 1: Réécrire**

Avec la nouvelle palette, `secondary = cuivre` au lieu de terracotta. Les usages actuels (`AppBadge.waiting`, `AppBadge.planned`) qui utilisent `colors.secondary` continueront à rendre, mais en cuivre. C'est compatible avec la spec (`accent` cuivre = highlight). On garde la sémantique mais on ajoute `success`/`info` factories explicites pour le futur.

```dart
// lib/presentation/widgets/app_badge.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../domain/use_cases/client_status.dart';

/// Badge pill ou square v3. Icône + label par défaut (les bare dots sont
/// déconseillés ; utiliser un Container 10dp colored à la place).
class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  const AppBadge._({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  factory AppBadge.waiting(BuildContext context, {String label = 'En attente'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.clock,
      background: colors.secondary,
      foreground: colors.secondaryForeground,
    );
  }

  factory AppBadge.fromStatus(
    BuildContext context, {
    required ClientStatus status,
    required String label,
  }) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: switch (status) {
        ClientStatus.defaultStatus => FIcons.circle,
        ClientStatus.waiting => FIcons.clock,
        ClientStatus.scheduled => FIcons.calendar,
        ClientStatus.done => FIcons.check,
        ClientStatus.noAnimals => FIcons.x,
        ClientStatus.banned => FIcons.ban,
      },
      background: switch (status) {
        ClientStatus.banned => colors.destructive,
        ClientStatus.waiting => colors.secondary,
        _ => colors.muted,
      },
      foreground: switch (status) {
        ClientStatus.banned => colors.destructiveForeground,
        ClientStatus.waiting => colors.secondaryForeground,
        _ => colors.foreground,
      },
    );
  }

  factory AppBadge.recompute(BuildContext context, {String label = 'Distances'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.refreshCw,
      background: colors.muted,
      foreground: colors.mutedForeground,
    );
  }

  factory AppBadge.completed(BuildContext context, {String label = 'Réalisée'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.check,
      background: colors.primary,
      foreground: colors.primaryForeground,
    );
  }

  factory AppBadge.planned(BuildContext context, {String label = 'Planifiée'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.calendar,
      background: colors.secondary,
      foreground: colors.secondaryForeground,
    );
  }

  factory AppBadge.longDay(BuildContext context, {String label = 'Journée longue'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.sunset,
      background: colors.muted,
      foreground: colors.foreground,
    );
  }

  /// Nouveau v3 — succès générique.
  factory AppBadge.success(BuildContext context, {required String label, IconData? icon}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: icon ?? FIcons.check,
      background: colors.primary,
      foreground: colors.primaryForeground,
    );
  }

  /// Nouveau v3 — info neutre.
  factory AppBadge.info(BuildContext context, {required String label, IconData? icon}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: icon,
      background: colors.muted,
      foreground: colors.foreground,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: theme.typography.xs.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`**

```
flutter analyze lib/presentation/widgets/app_badge.dart
```

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_badge.dart
git commit -m "refactor(widgets): AppBadge v3 (add success/info factories, semantic colors)"
```

---

### Task 11: Refactor `AnimalCountsBadges` pour utiliser les SVG espèces

**Files:**
- Modify: `lib/presentation/widgets/animal_counts_badges.dart`

- [ ] **Step 1: Lire le fichier actuel et identifier les usages d'icônes**

```
flutter analyze lib/presentation/widgets/animal_counts_badges.dart
```

Note : ce widget est consommé partout (Clients list/detail, Tour detail, Map popup). On ne change que les icônes, pas l'API publique (`AnimalCountsBadges(counts:, mode:)`).

- [ ] **Step 2: Inspecter le rendu actuel des icônes par espèce**

```
flutter analyze --no-pub lib/presentation/widgets/animal_counts_badges.dart
```

Repérer où une icône Lucide est rendue per-species (typiquement dans un helper local `_iconForSpecies` ou inline). Si le widget rend juste du texte (aucune icône), passer cette task et committer juste un commentaire de pointage.

- [ ] **Step 3: Si le widget rend des icônes per-species, les remplacer par `SvgPicture.asset(iconAssetForSpeciesKey(...))` avec fallback `FIcons.pawPrint`**

Pattern type à insérer en haut du fichier :

```dart
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forui/forui.dart';
import '../../core/animal_icons.dart';
```

Helper interne :

```dart
Widget _speciesIcon(BuildContext context, String? iconKey, {double size = 16}) {
  final theme = context.theme;
  final asset = iconAssetForSpeciesKey(iconKey);
  if (asset != null) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        theme.colors.foreground,
        BlendMode.srcIn,
      ),
    );
  }
  return Icon(FIcons.pawPrint, size: size, color: theme.colors.foreground);
}
```

Remplacer chaque rendu d'icône d'espèce par `_speciesIcon(context, species.iconKey)`. Garder l'API publique du widget intacte.

- [ ] **Step 4: Si le widget ne rend QUE du texte (pas d'icône) → ajouter le rendu de l'icône en mode `detailed` uniquement (le mode `compact` reste texte-only)**

Pattern : dans le mode `detailed`, ajouter un `Row` avec `_speciesIcon(...)` à gauche du label espèce.

- [ ] **Step 5: `flutter analyze`**

```
flutter analyze
```

Expected: 0 errors. Smoke test : ouvrir manuellement l'app, vérifier que la liste clients rend les badges sans crash.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/widgets/animal_counts_badges.dart
git commit -m "refactor(widgets): AnimalCountsBadges uses cl_*.svg icons via iconAssetForSpeciesKey"
```

---

## Phase D — Nouveaux composants signature

### Task 12: `AppStat` (icon + number + unit inline)

**Files:**
- Create: `lib/presentation/widgets/app_stat.dart`

- [ ] **Step 1: Créer le widget**

```dart
// lib/presentation/widgets/app_stat.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Micro-composant inline : `<icon> <number tabular> <unit muted>`.
/// Brique de base des KPIs et des metadata rows.
class AppStat extends StatelessWidget {
  final IconData? icon;
  final Widget? leading; // Pour passer un SvgPicture (pictogramme custom)
  final String value;
  final String? unit;
  final Color? valueColor;
  final double iconSize;

  const AppStat({
    super.key,
    this.icon,
    this.leading,
    required this.value,
    this.unit,
    this.valueColor,
    this.iconSize = 14,
  }) : assert(icon == null || leading == null, 'icon ou leading, pas les deux');

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final valueStyle = tabularStyle(theme.typography.sm).copyWith(
      color: valueColor ?? theme.colors.foreground,
      fontWeight: FontWeight.w600,
    );
    final unitStyle = theme.typography.sm.copyWith(
      color: theme.colors.mutedForeground,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) leading!,
        if (icon != null)
          Icon(icon, size: iconSize, color: theme.colors.mutedForeground),
        if (icon != null || leading != null)
          const SizedBox(width: AppSpacing.xxs),
        Text(value, style: valueStyle),
        if (unit != null) ...[
          const SizedBox(width: 2),
          Text(unit!, style: unitStyle),
        ],
      ],
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`**

```
flutter analyze lib/presentation/widgets/app_stat.dart
```

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_stat.dart
git commit -m "feat(widgets): add AppStat (icon + tabular number + unit)"
```

---

### Task 13: `AppKpiCard` (single big KPI)

**Files:**
- Create: `lib/presentation/widgets/app_kpi_card.dart`

- [ ] **Step 1: Créer le widget**

```dart
// lib/presentation/widgets/app_kpi_card.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Single KPI card : grand chiffre `display 36` en accent cuivre, label
/// caption UPPERCASE muted, optional delta vs période précédente.
class AppKpiCard extends StatelessWidget {
  final String value;
  final String label;
  final String? delta;       // ex. "+12 %", "-3"
  final bool? deltaPositive; // null = neutre, true = primary, false = destructive
  final Widget? sparkline;   // optionnel — un widget custom 8-12 points

  const AppKpiCard({
    super.key,
    required this.value,
    required this.label,
    this.delta,
    this.deltaPositive,
    this.sparkline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final valueStyle = tabularStyle(theme.typography.xl4).copyWith(
      color: theme.colors.secondary, // accent cuivre
    );
    final labelStyle = captionStyle(theme.typography.xs).copyWith(
      color: theme.colors.mutedForeground,
    );

    Color deltaColor;
    if (deltaPositive == true) {
      deltaColor = theme.colors.primary;
    } else if (deltaPositive == false) {
      deltaColor = theme.colors.destructive;
    } else {
      deltaColor = theme.colors.mutedForeground;
    }

    return Container(
      padding: AppSizes.cardPadding,
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: theme.colors.border,
          width: AppSizes.hairlineBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: labelStyle),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: valueStyle),
              if (delta != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    delta!,
                    style: tabularStyle(theme.typography.sm).copyWith(
                      color: deltaColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (sparkline != null) ...[
            const SizedBox(height: AppSpacing.sm),
            sparkline!,
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`** → expected 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_kpi_card.dart
git commit -m "feat(widgets): add AppKpiCard (display number + caption + delta)"
```

---

### Task 14: `AppKpiRow` (2-4 KPIs côte à côte avec hairlines verticales)

**Files:**
- Create: `lib/presentation/widgets/app_kpi_row.dart`

- [ ] **Step 1: Créer le widget**

```dart
// lib/presentation/widgets/app_kpi_row.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Une « cellule » de KpiRow : valeur tabular + label caption.
class AppKpiCell {
  final String value;
  final String label;
  final Color? valueColor; // null → foreground ; spec : accent cuivre pour le chiffre principal
  const AppKpiCell({
    required this.value,
    required this.label,
    this.valueColor,
  });
}

/// Rangée de 2-4 mini-KPIs côte à côte, séparés par hairlines verticales
/// (0.5px). Surface (`card`), border 0.5px, padding 16dp vertical.
///
/// Ex. usage Tour detail : `AppKpiRow(cells: [
///   AppKpiCell(value: '47.2', label: 'km'),
///   AppKpiCell(value: '6h12', label: 'durée'),
///   AppKpiCell(value: '480 €', label: 'revenu', valueColor: ...accent),
///   AppKpiCell(value: '12', label: 'animaux'),
/// ])`.
class AppKpiRow extends StatelessWidget {
  final List<AppKpiCell> cells;

  const AppKpiRow({super.key, required this.cells})
      : assert(cells.length >= 2 && cells.length <= 4,
            'AppKpiRow accepte 2 à 4 cellules');

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final valueStyle = tabularStyle(theme.typography.xl).copyWith(
      color: theme.colors.foreground,
      fontWeight: FontWeight.w600,
    );
    final labelStyle = captionStyle(theme.typography.xs).copyWith(
      color: theme.colors.mutedForeground,
    );

    final children = <Widget>[];
    for (var i = 0; i < cells.length; i++) {
      final c = cells[i];
      children.add(Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                c.value,
                style: valueStyle.copyWith(
                  color: c.valueColor ?? theme.colors.foreground,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(c.label.toUpperCase(), style: labelStyle),
            ],
          ),
        ),
      ));
      if (i < cells.length - 1) {
        children.add(Container(
          width: AppSizes.hairlineBorder,
          color: theme.colors.border,
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: theme.colors.border,
          width: AppSizes.hairlineBorder,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_kpi_row.dart
git commit -m "feat(widgets): add AppKpiRow (2-4 cells with hairline separators)"
```

---

### Task 15: `AppListTile` (compact / standard / rich variants)

**Files:**
- Create: `lib/presentation/widgets/app_list_tile.dart`

- [ ] **Step 1: Créer le widget**

```dart
// lib/presentation/widgets/app_list_tile.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// Variants supportés.
enum AppListTileVariant {
  /// 1 ligne : prefix + title + suffix.
  compact,
  /// 2 lignes : title + subtitle italic.
  standard,
  /// 3-4 lignes : title + subtitle italic + metadata + suffix.
  rich,
}

/// Tile v3 Modern Craft pour listes denses. Surface, hairline border,
/// padding 14×16. Remplace les usages directs de `FTile`.
///
/// `metadata` n'est utilisé qu'en variant `rich`.
class AppListTile extends StatelessWidget {
  final AppListTileVariant variant;
  final Widget? prefix;
  final String title;
  final String? subtitle;       // Rendu italique en standard et rich
  final Widget? metadata;       // Row d'AppStat ou similaire — rich uniquement
  final Widget? suffix;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppListTile({
    super.key,
    this.variant = AppListTileVariant.standard,
    this.prefix,
    required this.title,
    this.subtitle,
    this.metadata,
    this.suffix,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final titleStyle = theme.typography.lg.copyWith(
      color: theme.colors.foreground,
    );
    final subtitleStyle = theme.typography.sm.copyWith(
      color: theme.colors.mutedForeground,
      fontStyle: FontStyle.italic,
    );

    Widget content;
    switch (variant) {
      case AppListTileVariant.compact:
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (prefix != null) ...[
              prefix!,
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: AppSpacing.sm),
              suffix!,
            ],
          ],
        );
        break;

      case AppListTileVariant.standard:
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (prefix != null) ...[
              prefix!,
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: titleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxxs),
                    Text(subtitle!,
                        style: subtitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: AppSpacing.sm),
              suffix!,
            ],
          ],
        );
        break;

      case AppListTileVariant.rich:
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (prefix != null) ...[
              prefix!,
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: titleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxxs),
                    Text(subtitle!,
                        style: subtitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (metadata != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    metadata!,
                  ],
                ],
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: AppSpacing.sm),
              suffix!,
            ],
          ],
        );
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      onLongPress: onLongPress == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onLongPress!();
            },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colors.card,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: theme.colors.border,
            width: AppSizes.hairlineBorder,
          ),
        ),
        padding: AppSizes.listTilePadding,
        child: content,
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_list_tile.dart
git commit -m "feat(widgets): add AppListTile (compact/standard/rich variants)"
```

---

### Task 16: `AppHeader` (label-aware actions, optional subtitle)

**Files:**
- Create: `lib/presentation/widgets/app_header.dart`

- [ ] **Step 1: Créer le widget**

```dart
// lib/presentation/widgets/app_header.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';

/// Action décrite côté caller. Si la largeur disponible permet le label,
/// on rend `[icon] label` ; sinon on rend juste l'icône (touch target 44dp,
/// le tooltip Forui montre le label sur tap-and-hold).
class AppHeaderAction {
  final IconData icon;
  final String label;
  final VoidCallback? onPress;
  final bool destructive;

  const AppHeaderAction({
    required this.icon,
    required this.label,
    required this.onPress,
    this.destructive = false,
  });
}

/// Header v3. Hauteur ~64dp + padding horizontal. `[back?] [title-lg + subtitle?]
/// [trailing actions]`. Les actions affichent leur label si la width
/// disponible ≥ 360dp, sinon icon-only avec tooltip.
class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final List<AppHeaderAction> actions;
  final VoidCallback? onBack;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.actions = const [],
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final labelMode = MediaQuery.sizeOf(context).width >= 360;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBackButton)
            FButton.icon(
              onPress: onBack ?? () => context.pop(),
              child: const Icon(FIcons.chevronLeft),
            ),
          if (showBackButton) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.typography.xl2.copyWith(
                    color: theme.colors.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    subtitle!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          for (final a in actions) ...[
            const SizedBox(width: AppSpacing.xs),
            _renderAction(context, a, labelMode: labelMode),
          ],
        ],
      ),
    );
  }

  Widget _renderAction(BuildContext context, AppHeaderAction a,
      {required bool labelMode}) {
    if (labelMode) {
      return FButton(
        variant: FButtonVariant.outline,
        size: FButtonSizeVariant.sm,
        prefix: Icon(a.icon),
        onPress: a.onPress,
        child: Text(a.label),
      );
    }
    return FButton.icon(onPress: a.onPress, child: Icon(a.icon));
  }
}
```

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_header.dart
git commit -m "feat(widgets): add AppHeader (label-aware actions, optional subtitle)"
```

---

### Task 17: `AppActionBar` (sticky bottom, max 3 actions)

**Files:**
- Create: `lib/presentation/widgets/app_action_bar.dart`

- [ ] **Step 1: Créer le widget**

```dart
// lib/presentation/widgets/app_action_bar.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// Action bar sticky bottom v3. Hauteur 64dp + safe-area, surface (card),
/// hairline 0.5px en haut. Contient 1 à 3 actions.
///
/// `primary` = CTA plein-largeur si rendu seul ; sinon partage la rangée
/// avec `secondary` (50/50). Si `secondary` ET `tertiary` sont fournis et
/// pas de `primary`, on rend les 3 outline répartis equal-flex.
class AppActionBar extends StatelessWidget {
  final Widget? primary;
  final Widget? secondary;
  final Widget? tertiary;

  const AppActionBar({
    super.key,
    this.primary,
    this.secondary,
    this.tertiary,
  }) : assert(primary != null || secondary != null || tertiary != null,
            'au moins une action');

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final children = <Widget>[];

    if (primary != null && secondary == null && tertiary == null) {
      children.add(Expanded(child: primary!));
    } else if (primary != null && secondary != null) {
      children.addAll([
        Expanded(child: secondary!),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: primary!),
      ]);
    } else {
      // 2 ou 3 outline répartis
      if (tertiary != null) children.add(Expanded(child: tertiary!));
      if (secondary != null) {
        if (children.isNotEmpty) children.add(const SizedBox(width: AppSpacing.sm));
        children.add(Expanded(child: secondary!));
      }
      if (primary != null) {
        if (children.isNotEmpty) children.add(const SizedBox(width: AppSpacing.sm));
        children.add(Expanded(child: primary!));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.card,
        border: Border(
          top: BorderSide(
            color: theme.colors.border,
            width: AppSizes.hairlineBorder,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: children,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_action_bar.dart
git commit -m "feat(widgets): add AppActionBar (sticky bottom, 1-3 actions)"
```

---

### Task 18: `AppTimelineRow`

**Files:**
- Create: `lib/presentation/widgets/app_timeline_row.dart`

- [ ] **Step 1: Créer le widget**

```dart
// lib/presentation/widgets/app_timeline_row.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Ligne d'historique dense. Indicateur date à gauche, pictogramme métier,
/// titre court, breakdown italic, montant + durée tabular à droite.
class AppTimelineRow extends StatelessWidget {
  final String dateLabel;       // ex. "03 sept 2025"
  final IconData icon;          // FIcons.scissors / FIcons.pencil
  final String title;           // ex. "Tournée #128"
  final String? breakdown;      // ex. "3 Tonte Petit · 1 Parage" (rendu italic)
  final String? amount;         // ex. "180 €"
  final String? duration;       // ex. "45m"
  final VoidCallback? onTap;

  const AppTimelineRow({
    super.key,
    required this.dateLabel,
    required this.icon,
    required this.title,
    this.breakdown,
    this.amount,
    this.duration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date verticale à gauche
            SizedBox(
              width: 70,
              child: Text(
                dateLabel,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
            // Pictogramme + content
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: theme.colors.muted,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 14, color: theme.colors.foreground),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.typography.lg.copyWith(
                      color: theme.colors.foreground,
                    ),
                  ),
                  if (breakdown != null) ...[
                    const SizedBox(height: AppSpacing.xxxs),
                    Text(
                      breakdown!,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Montant + durée à droite (tabular)
            if (amount != null || duration != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (amount != null)
                    Text(
                      amount!,
                      style: tabularStyle(theme.typography.sm).copyWith(
                        color: theme.colors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (duration != null) ...[
                    if (amount != null) const SizedBox(height: 2),
                    Text(
                      duration!,
                      style: tabularStyle(theme.typography.sm).copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_timeline_row.dart
git commit -m "feat(widgets): add AppTimelineRow (dense history row)"
```

---

### Task 19: `AppDiffRow` + test pure-dart de `computeDelta`

**Files:**
- Create: `lib/presentation/widgets/app_diff_row.dart`
- Test: `test/presentation/widgets/app_diff_row_test.dart`

- [ ] **Step 1: Écrire le test du helper pur**

```dart
// test/presentation/widgets/app_diff_row_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/presentation/widgets/app_diff_row.dart';

void main() {
  group('AppDiffRow.computeDelta', () {
    test('égal → DiffStatus.same, delta 0', () {
      final r = AppDiffRow.computeDelta(planned: 3, actual: 3);
      expect(r.status, DiffStatus.same);
      expect(r.delta, 0);
    });

    test('actual > planned → DiffStatus.up, delta positif', () {
      final r = AppDiffRow.computeDelta(planned: 2, actual: 3);
      expect(r.status, DiffStatus.up);
      expect(r.delta, 1);
    });

    test('actual < planned → DiffStatus.down, delta négatif', () {
      final r = AppDiffRow.computeDelta(planned: 5, actual: 4);
      expect(r.status, DiffStatus.down);
      expect(r.delta, -1);
    });

    test('hors-plan (planned == 0, actual > 0) → DiffStatus.bonus', () {
      final r = AppDiffRow.computeDelta(planned: 0, actual: 2);
      expect(r.status, DiffStatus.bonus);
      expect(r.delta, 2);
    });
  });
}
```

- [ ] **Step 2: Lancer → fail (file missing)**

```
flutter test test/presentation/widgets/app_diff_row_test.dart
```

- [ ] **Step 3: Créer `lib/presentation/widgets/app_diff_row.dart`**

```dart
// lib/presentation/widgets/app_diff_row.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../core/theme/app_typography.dart';

enum DiffStatus { same, up, down, bonus }

class DiffResult {
  final DiffStatus status;
  final int delta;
  const DiffResult(this.status, this.delta);
}

/// Affiche prévu → effectué côte à côte avec delta visuel. Utilisé sur le
/// Tour completion screen.
///
/// `planned == 0 && actual > 0` → `DiffStatus.bonus` (presta hors-plan).
/// `planned > 0 && actual == planned` → `same`.
/// `actual > planned` → `up`. `actual < planned` → `down`.
class AppDiffRow extends StatelessWidget {
  final String label;
  final int planned;
  final int actual;
  final String? amountLabel; // ex. "180 €"

  const AppDiffRow({
    super.key,
    required this.label,
    required this.planned,
    required this.actual,
    this.amountLabel,
  });

  static DiffResult computeDelta({required int planned, required int actual}) {
    if (planned == 0 && actual > 0) {
      return DiffResult(DiffStatus.bonus, actual);
    }
    final d = actual - planned;
    if (d == 0) return const DiffResult(DiffStatus.same, 0);
    if (d > 0) return DiffResult(DiffStatus.up, d);
    return DiffResult(DiffStatus.down, d);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final r = computeDelta(planned: planned, actual: actual);

    final (icon, color) = switch (r.status) {
      DiffStatus.same => (FIcons.check, theme.colors.mutedForeground),
      DiffStatus.up => (FIcons.arrowUp, theme.colors.primary),
      DiffStatus.down => (FIcons.arrowDown, theme.colors.destructive),
      DiffStatus.bonus => (FIcons.plus, theme.colors.secondary),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.typography.base.copyWith(
                color: theme.colors.foreground,
              ),
            ),
          ),
          if (planned > 0)
            Text(
              'prévu $planned',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          const SizedBox(width: AppSpacing.xs),
          Icon(FIcons.chevronRight, size: 12, color: theme.colors.mutedForeground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$actual',
            style: tabularStyle(theme.typography.base).copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(icon, size: 14, color: color),
          if (amountLabel != null) ...[
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 60,
              child: Text(
                amountLabel!,
                textAlign: TextAlign.end,
                style: tabularStyle(theme.typography.sm).copyWith(
                  color: theme.colors.foreground,
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

- [ ] **Step 4: Lancer → pass**

```
flutter test test/presentation/widgets/app_diff_row_test.dart
```

Expected: PASS.

- [ ] **Step 5: `flutter analyze`** → 0 errors.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/widgets/app_diff_row.dart test/presentation/widgets/app_diff_row_test.dart
git commit -m "feat(widgets): add AppDiffRow (planned vs actual with delta)"
```

---

### Task 20: `AppFAB` (regular + extended)

**Files:**
- Create: `lib/presentation/widgets/app_fab.dart`

- [ ] **Step 1: Créer le widget**

```dart
// lib/presentation/widgets/app_fab.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// FAB v3. Variante `regular` (56dp circulaire) ou `extended` (56dp pill
/// avec label). Utilise `primary` fill. Position bottom-right gérée par
/// le caller (typiquement dans un `Stack`).
class AppFAB extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onPress;
  final bool extended;

  const AppFAB({
    super.key,
    required this.icon,
    required this.onPress,
    this.label,
    this.extended = false,
  }) : assert(!extended || label != null,
            'AppFAB extended exige un label');

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final radius = extended ? AppBorderRadius.pill : 999.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPress == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPress!();
            },
      child: Container(
        height: 56,
        width: extended ? null : 56,
        padding: extended
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.lg)
            : null,
        decoration: BoxDecoration(
          color: theme.colors.primary,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: theme.colors.primary.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colors.primaryForeground, size: 22),
            if (extended) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                label!,
                style: theme.typography.lg.copyWith(
                  color: theme.colors.primaryForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`** → 0 errors. Si `withValues` n'est pas dispo (Flutter < 3.27), fallback `withOpacity(0.18)`.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_fab.dart
git commit -m "feat(widgets): add AppFAB (regular + extended variants)"
```

---

### Task 21: `AppSkeleton` (shimmer placeholders pure flutter)

**Files:**
- Create: `lib/presentation/widgets/app_skeleton.dart`

- [ ] **Step 1: Créer le widget**

```dart
// lib/presentation/widgets/app_skeleton.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../core/motion.dart';

/// Bloc placeholder shimmer pure-Flutter (pas de package shimmer externe).
/// Utilise un `AnimatedBuilder` qui interpole entre deux opacités sur la
/// couleur `surfaceMuted` (proxy : `theme.colors.muted`).
class AppSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const AppSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = AppBorderRadius.sm,
  });

  /// Helper : skeleton pour un titre (24dp height).
  factory AppSkeleton.title({double? width}) =>
      AppSkeleton(height: 24, width: width, radius: AppBorderRadius.sm);

  /// Helper : skeleton pour un body line (16dp height).
  factory AppSkeleton.line({double? width}) =>
      AppSkeleton(height: 16, width: width, radius: AppBorderRadius.sm);

  /// Helper : skeleton pour un tile (72dp height).
  factory AppSkeleton.tile() =>
      const AppSkeleton(height: 72, radius: AppBorderRadius.md);

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(
              theme.colors.muted,
              theme.colors.border,
              t,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`** → 0 errors. (`AppMotion` est importé pour disponibilité future ; si lint warning unused import, drop la ligne `import '../../core/motion.dart';`.)

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_skeleton.dart
git commit -m "feat(widgets): add AppSkeleton (shimmer placeholder pure flutter)"
```

---

### Task 22: `AppErrorState`

**Files:**
- Create: `lib/presentation/widgets/app_error_state.dart`

- [ ] **Step 1: Créer le widget**

```dart
// lib/presentation/widgets/app_error_state.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import 'app_primary_button.dart';

/// État d'erreur standardisé. Icône triangleAlert destructive, message
/// clair, bouton « Réessayer » primary, bouton « Détails » outline qui
/// toggle l'affichage de `details` (typiquement le stack trace).
class AppErrorState extends StatefulWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final String retryLabel;
  final String detailsLabel;

  const AppErrorState({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.retryLabel = 'Réessayer',
    this.detailsLabel = 'Détails',
  });

  @override
  State<AppErrorState> createState() => _AppErrorStateState();
}

class _AppErrorStateState extends State<AppErrorState> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.huge,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(FIcons.triangleAlert,
              size: AppSizes.heroIconCircle, color: theme.colors.destructive),
          const SizedBox(height: AppSpacing.lg),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: theme.typography.xl2.copyWith(color: theme.colors.foreground),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              label: widget.retryLabel,
              onPress: widget.onRetry,
            ),
          ],
          if (widget.details != null) ...[
            const SizedBox(height: AppSpacing.sm),
            FButton(
              variant: FButtonVariant.outline,
              size: FButtonSizeVariant.sm,
              onPress: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Masquer ${widget.detailsLabel.toLowerCase()}' : widget.detailsLabel),
            ),
            if (_expanded) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colors.muted,
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Text(
                  widget.details!,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_error_state.dart
git commit -m "feat(widgets): add AppErrorState (icon + retry + collapsible details)"
```

---

### Task 23: `AppCommandPalette` (full-screen sheet)

**Files:**
- Create: `lib/presentation/widgets/app_command_palette.dart`

> **Note descope** : si l'implémentation devient trop lourde au moment de l'application aux écrans (Plan 2), ce composant peut être dropped. Le widget construit ici est minimal — il scope clients/tournées/prestations/paramètres via les providers existants. Si le caller ne le branche pas, il reste inerte.

- [ ] **Step 1: Créer le widget — surface uniquement (pas de wiring providers ici)**

```dart
// lib/presentation/widgets/app_command_palette.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// Item présenté dans la palette : un label, une icône, une action onSelect.
class AppCommandItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onSelect;

  const AppCommandItem({
    required this.icon,
    required this.label,
    required this.onSelect,
    this.subtitle,
  });
}

/// Sheet full-screen de recherche universelle. Le caller fournit les items
/// (typiquement construits depuis des providers dans Plan 2). Filtrage
/// case-insensitive substring sur `label` + `subtitle`.
class AppCommandPalette extends StatefulWidget {
  final List<AppCommandItem> items;
  final String hint;

  const AppCommandPalette({
    super.key,
    required this.items,
    this.hint = 'Recherche…',
  });

  /// Helper d'ouverture en bottom sheet plein-écran.
  static Future<void> show(BuildContext context,
      {required List<AppCommandItem> items, String hint = 'Recherche…'}) {
    return showFSheet<void>(
      context: context,
      side: FLayout.btt,
      builder: (ctx) => Padding(
        padding: MediaQuery.viewInsetsOf(ctx),
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.9,
          child: AppCommandPalette(items: items, hint: hint),
        ),
      ),
    );
  }

  @override
  State<AppCommandPalette> createState() => _AppCommandPaletteState();
}

class _AppCommandPaletteState extends State<AppCommandPalette> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.items
        : widget.items.where((i) {
            final hay = '${i.label} ${i.subtitle ?? ''}'.toLowerCase();
            return hay.contains(q);
          }).toList();

    return Container(
      color: theme.colors.background,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          FTextField(
            control: FTextFieldControl.managed(
              controller: _controller,
              onChange: (v) => setState(() => _query = v.text),
            ),
            hint: widget.hint,
            prefix: const Icon(FIcons.search),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Aucun résultat',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xxs),
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.of(context).pop();
                          item.onSelect();
                        },
                        child: Container(
                          padding: AppSizes.listTilePadding,
                          decoration: BoxDecoration(
                            color: theme.colors.card,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.md),
                            border: Border.all(
                              color: theme.colors.border,
                              width: AppSizes.hairlineBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(item.icon,
                                  size: 18, color: theme.colors.foreground),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(item.label,
                                        style: theme.typography.lg.copyWith(
                                          color: theme.colors.foreground,
                                        )),
                                    if (item.subtitle != null) ...[
                                      const SizedBox(height: AppSpacing.xxxs),
                                      Text(
                                        item.subtitle!,
                                        style: theme.typography.sm.copyWith(
                                          color: theme.colors.mutedForeground,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(FIcons.chevronRight,
                                  size: 16,
                                  color: theme.colors.mutedForeground),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`** → 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_command_palette.dart
git commit -m "feat(widgets): add AppCommandPalette (full-screen sheet, caller-fed items)"
```

---

## Phase E — Smoke validation finale

### Task 24: Smoke build et test full

**Files:**
- (aucun)

- [ ] **Step 1: `flutter analyze` complet**

```
flutter analyze
```

Expected: 0 errors. Warnings deprecated tolérés.

- [ ] **Step 2: Lancer toute la suite de tests**

```
flutter test
```

Expected: tous tests verts (les 186 existants + les nouveaux ajoutés ici : design_tokens, motion, color_scheme, typography, animal_icons, app_diff_row).

- [ ] **Step 3: Build APK debug**

```
flutter build apk --debug --target-platform android-arm64
```

Expected: build OK.

- [ ] **Step 4: Smoke test manuel**

Lancer l'app sur un device/émulateur. Vérifier :
- [ ] L'app se lance sans crash.
- [ ] La palette a basculé : fond ivoire `#FAF8F3`, texte vert quasi-noir, boutons primary vert forêt.
- [ ] Aucun headline en serif (Fraunces droppé du theme).
- [ ] Les écrans existants (clients list, client detail, tour list, tour detail, map, settings) **se rendent toujours sans erreur** — la disposition reste celle d'avant (les nouveaux composants ne sont pas encore appliqués).
- [ ] Les `AnimalCountsBadges` rendent les SVG d'animaux si le widget les utilise (Task 11).

- [ ] **Step 5: Pas de commit ici** — c'est un smoke test final, sans modif code.

---

## Self-review post-écriture

Spec coverage check :

- §1.1 Palette light + dark → Task 3 ✓
- §1.2 Typographie Inter unique → Task 4 ✓
- §1.3 Spacing/radius/sizes → Task 1 ✓
- §1.4 Motion → Task 2 ✓
- §1.5 Icon set custom (4 silhouettes animales + alias FIcons) → Task 6 ✓
- §1.6 Composants signature :
  - Conservés/redessinés : `AppPrimaryButton` (T7), `AppSectionCard` (T8), `AppEmptyState` (T9), `AppBadge` (T10), `AnimalCountsBadges` (T11) ✓
  - Déprécié : `AppHeroCard` → laissé en place pour le moment, drop dans Plan 3 cleanup ✓ (noté en out-of-scope)
  - Nouveaux : `AppKpiCard` (T13), `AppKpiRow` (T14), `AppListTile` (T15), `AppHeader` (T16), `AppActionBar` (T17), `AppCommandPalette` (T23), `AppTimelineRow` (T18), `AppStat` (T12), `AppDiffRow` (T19), `AppFAB` (T20), `AppSkeleton` (T21), `AppErrorState` (T22) ✓ tous présents
- §2-§7 (patterns globaux, écrans, phasing, risques, success criteria) → out-of-scope de ce plan, traités par Plan 2 et 3 ✓

Type consistency :
- `AppKpiCell` (T14) défini puis consommé via `AppKpiRow(cells: [...])` ✓
- `AppDiffRow.computeDelta` (T19) — `DiffStatus` enum + `DiffResult` consommés cohérents ✓
- `AppCommandItem` (T23) défini puis consommé dans `AppCommandPalette.show` ✓
- `iconAssetForSpeciesKey` (T6) → consommé dans T11 (AnimalCountsBadges) ✓

Placeholder scan :
- Aucun `TBD`, `TODO`, `implement later`. Les seules « notes » sont les remarques de pragmatisme (descope possible pour CommandPalette ; Fraunces drop différé), explicites et bien cadrées.

Notes :
- Le composant `AppHeroCard` n'est pas modifié ni supprimé ici — il continue de servir les écrans existants jusqu'à ce que Plan 2 redesigne ces écrans. La suppression définitive est dans Plan 3 cleanup.
- Les patterns `AppHeader`/`AppActionBar` sont **construits** ici mais **pas appliqués** aux écrans — l'application est dans Plan 2 (qui touchera les fichiers d'écrans).
- Le motion token `AppMotion` est créé mais peu consommé dans Plan 1 (uniquement dans `AppSkeleton` indirectement via duration constante 1200ms qui n'est pas un token). Plan 2 le consommera intensément (sheets, dialogs, page transitions).
