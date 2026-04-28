# UI Polish v2 — Pastoral Chic Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-skin the Coupe-Laine app with a warm sage + terracotta palette, Fraunces serif on titles/numbers, generous spacing, custom signature widgets, and SVG illustrations — without touching business logic or navigation.

**Architecture:** Five sequential sub-phases. P1 lays the design tokens and theme. P2 builds 6 reusable signature widgets that wrap Forui primitives with the new spacing/typography. P3 adds 4 simple SVG illustrations bundled in `assets/`. P4-P5 refactor the screens to consume the tokens, theme, and components.

**Tech Stack:** Flutter (existing 3.41.7), Forui 0.21.3, Riverpod 3.3, drift 2.32, go_router 17, flutter_svg (added in P1). All preexisting screens are already on Forui scaffolding.

**Spec:** [`../specs/2026-04-28-ui-polish-v2-pastoral-chic-design.md`](../specs/2026-04-28-ui-polish-v2-pastoral-chic-design.md)

**Note on TDD:** This is a purely visual refactor. We do **not** follow strict red-green TDD per task. Each task ends with `flutter analyze` clean + `flutter test` (54 existing tests must stay green) + a manual smoke check on device when relevant. New automated tests are NOT added.

---

## File structure

```
assets/
├── fonts/                                       (P1) NEW
│   ├── Fraunces_9pt-SemiBold.ttf
│   ├── Fraunces_9pt-Bold.ttf
│   └── Fraunces_9pt-ExtraBold.ttf
└── illustrations/                               (P3) NEW
    ├── welcome.svg
    ├── empty-clients.svg
    ├── empty-tours.svg
    └── tour-completed.svg

lib/
├── app.dart                                     (P1) MODIFY
├── core/
│   ├── design_tokens.dart                       (P1) NEW
│   └── theme/                                   (P1) NEW
│       ├── app_color_scheme.dart
│       ├── app_typography.dart
│       └── app_themes.dart
├── presentation/
│   ├── widgets/                                 (P2) NEW (6 files)
│   │   ├── app_badge.dart
│   │   ├── app_empty_state.dart
│   │   ├── app_hero_card.dart
│   │   ├── app_list_tile.dart
│   │   ├── app_primary_button.dart
│   │   └── app_section_card.dart
│   ├── onboarding/onboarding_screen.dart        (P4) MODIFY
│   ├── settings/settings_screen.dart            (P4) MODIFY
│   ├── tours/
│   │   ├── tours_list_screen.dart               (P4) MODIFY
│   │   ├── tour_draft_screen.dart               (P5) MODIFY
│   │   └── tour_detail_screen.dart              (P5) MODIFY
│   ├── clients/
│   │   ├── clients_list_screen.dart             (P4) MODIFY
│   │   ├── client_form_screen.dart              (P5) MODIFY
│   │   └── client_detail_screen.dart            (P5) MODIFY
│   └── proximity/
│       ├── proximity_screen.dart                (P5) MODIFY
│       ├── proximity_list_view.dart             (P5) MODIFY
│       └── proximity_map_view.dart              (P5) MODIFY
pubspec.yaml                                     (P1, P3) MODIFY
```

---

# Phase 1 — Tokens, theme, and dependencies

**Goal at end of phase:** App rebuilds with the new sage + terracotta palette + Fraunces typography active across every existing screen, with no other change yet. `flutter_svg` is installed and ready for P2 to consume.

## Task 1.1: Add `flutter_svg` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dependency**

```bash
cd /c/Users/rapha/Documents/Development/coupe-laine
flutter pub add flutter_svg
```

Expected: `flutter_svg: ^2.0.10+1` added to `dependencies` block.

- [ ] **Step 2: Verify**

```bash
flutter pub get
flutter analyze lib/
flutter test
```

Expected: 0 new errors, 54 tests pass.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "$(cat <<'EOF'
deps: add flutter_svg for upcoming illustrations

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 1.2: Bundle Fraunces fonts

**Files:**
- Create: `assets/fonts/Fraunces_9pt-SemiBold.ttf`
- Create: `assets/fonts/Fraunces_9pt-Bold.ttf`
- Create: `assets/fonts/Fraunces_9pt-ExtraBold.ttf`
- Modify: `pubspec.yaml`

- [ ] **Step 1: Download the three static Fraunces TTFs**

Fraunces is OFL-licensed (commercial use OK). Download the static instances from the official Google Fonts repo:

```bash
mkdir -p assets/fonts
curl -L -o assets/fonts/Fraunces_9pt-SemiBold.ttf \
  "https://github.com/google/fonts/raw/main/ofl/fraunces/static/Fraunces_9pt-SemiBold.ttf"
curl -L -o assets/fonts/Fraunces_9pt-Bold.ttf \
  "https://github.com/google/fonts/raw/main/ofl/fraunces/static/Fraunces_9pt-Bold.ttf"
curl -L -o assets/fonts/Fraunces_9pt-ExtraBold.ttf \
  "https://github.com/google/fonts/raw/main/ofl/fraunces/static/Fraunces_9pt-ExtraBold.ttf"
```

If any of those 404, the static directory might be elsewhere — fall back to the variable font and tell the user, OR download from Google Fonts directly:

```bash
# Fallback: download the Google Fonts archive zip and extract
curl -L -o /tmp/fraunces.zip "https://fonts.google.com/download?family=Fraunces"
# then unzip and copy the static files
```

- [ ] **Step 2: Verify the three files exist and are non-trivial**

```bash
ls -la assets/fonts/
```

Expected: each file ~100-200 KB. If any file is < 1 KB, the download failed (likely a 404 HTML page) — retry from the fallback URL.

- [ ] **Step 3: Register the fonts in `pubspec.yaml`**

In `pubspec.yaml`, under the `flutter:` section (after `assets:`), add:

```yaml
  fonts:
    - family: Fraunces
      fonts:
        - asset: assets/fonts/Fraunces_9pt-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Fraunces_9pt-Bold.ttf
          weight: 700
        - asset: assets/fonts/Fraunces_9pt-ExtraBold.ttf
          weight: 800
```

- [ ] **Step 4: Verify**

```bash
flutter pub get
flutter analyze lib/
```

Expected: 0 new errors. Flutter recognises the font family.

- [ ] **Step 5: Commit**

```bash
git add assets/fonts/ pubspec.yaml
git commit -m "$(cat <<'EOF'
chore(assets): bundle Fraunces fonts (semi-bold, bold, extra-bold)

OFL-licensed static instances. No google_fonts package — usable offline.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 1.3: Define design tokens

**Files:**
- Create: `lib/core/design_tokens.dart`

- [ ] **Step 1: Write the tokens file**

```dart
// lib/core/design_tokens.dart
import 'package:flutter/widgets.dart';

/// Spacing scale in logical pixels (multiples of 4).
abstract final class AppSpacing {
  AppSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border radii used across components.
abstract final class AppBorderRadius {
  AppBorderRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 24;
  static const double pill = 999;
}

/// Common animation durations.
abstract final class AppDuration {
  AppDuration._();
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 240);
}

/// Concrete element sizes that recur across screens.
abstract final class AppSizes {
  AppSizes._();
  static const double primaryButtonHeight = 56;
  static const double secondaryButtonHeight = 48;
  static const double iconButtonSize = 44;
  static const double textFieldMinHeight = 56;
  static const double sectionIconCircle = 32;
  static const double heroIconCircle = 72;

  /// Standard outer screen padding.
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(20, 24, 20, 40);

  /// Hero card padding (more generous vertically).
  static const EdgeInsets heroCardPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 32);

  /// Standard FCard padding (used by AppSectionCard).
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  /// AppListTile internal padding.
  static const EdgeInsets listTilePadding = EdgeInsets.all(16);
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/core/design_tokens.dart
```

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/design_tokens.dart
git commit -m "$(cat <<'EOF'
feat(design): expose spacing, radii, sizes as design tokens

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 1.4: Define the custom color scheme

**Files:**
- Create: `lib/core/theme/app_color_scheme.dart`

- [ ] **Step 1: Discover the FColorScheme constructor in Forui 0.21.3**

```bash
cat "/c/Users/rapha/AppData/Local/Pub/Cache/hosted/pub.dev/forui-0.21.3/lib/src/theme/color_scheme.dart" | head -120
```

Note the actual fields. Forui's `FColorScheme` typically takes: `brightness`, `background`, `foreground`, `primary`, `primaryForeground`, `secondary`, `secondaryForeground`, `muted`, `mutedForeground`, `destructive`, `destructiveForeground`, `error`, `errorForeground`, `border`, `barrier`. Verify before writing the file.

> Forui doesn't always have a separate `accent` token — it usually overloads `secondary` for that role. Use `secondary` for terracotta in the implementation below. If the actual field set differs, adapt.

- [ ] **Step 2: Write the color scheme**

```dart
// lib/core/theme/app_color_scheme.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Sage + terracotta palette for light mode.
///
/// Sage (#4A6B52) = primary CTAs, active states.
/// Terracotta (#C77B5C) = accents (used as `secondary` in Forui's vocabulary).
final FColorScheme appLightColorScheme = FColorScheme(
  brightness: Brightness.light,
  background: const Color(0xFFF8F4ED),
  foreground: const Color(0xFF1F1B16),
  primary: const Color(0xFF4A6B52),
  primaryForeground: const Color(0xFFFFFFFF),
  secondary: const Color(0xFFC77B5C),
  secondaryForeground: const Color(0xFFFFFFFF),
  muted: const Color(0xFFEFEAE0),
  mutedForeground: const Color(0xFF6B6359),
  destructive: const Color(0xFFB33A3A),
  destructiveForeground: const Color(0xFFFFFFFF),
  error: const Color(0xFFB33A3A),
  errorForeground: const Color(0xFFFFFFFF),
  border: const Color(0xFFE8E1D4),
  barrier: const Color(0x801F1B16),
);

final FColorScheme appDarkColorScheme = FColorScheme(
  brightness: Brightness.dark,
  background: const Color(0xFF1F1B16),
  foreground: const Color(0xFFF5F0E8),
  primary: const Color(0xFF7C9C7E),
  primaryForeground: const Color(0xFF1F1B16),
  secondary: const Color(0xFFE0926D),
  secondaryForeground: const Color(0xFF1F1B16),
  muted: const Color(0xFF2B2620),
  mutedForeground: const Color(0xFFA89F92),
  destructive: const Color(0xFFD45A5A),
  destructiveForeground: const Color(0xFF1F1B16),
  error: const Color(0xFFD45A5A),
  errorForeground: const Color(0xFF1F1B16),
  border: const Color(0xFF3A332A),
  barrier: const Color(0x80F5F0E8),
);
```

> If `FColorScheme` requires different field names (e.g. uses `accent` instead of `secondary`, or requires extra fields like `card`/`popover`), adapt the implementation. Document the difference in your task report.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/core/theme/app_color_scheme.dart
```

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme/app_color_scheme.dart
git commit -m "$(cat <<'EOF'
feat(theme): sage + terracotta FColorScheme (light + dark)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 1.5: Build the FTypography with Fraunces

**Files:**
- Create: `lib/core/theme/app_typography.dart`

- [ ] **Step 1: Discover the FTypography constructor in Forui 0.21.3**

```bash
cat "/c/Users/rapha/AppData/Local/Pub/Cache/hosted/pub.dev/forui-0.21.3/lib/src/theme/typography.dart" | head -150
```

Note the named text-style fields (likely `xs`, `sm`, `md`, `lg`, `xl`, `xl2`, `xl3`, `xl4`). Each is typically a `TextStyle`. Use `.copyWith(fontFamily: 'Fraunces', fontWeight: ...)` on the larger sizes to swap in Fraunces.

- [ ] **Step 2: Build the typography file**

```dart
// lib/core/theme/app_typography.dart
import 'package:flutter/painting.dart';
import 'package:forui/forui.dart';

/// Build a typography that swaps Fraunces in for headline-tier sizes.
///
/// Display + xl3 + xl2 use Fraunces. Smaller tiers stay on the default
/// sans (Inter, inherited from Forui's defaults).
FTypography buildAppTypography(FTypography base) {
  // The available size tokens in Forui 0.21.3 may include `xs`, `sm`, `md`,
  // `lg`, `xl`, `xl2`, `xl3`, `xl4`. We override only the headline tiers.
  return base.copyWith(
    xl4: base.xl4.copyWith(
      fontFamily: 'Fraunces',
      fontWeight: FontWeight.w800,
      fontSize: 40,
      height: 1.1,
      letterSpacing: -0.5,
    ),
    xl3: base.xl3.copyWith(
      fontFamily: 'Fraunces',
      fontWeight: FontWeight.w700,
      fontSize: 28,
      height: 1.15,
      letterSpacing: -0.4,
    ),
    xl2: base.xl2.copyWith(
      fontFamily: 'Fraunces',
      fontWeight: FontWeight.w600,
      fontSize: 22,
      height: 1.2,
      letterSpacing: -0.2,
    ),
    // lg, md, sm, xs stay on the inherited (Inter) family.
  );
}
```

> If `FTypography` field names differ (e.g. `headline`, `title` instead of `xl4`, `xl3`), adapt accordingly. Read the source if unsure.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/core/theme/app_typography.dart
```

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme/app_typography.dart
git commit -m "$(cat <<'EOF'
feat(theme): Fraunces-augmented FTypography

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 1.6: Compose `appLightTheme` and `appDarkTheme`

**Files:**
- Create: `lib/core/theme/app_themes.dart`

- [ ] **Step 1: Write the theme exports**

```dart
// lib/core/theme/app_themes.dart
import 'package:forui/forui.dart';

import 'app_color_scheme.dart';
import 'app_typography.dart';

/// Build the app's themes by starting from Forui's blue.touch baseline,
/// then replacing the color scheme and the headline typography.
final FThemeData appLightTheme = () {
  final base = FThemes.blue.light.touch;
  return base.copyWith(
    colorScheme: appLightColorScheme,
    typography: buildAppTypography(base.typography),
  );
}();

final FThemeData appDarkTheme = () {
  final base = FThemes.blue.dark.touch;
  return base.copyWith(
    colorScheme: appDarkColorScheme,
    typography: buildAppTypography(base.typography),
  );
}();
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/core/theme/app_themes.dart
```

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_themes.dart
git commit -m "$(cat <<'EOF'
feat(theme): compose appLightTheme + appDarkTheme

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 1.7: Wire the new themes in `lib/app.dart`

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Read the current `lib/app.dart`** to see the existing wiring.

```bash
cat lib/app.dart
```

It currently uses `FThemes.blue.light.touch` and `.dark.touch`. Replace those with our `appLightTheme` and `appDarkTheme`.

- [ ] **Step 2: Modify `lib/app.dart`**

Replace the existing imports of Forui themes (none specific — `forui.dart` covers it) and add:

```dart
import 'core/theme/app_themes.dart';
```

Replace any reference to `FThemes.blue.light.touch` with `appLightTheme`, and `FThemes.blue.dark.touch` with `appDarkTheme`. Specifically the `theme:`, `darkTheme:`, and the `FTheme(data: ...)` inside `builder:`.

The expected resulting structure of `app.dart` is:

```dart
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'core/theme/app_themes.dart';
import 'state/providers.dart';

class CoupeLaineApp extends ConsumerWidget {
  const CoupeLaineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final modeAsync = ref.watch(themeModeProvider);
    final mode = modeAsync.value ?? ThemeMode.system;

    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...FLocalizations.localizationsDelegates,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('fr'),
      theme: appLightTheme.toApproximateMaterialTheme(),
      darkTheme: appDarkTheme.toApproximateMaterialTheme(),
      themeMode: mode,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final fTheme = brightness == Brightness.dark ? appDarkTheme : appLightTheme;
        return FTheme(
          data: fTheme,
          child: FToaster(child: child ?? const SizedBox.shrink()),
        );
      },
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors, 54 tests pass, debug APK builds.

- [ ] **Step 4: Manual smoke (optional but recommended)**

If a device or emulator is available, run `flutter run -d android` and confirm:
- Background is ivory `#F8F4ED` (light) or warm anthracite `#1F1B16` (dark, if you toggle the system theme).
- Section titles render in Fraunces (visible italic-ish serif curves on capital letters).
- Primary buttons are sage green.

Note any visual issues but don't fix them yet — P4-P5 do the per-screen polish.

- [ ] **Step 5: Commit**

```bash
git add lib/app.dart
git commit -m "$(cat <<'EOF'
feat(theme): wire pastoral chic themes into MaterialApp.router

R0 of the redesign rounds out: blue palette is now sage/terracotta,
Fraunces serif is in for headline tiers across both light and dark.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# Phase 2 — Signature widgets

**Goal at end of phase:** Six new widgets in `lib/presentation/widgets/`, all compiling cleanly. Existing screens continue to work (they don't use the new widgets yet — that's P4-P5).

## Task 2.1: `AppPrimaryButton`

**Files:**
- Create: `lib/presentation/widgets/app_primary_button.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/presentation/widgets/app_primary_button.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// A primary CTA button with consistent height (56), generous horizontal
/// padding, and Inter 600 weight. Optionally loading — shows a small
/// circular progress in place of the label and disables the press.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? prefixIcon;
  final VoidCallback? onPress;
  final bool loading;
  final FButtonVariant variant;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPress,
    this.prefixIcon,
    this.loading = false,
    this.variant = FButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.primaryButtonHeight,
      child: FButton(
        variant: variant,
        prefix: prefixIcon == null ? null : Icon(prefixIcon),
        onPress: loading ? null : onPress,
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: FCircularProgress(size: FCircularProgressSizeVariant.sm),
              )
            : Text(label),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/presentation/widgets/app_primary_button.dart
```

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_primary_button.dart
git commit -m "$(cat <<'EOF'
feat(widget): AppPrimaryButton — 56px primary CTA wrapper

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2.2: `AppBadge`

**Files:**
- Create: `lib/presentation/widgets/app_badge.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/presentation/widgets/app_badge.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// Fully-rounded pill badge with optional 14px prefix icon.
///
/// Variants are exposed as named constructors that bind the right colors,
/// labels, and icons for the recurring states in the app.
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

  /// "En attente" — terracotta (secondary).
  factory AppBadge.waiting(BuildContext context, {String label = 'En attente'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.clock,
      background: colors.secondary,
      foreground: colors.secondaryForeground,
    );
  }

  /// "En retard" — destructive.
  factory AppBadge.overdue(BuildContext context, {String label = 'En retard'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.triangleAlert,
      background: colors.destructive,
      foreground: colors.destructiveForeground,
    );
  }

  /// "Distances à recalculer" — muted.
  factory AppBadge.recompute(BuildContext context,
      {String label = 'Distances'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.refreshCw,
      background: colors.muted,
      foreground: colors.mutedForeground,
    );
  }

  /// "Réalisée" — primary (sage).
  factory AppBadge.completed(BuildContext context,
      {String label = 'Réalisée'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.check,
      background: colors.primary,
      foreground: colors.primaryForeground,
    );
  }

  /// "Planifiée" — secondary (terracotta).
  factory AppBadge.planned(BuildContext context, {String label = 'Planifiée'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.calendar,
      background: colors.secondary,
      foreground: colors.secondaryForeground,
    );
  }

  /// "Journée longue" — warm muted (use secondary at 80% via opacity overlay,
  /// but here we just use muted for simplicity).
  factory AppBadge.longDay(BuildContext context,
      {String label = 'Journée longue'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.sunset,
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

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/presentation/widgets/app_badge.dart
```

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_badge.dart
git commit -m "$(cat <<'EOF'
feat(widget): AppBadge — pill badge with 6 named-constructor variants

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2.3: `AppSectionCard`

**Files:**
- Create: `lib/presentation/widgets/app_section_card.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/presentation/widgets/app_section_card.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// A card with a colored 32×32 circle prefix holding an icon, plus a title.
///
/// Used everywhere a screen has a logical section (Identité, Adresse, Tonte,
/// Apparence, etc.).
class AppSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  /// Override the icon circle background. Defaults to `colors.secondary`
  /// (terracotta).
  final Color? iconBackground;

  const AppSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bg = iconBackground ?? theme.colors.secondary;
    final fg = theme.colors.secondaryForeground;

    return FCard.raw(
      child: Padding(
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
                  child: Icon(icon, color: fg, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.typography.xl2.copyWith(
                      color: theme.colors.foreground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/presentation/widgets/app_section_card.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_section_card.dart
git commit -m "$(cat <<'EOF'
feat(widget): AppSectionCard — section with terracotta icon circle

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2.4: `AppListTile`

**Files:**
- Create: `lib/presentation/widgets/app_list_tile.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/presentation/widgets/app_list_tile.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// A standalone tile with card-like styling — internal padding 16/16,
/// 12px border radius, card-color background. Used in lists with a 12px
/// gap between consecutive tiles so each tile reads as its own card.
class AppListTile extends StatelessWidget {
  final Widget? prefix;
  final String title;
  final String? subtitle;
  final Widget? suffix;
  final VoidCallback? onPress;

  const AppListTile({
    super.key,
    required this.title,
    this.prefix,
    this.subtitle,
    this.suffix,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPress,
      child: Container(
        padding: AppSizes.listTilePadding,
        decoration: BoxDecoration(
          color: theme.colors.background == const Color(0xFFF8F4ED)
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF2B2620),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: theme.colors.border),
        ),
        child: Row(
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
                  Text(
                    title,
                    style: theme.typography.md.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: AppSpacing.sm),
              suffix!,
            ],
          ],
        ),
      ),
    );
  }
}
```

> The `card` color isn't directly exposed on `FColorScheme` — we approximate by detecting the background and picking white or warm-anthracite. If Forui exposes a `card` field on `FColorScheme`, prefer that. Read the source to confirm.

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/presentation/widgets/app_list_tile.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_list_tile.dart
git commit -m "$(cat <<'EOF'
feat(widget): AppListTile — card-like list row with 12 gap

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2.5: `AppHeroCard`

**Files:**
- Create: `lib/presentation/widgets/app_hero_card.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/presentation/widgets/app_hero_card.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// The featured card. Big number + label + optional subtitle and badge,
/// on an asymmetric-corner card with a soft warm background gradient.
class AppHeroCard extends StatelessWidget {
  final Widget? badge;
  final String bigNumber;
  final String label;
  final String? subtitle;

  const AppHeroCard({
    super.key,
    required this.bigNumber,
    required this.label,
    this.badge,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.colors.brightness == Brightness.dark;

    return Container(
      padding: AppSizes.heroCardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF2B2620),
                  const Color(0xFF1F1B16),
                ]
              : [
                  const Color(0xFFFFFFFF),
                  const Color(0xFFF1EBDF),
                ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.lg),
          topRight: Radius.circular(AppBorderRadius.sm),
          bottomLeft: Radius.circular(AppBorderRadius.sm),
          bottomRight: Radius.circular(AppBorderRadius.sm),
        ),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null) ...[
            badge!,
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                bigNumber,
                style: theme.typography.xl4.copyWith(
                  color: theme.colors.foreground,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.typography.lg.copyWith(
                  color: theme.colors.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/presentation/widgets/app_hero_card.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_hero_card.dart
git commit -m "$(cat <<'EOF'
feat(widget): AppHeroCard — asymmetric-radius hero card with gradient

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2.6: `AppEmptyState`

**Files:**
- Create: `lib/presentation/widgets/app_empty_state.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/presentation/widgets/app_empty_state.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// Illustrated empty-state for lists. Renders a centered SVG, then a title,
/// then a body, then an optional action button.
class AppEmptyState extends StatelessWidget {
  final String illustrationAsset;
  final String title;
  final String body;
  final Widget? action;
  final double illustrationHeight;

  const AppEmptyState({
    super.key,
    required this.illustrationAsset,
    required this.title,
    required this.body,
    this.action,
    this.illustrationHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl + AppSpacing.md, // 64
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            illustrationAsset,
            height: illustrationHeight,
            fit: BoxFit.contain,
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
            style: theme.typography.md.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/presentation/widgets/app_empty_state.dart
```

Expected: 0 errors. The SVG file doesn't have to exist yet — `SvgPicture.asset` is just a constructor, the asset is loaded only when rendered (and we won't render any AppEmptyState until P4).

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_empty_state.dart
git commit -m "$(cat <<'EOF'
feat(widget): AppEmptyState — illustration + title + body + optional CTA

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2.7: Phase 2 sweep

- [ ] **Step 1: Verify everything**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors, 54 tests pass, APK builds.

No commit needed — this is a checkpoint.

---

# Phase 3 — SVG illustrations

**Goal at end of phase:** Four SVG illustrations bundled in `assets/illustrations/` and wired in `pubspec.yaml`. AppEmptyState rendering them works in a smoke screen.

The illustrations below are deliberately simple geometric shapes — circles, abstract figures, sage and terracotta accents on ivory. They're functional placeholders aligned with the palette. The user can later replace them with bespoke unDraw downloads if they want richer art.

## Task 3.1: Create `welcome.svg`

**Files:**
- Create: `assets/illustrations/welcome.svg`

- [ ] **Step 1: Create the directory and file**

```bash
mkdir -p assets/illustrations
```

Write `assets/illustrations/welcome.svg`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200" fill="none">
  <!-- Background warm circle -->
  <circle cx="160" cy="100" r="78" fill="#4A6B52" opacity="0.12"/>
  <!-- Inner sage circle -->
  <circle cx="160" cy="100" r="54" fill="#4A6B52"/>
  <!-- Terracotta arc behind -->
  <path d="M 60 130 Q 160 60 260 130" stroke="#C77B5C" stroke-width="6" stroke-linecap="round" fill="none" opacity="0.6"/>
  <!-- Scissors silhouette in white -->
  <g transform="translate(135 75)" stroke="#FFFFFF" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round" fill="none">
    <circle cx="6" cy="6" r="3"/>
    <circle cx="6" cy="44" r="3"/>
    <line x1="20" y1="4" x2="44" y2="44"/>
    <line x1="14" y1="14" x2="44" y2="44"/>
    <line x1="20" y1="46" x2="44" y2="6"/>
  </g>
  <!-- Two small sage dots like sheep -->
  <circle cx="68" cy="148" r="9" fill="#4A6B52" opacity="0.5"/>
  <circle cx="252" cy="152" r="7" fill="#C77B5C" opacity="0.5"/>
</svg>
```

- [ ] **Step 2: Verify the file is well-formed**

```bash
head -c 200 assets/illustrations/welcome.svg
```

Expected: starts with `<?xml version="1.0"`.

- [ ] **Step 3: Commit**

```bash
git add assets/illustrations/welcome.svg
git commit -m "$(cat <<'EOF'
chore(assets): add welcome.svg placeholder illustration

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3.2: Create `empty-clients.svg`

**Files:**
- Create: `assets/illustrations/empty-clients.svg`

- [ ] **Step 1: Write the file**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 180" width="320" height="180" fill="none">
  <!-- Background pasture line -->
  <line x1="20" y1="135" x2="300" y2="135" stroke="#E8E1D4" stroke-width="2" stroke-dasharray="4 6"/>
  <!-- Three sheep-as-circles in front -->
  <g>
    <ellipse cx="100" cy="120" rx="22" ry="16" fill="#FFFFFF" stroke="#4A6B52" stroke-width="2"/>
    <circle cx="84" cy="116" r="6" fill="#1F1B16"/>
    <line x1="93" y1="135" x2="93" y2="142" stroke="#1F1B16" stroke-width="1.5" stroke-linecap="round"/>
    <line x1="107" y1="135" x2="107" y2="142" stroke="#1F1B16" stroke-width="1.5" stroke-linecap="round"/>
  </g>
  <g>
    <ellipse cx="160" cy="115" rx="26" ry="18" fill="#FFFFFF" stroke="#4A6B52" stroke-width="2"/>
    <circle cx="140" cy="111" r="7" fill="#1F1B16"/>
    <line x1="151" y1="132" x2="151" y2="142" stroke="#1F1B16" stroke-width="1.5" stroke-linecap="round"/>
    <line x1="169" y1="132" x2="169" y2="142" stroke="#1F1B16" stroke-width="1.5" stroke-linecap="round"/>
  </g>
  <g>
    <ellipse cx="220" cy="120" rx="22" ry="16" fill="#FFFFFF" stroke="#4A6B52" stroke-width="2"/>
    <circle cx="204" cy="116" r="6" fill="#1F1B16"/>
    <line x1="213" y1="135" x2="213" y2="142" stroke="#1F1B16" stroke-width="1.5" stroke-linecap="round"/>
    <line x1="227" y1="135" x2="227" y2="142" stroke="#1F1B16" stroke-width="1.5" stroke-linecap="round"/>
  </g>
  <!-- Terracotta sun -->
  <circle cx="260" cy="50" r="18" fill="#C77B5C" opacity="0.85"/>
  <!-- Sage background hill -->
  <path d="M 0 135 Q 80 95 160 110 Q 240 125 320 100 L 320 180 L 0 180 Z" fill="#4A6B52" opacity="0.12"/>
</svg>
```

- [ ] **Step 2: Commit**

```bash
git add assets/illustrations/empty-clients.svg
git commit -m "$(cat <<'EOF'
chore(assets): add empty-clients.svg placeholder illustration

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3.3: Create `empty-tours.svg`

**Files:**
- Create: `assets/illustrations/empty-tours.svg`

- [ ] **Step 1: Write the file**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 180" width="320" height="180" fill="none">
  <!-- Map background -->
  <rect x="40" y="30" width="240" height="120" rx="8" fill="#F1EBDF" stroke="#E8E1D4" stroke-width="1.5"/>
  <!-- Winding route -->
  <path d="M 70 130 Q 110 70 150 90 Q 190 110 230 60" stroke="#C77B5C" stroke-width="3.5" stroke-linecap="round" fill="none" stroke-dasharray="6 6"/>
  <!-- Start pin -->
  <circle cx="70" cy="130" r="8" fill="#4A6B52"/>
  <circle cx="70" cy="130" r="3" fill="#FFFFFF"/>
  <!-- End pin -->
  <g transform="translate(220 50)">
    <path d="M 10 0 C 4 0 0 5 0 10 C 0 17 10 30 10 30 C 10 30 20 17 20 10 C 20 5 16 0 10 0 Z" fill="#C77B5C"/>
    <circle cx="10" cy="10" r="3.5" fill="#FFFFFF"/>
  </g>
  <!-- Mid waypoint -->
  <circle cx="150" cy="90" r="5" fill="#4A6B52" opacity="0.5"/>
</svg>
```

- [ ] **Step 2: Commit**

```bash
git add assets/illustrations/empty-tours.svg
git commit -m "$(cat <<'EOF'
chore(assets): add empty-tours.svg placeholder illustration

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3.4: Create `tour-completed.svg`

**Files:**
- Create: `assets/illustrations/tour-completed.svg`

- [ ] **Step 1: Write the file**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 160" width="240" height="160" fill="none">
  <!-- Soft ring -->
  <circle cx="120" cy="80" r="62" fill="#4A6B52" opacity="0.12"/>
  <!-- Solid sage disc -->
  <circle cx="120" cy="80" r="46" fill="#4A6B52"/>
  <!-- White checkmark -->
  <path d="M 100 82 L 116 96 L 142 66" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
  <!-- Confetti bits -->
  <circle cx="50" cy="40" r="3" fill="#C77B5C"/>
  <circle cx="200" cy="120" r="3" fill="#C77B5C"/>
  <rect x="40" y="105" width="6" height="6" fill="#C77B5C" transform="rotate(20 43 108)"/>
  <rect x="195" y="35" width="6" height="6" fill="#4A6B52" opacity="0.5" transform="rotate(15 198 38)"/>
  <line x1="22" y1="80" x2="34" y2="80" stroke="#C77B5C" stroke-width="2" stroke-linecap="round"/>
  <line x1="206" y1="80" x2="218" y2="80" stroke="#C77B5C" stroke-width="2" stroke-linecap="round"/>
</svg>
```

- [ ] **Step 2: Commit**

```bash
git add assets/illustrations/tour-completed.svg
git commit -m "$(cat <<'EOF'
chore(assets): add tour-completed.svg placeholder illustration

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3.5: Register the illustrations directory in pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add to the assets list**

In `pubspec.yaml`, under `flutter > assets:`, add (preserving the existing `.env`):

```yaml
  assets:
    - .env
    - assets/illustrations/
```

(Note the trailing slash to register the whole directory.)

- [ ] **Step 2: Verify**

```bash
flutter pub get
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors, 54 tests pass, APK builds.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml
git commit -m "$(cat <<'EOF'
chore(assets): register illustrations directory

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# Phase 4 — Refactor simple screens

**Goal at end of phase:** Onboarding, Settings, Tours list, and Clients list use the new tokens, theme, and signature widgets. Bottom-tab loop feels cohesive.

## Task 4.1: Refactor `onboarding_screen.dart`

**Files:**
- Modify: `lib/presentation/onboarding/onboarding_screen.dart`

- [ ] **Step 1: Replace the screen body**

The screen currently has a circular FIcons.scissors badge, an `xl3` title, two FCards (welcome + address), and a primary FButton. We replace with: SVG illustration, big Fraunces title, italic subtitle, two `AppSectionCard`s, an `AppPrimaryButton`.

Read the current file:

```bash
cat lib/presentation/onboarding/onboarding_screen.dart
```

Then rewrite it as:

```dart
// lib/presentation/onboarding/onboarding_screen.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/settings.dart';
import '../../infra/services/ban_geocoding_service.dart';
import '../../state/providers.dart';
import '../widgets/address_autocomplete_field.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  GeocodingResult? _picked;
  bool _saving = false;

  Future<void> _confirm() async {
    final picked = _picked;
    if (picked == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).save(
            Settings(
              baseCoordinates: picked.coordinates,
              baseAddressLabel: picked.label,
            ),
          );
      if (!mounted) return;
      context.go('/clients');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;

    return FScaffold(
      resizeToAvoidBottomInset: true,
      child: SingleChildScrollView(
        padding: AppSizes.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero illustration
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: SvgPicture.asset(
                  'assets/illustrations/welcome.svg',
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Title
            Text(
              l.appTitle,
              textAlign: TextAlign.center,
              style: theme.typography.xl4.copyWith(
                color: theme.colors.foreground,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Italic subtitle
            Text(
              l.onboardingHeroSubtitle,
              textAlign: TextAlign.center,
              style: theme.typography.lg.copyWith(
                color: theme.colors.mutedForeground,
                fontStyle: FontStyle.italic,
                fontFamily: 'Fraunces',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Welcome section
            AppSectionCard(
              icon: FIcons.sparkles,
              title: l.onboardingWelcomeTitle,
              child: Text(
                l.onboardingWelcomeBody,
                style: theme.typography.md.copyWith(
                  color: theme.colors.foreground,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Address section
            AppSectionCard(
              icon: FIcons.mapPin,
              title: l.onboardingAddressTitle,
              child: AddressAutocompleteField(
                onPicked: (r) => setState(() => _picked = r),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // CTA
            AppPrimaryButton(
              label: l.onboardingCta,
              prefixIcon: FIcons.arrowRight,
              onPress: _picked == null ? null : _confirm,
              loading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/presentation/onboarding/onboarding_screen.dart
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors, 54 tests pass, APK builds.

- [ ] **Step 3: Manual smoke**

If a device is available, run the app with a fresh install (clear app data first via `adb shell pm clear fr.coupelaine.coupe_laine`). Verify:
- The welcome SVG renders.
- The title is in Fraunces (rounded curves on the C and L).
- The subtitle is italic.
- The two section cards render with terracotta icon circles.
- The CTA is sage green and 56px high.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/onboarding/
git commit -m "$(cat <<'EOF'
feat(onboarding): pastoral chic redesign

Replaces the icon badge with the welcome SVG, swaps to AppSectionCards,
and uses AppPrimaryButton for the CTA. Italic Fraunces subtitle for
editorial flavor.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4.2: Refactor `settings_screen.dart`

**Files:**
- Modify: `lib/presentation/settings/settings_screen.dart`

The screen has 4 sections (Apparence, Adresse de base, Valeurs par défaut, Données). We replace each `FCard` with `AppSectionCard`, replace inline FTiles with `AppListTile`s where appropriate, and replace the save FButton with `AppPrimaryButton`.

- [ ] **Step 1: Read the current file**

```bash
cat lib/presentation/settings/settings_screen.dart
```

- [ ] **Step 2: Rewrite the screen**

The full rewrite is mechanical: every `FCard(title: Text(...), child: ...)` becomes `AppSectionCard(icon: ..., title: ..., child: ...)`. The icons:
- Apparence → `FIcons.palette`
- Adresse de base → `FIcons.house`
- Valeurs par défaut → `FIcons.sliders`
- Données → `FIcons.database`

Replace `FButton` (Save) with `AppPrimaryButton`. Replace internal `FTile` rows for the theme picker with `AppListTile`s.

Apply the new spacing tokens: `AppSizes.screenPadding` for the outer padding, `AppSpacing.md` between cards.

Here's the structural skeleton; preserve all the existing logic (theme mode persistence, base-changed dialog, JSON export/import flows, dirty detection). The full file is too long to inline here — apply these substitutions:

```dart
// Imports — add:
import '../../core/design_tokens.dart';
import '../widgets/app_section_card.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_primary_button.dart';

// Replace each `FCard(title: Text(l.X), child: Y)` with:
AppSectionCard(
  icon: <icon for X>,
  title: l.X,
  child: Y,
)

// Replace the save FButton at the bottom with:
AppPrimaryButton(
  label: l.settingsSave,
  onPress: _isDirty ? _save : null,
)

// Replace SingleChildScrollView padding with:
SingleChildScrollView(
  padding: AppSizes.screenPadding,
  ...
)

// Spacing between cards: const SizedBox(height: AppSpacing.md)
```

For the theme picker `_ThemeOption` rows: replace the inner `FTile` with `AppListTile` and use the active mode's check via a small `Icon(FIcons.check, color: theme.colors.primary)` as suffix.

Page heading style stays at `theme.typography.xl3` — Fraunces is already wired.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/presentation/settings/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

- [ ] **Step 4: Manual smoke**

Open Settings, verify:
- 4 section cards with terracotta icon circles.
- Theme picker rows look like cards (12px gap between them).
- Save button is sage green, 56px.
- Toggling the theme mode immediately rerenders the rest of the app.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/settings/
git commit -m "$(cat <<'EOF'
feat(settings): pastoral chic redesign

AppSectionCards for the four sections, AppListTile theme picker rows,
AppPrimaryButton save.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4.3: Refactor `tours_list_screen.dart`

**Files:**
- Modify: `lib/presentation/tours/tours_list_screen.dart`

- [ ] **Step 1: Read current file**

```bash
cat lib/presentation/tours/tours_list_screen.dart
```

- [ ] **Step 2: Rewrite**

Apply substitutions:
- Each `_TourTile` (currently a Forui `FTile`) becomes an `AppListTile` with:
  - `prefix:` an icon in a colored circle (sage for completed, terracotta-light for planned). Build a small `Container(width: 36, height: 36, decoration: BoxDecoration(color: <color>, shape: BoxShape.circle), child: Icon(...))`.
  - `suffix:` `AppBadge.completed(context)` or `AppBadge.planned(context)`.
- Wrap the list with `SliverPadding` adding `AppSpacing.md` horizontal and bottom, with inter-tile spacing of `AppSpacing.sm`. Use `SliverList.separated(separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm), ...)`.
- Empty state becomes `AppEmptyState(illustrationAsset: 'assets/illustrations/empty-tours.svg', title: l.emptyToursTitle, body: l.emptyToursBody)`.
- The page heading and stats are unchanged (already `xl3` Fraunces via the new typography).
- The `SegmentedButton` filter stays — wrap in `Material(type: MaterialType.transparency)` if not already (it should be from the earlier fix).
- Apply `AppSizes.screenPadding` to the outer scroll.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/presentation/tours/tours_list_screen.dart
flutter test
flutter build apk --debug 2>&1 | tail -3
```

- [ ] **Step 4: Manual smoke**

Verify on device:
- Tile rows look like individual cards with 12px gap.
- Status badges (Planifiée/Réalisée) render as pills.
- Empty state shows the empty-tours.svg with title + body.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/tours/tours_list_screen.dart
git commit -m "$(cat <<'EOF'
feat(tours): pastoral chic list redesign

AppListTile rows with circular calendar prefix and AppBadge status,
AppEmptyState with empty-tours.svg.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4.4: Refactor `clients_list_screen.dart`

**Files:**
- Modify: `lib/presentation/clients/clients_list_screen.dart`

- [ ] **Step 1: Read current file**

```bash
cat lib/presentation/clients/clients_list_screen.dart
```

- [ ] **Step 2: Rewrite**

Apply substitutions:
- `_ClientTile` becomes `AppListTile` with:
  - `prefix:` a sage circle with the client's initials in white. Build with `Container(width: 36, height: 36, decoration: BoxDecoration(color: theme.colors.primary, shape: BoxShape.circle), alignment: Alignment.center, child: Text(initials, style: ...))`.
  - `subtitle:` "{city} · {last shearing or 'Jamais tondu'}".
  - `suffix:` a `Wrap(spacing: AppSpacing.xs, children: [...badges])` of `AppBadge.waiting(context)`, `AppBadge.overdue(context)` (if last shearing > 395 days), `AppBadge.recompute(context)` if `needsDistanceRecompute`. If no badges apply, use `Icon(FIcons.chevronRight, color: theme.colors.mutedForeground)`.
- Recompute banner card becomes `AppSectionCard(icon: FIcons.triangleAlert, title: 'Distances à recalculer', child: Row(...))` with the count + retry FButton.
  - Or simpler: keep the `FCard` row layout and just adjust spacing. Your call — but the icon-circle prefix would be misleading for an alert, so a custom layout is fine. Use a destructive color for the icon circle (`iconBackground: theme.colors.destructive`).
- Empty state becomes `AppEmptyState(illustrationAsset: 'assets/illustrations/empty-clients.svg', title: l.emptyClientsTitle, body: l.emptyClientsBody, action: AppPrimaryButton(label: l.clientsAddNew, prefixIcon: FIcons.userPlus, onPress: () => context.push('/clients/new')))`.
- Replace `FloatingActionButton` (currently wrapped in Material(transparency)) with a positioned `AppPrimaryButton` that has prefix `FIcons.userPlus`, label `l.clientsAddNew`, and a fixed width (e.g. wrapped in `IntrinsicWidth` or a constrained box). Position it bottom: 20, right: 20.
  - Alternative: keep the FAB but recolor it via the theme. Simpler. Either OK — choose the one that looks cleaner on device.
- Apply `AppSpacing.sm` separator between tiles in the list.
- Apply `AppSizes.screenPadding` for outer padding.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/presentation/clients/clients_list_screen.dart
flutter test
flutter build apk --debug 2>&1 | tail -3
```

- [ ] **Step 4: Manual smoke**

Verify:
- Avatars are sage circles with white initials.
- Status badges look like pills with icons.
- Empty state shows empty-clients.svg.
- "Nouveau client" CTA is sage green.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/clients/clients_list_screen.dart
git commit -m "$(cat <<'EOF'
feat(clients): pastoral chic list redesign

AppListTile rows with sage initial avatars and AppBadge chips,
AppEmptyState with empty-clients.svg + AppPrimaryButton CTA.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4.5: Phase 4 sweep

- [ ] **Step 1: Manual end-to-end smoke** on device

Walk through:
1. Fresh install (`adb shell pm clear fr.coupelaine.coupe_laine`).
2. Onboarding → fill address → Commencer.
3. Land on Clients (empty) → see empty-clients.svg + CTA.
4. Tap "Nouveau client" → form (still old style — that's P5).
5. Add a client, return to list → see the new tile.
6. Switch to Tours tab (empty) → see empty-tours.svg.
7. Switch to Settings → see the four section cards.

Note any visual rough edges. Don't fix what's still in old style — that's P5.

```bash
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 54 tests pass, APK builds.

- [ ] **Step 2: No commit needed** — sweep only.

---

# Phase 5 — Refactor complex screens

**Goal at end of phase:** All remaining screens use the new pattern. Full client-create → tour-plan → tour-complete flow looks coherent.

## Task 5.1: Refactor `client_form_screen.dart`

**Files:**
- Modify: `lib/presentation/clients/client_form_screen.dart`

- [ ] **Step 1: Read current file**

```bash
cat lib/presentation/clients/client_form_screen.dart
```

- [ ] **Step 2: Rewrite**

Substitutions:
- Three sections become `AppSectionCard`:
  - "Identité" with `FIcons.user` (name + phone)
  - "Adresse" with `FIcons.mapPin` (the AddressAutocompleteField)
  - "Tonte" with `FIcons.scissors` (sheep count + min/sheep override + notes)
- Replace the bottom Save FButton with `AppPrimaryButton(label: l.clientFormSave, onPress: _saving ? null : _submit, loading: _saving)`.
- Apply `AppSizes.screenPadding` for outer.
- Spacing between section cards: `AppSpacing.md`.
- Inside cards, gap between FTextFields: `AppSpacing.md` (or use `AppSpacing.sm` if it gets too tall).

Preserve all existing logic: validation, matrix sync trigger, provider invalidation, error toasts.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/presentation/clients/client_form_screen.dart
flutter test
flutter build apk --debug 2>&1 | tail -3
```

- [ ] **Step 4: Manual smoke**

Open the form, verify:
- 3 section cards with their icons.
- Save button is full-width, sage, 56px.
- Form still validates and saves correctly.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/clients/client_form_screen.dart
git commit -m "$(cat <<'EOF'
feat(clients): pastoral chic form redesign

Three AppSectionCards (Identité/Adresse/Tonte) + AppPrimaryButton save.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5.2: Refactor `client_detail_screen.dart`

**Files:**
- Modify: `lib/presentation/clients/client_detail_screen.dart`

- [ ] **Step 1: Read current file**

```bash
cat lib/presentation/clients/client_detail_screen.dart
```

- [ ] **Step 2: Rewrite**

Substitutions:
- Replace the existing "hero" `FCard.raw` (sheep count display) with:
  ```dart
  AppHeroCard(
    badge: client.isWaiting ? AppBadge.waiting(context) : null,
    bigNumber: '${client.sheepCount}',
    label: 'moutons',
    subtitle: lastShearingText,
  )
  ```
- Recompute banner: `AppSectionCard(icon: FIcons.triangleAlert, iconBackground: theme.colors.destructive, title: '...', child: ...)` with the inline retry button.
- Address card: `AppSectionCard(icon: FIcons.mapPin, title: l.clientDetailSectionAddress, child: <existing FTile>)`.
- Contact card (if phone): `AppSectionCard(icon: FIcons.phone, title: l.clientDetailSectionContact, ...)`.
- Notes card (if notes): `AppSectionCard(icon: FIcons.notebookPen, title: l.clientDetailSectionNotes, ...)`.
- Status section: `AppSectionCard(icon: FIcons.bellRing, title: l.clientDetailSectionStatus, child: <FTile + FSwitch>)`.
- Bottom CTA: `AppPrimaryButton(label: l.clientDetailFindNearby, prefixIcon: FIcons.compass, onPress: ...)`. Disabled when not waiting or recompute pending.
- Spacing: `AppSizes.screenPadding` outer, `AppSpacing.md` between cards.

Preserve all logic.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/presentation/clients/client_detail_screen.dart
flutter test
flutter build apk --debug 2>&1 | tail -3
```

- [ ] **Step 4: Manual smoke**

Open a client detail, verify:
- Hero card shows the sheep count in `xl4` Fraunces with the asymmetric corner.
- Sections all have their colored icon circles.
- "Voir les clients à proximité" button is prominent.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/clients/client_detail_screen.dart
git commit -m "$(cat <<'EOF'
feat(clients): pastoral chic detail redesign

AppHeroCard for sheep count, AppSectionCards for address/contact/notes/
status, AppPrimaryButton for the proximity CTA.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5.3: Refactor `tour_draft_screen.dart`

**Files:**
- Modify: `lib/presentation/tours/tour_draft_screen.dart`

- [ ] **Step 1: Read current file**

```bash
cat lib/presentation/tours/tour_draft_screen.dart
```

- [ ] **Step 2: Rewrite**

Substitutions:
- "Quand" card: `AppSectionCard(icon: FIcons.calendarClock, title: l.tourDraftWhenTitle, child: <2 inline tiles for date/time>)` — for the inner two tiles, use `AppListTile`s with `AppListTile`'s constructor accepting a `subtitle:` (date / time formatted) and `prefix:` `Icon(FIcons.calendar)` / `Icon(FIcons.clock)`, and `onPress: _pickDate` / `_pickTime`. Stack them with a `SizedBox(height: AppSpacing.sm)` between.
- Steps section: keep the heading "Étapes" in `lg` Inter 600 (use `theme.typography.lg.copyWith(fontWeight: FontWeight.w600)`).
- Reorderable list: replace each `FTile` row with an `AppListTile` configured the same way. The `prefix:` is the existing sage circle with the visit number. The `suffix:` is the drag handle `Icon(FIcons.gripVertical)`. Note: `AppListTile.onPress` should be `null` here (no row tap, only drag). Show fee share inline in the subtitle, e.g. `subtitle: '${formatHm(arr)} → ${formatHm(dep)} · $fee'`.
- Summary footer: replace the existing `FCard.raw` summary with a small `AppHeroCard` (use a lightweight version — no badge, just `bigNumber: km, label: 'km au total', subtitle: '...'`). Or keep as a thin `FCard` — your call based on visual weight.
- Action row: replace `OutlinedButton`/etc. with two FButtons. "Optimiser" is `FButton(variant: FButtonVariant.outline, ...)` standard size. "Enregistrer" is `AppPrimaryButton(label: l.tourDraftConfirm)` taking the remaining width via `Expanded`.
- Apply `AppSpacing.md` paddings around the column items, keep the SafeArea bottom row.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/presentation/tours/tour_draft_screen.dart
flutter test
flutter build apk --debug 2>&1 | tail -3
```

- [ ] **Step 4: Manual smoke**

Compose a tour from scratch (proximity → select → plan tour). Verify:
- The "Quand" card shows date/time as tappable rows.
- Étape rows look spacious with sage numbered circles.
- The action row at the bottom has a clear visual hierarchy.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/tours/tour_draft_screen.dart
git commit -m "$(cat <<'EOF'
feat(tours): pastoral chic draft redesign

AppSectionCard wrapping date/time pickers, AppListTile reorderable
stops, AppHeroCard summary, AppPrimaryButton confirm.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5.4: Refactor `tour_detail_screen.dart`

**Files:**
- Modify: `lib/presentation/tours/tour_detail_screen.dart`

- [ ] **Step 1: Read current file**

```bash
cat lib/presentation/tours/tour_detail_screen.dart
```

- [ ] **Step 2: Rewrite**

Substitutions:
- Replace the existing hero `FCard.raw` (status + total fee) with:
  ```dart
  AppHeroCard(
    badge: completed
        ? AppBadge.completed(context)
        : AppBadge.planned(context),
    bigNumber: formatEuros(bundle.tour.totalTravelFeeCents),
    label: l.tourDetailFeeTotalCaption,
    subtitle: '$km km · ${formatDuration(driveMin)} de trajet · Départ ${formatHm(bundle.tour.startTimeMinutes)}',
  )
  ```
- Long-day badge stays standalone after the hero — wrap in a `Padding(EdgeInsets.symmetric(vertical: AppSpacing.xs))` and use `AppBadge.longDay(context)`.
- Schedule section: `AppSectionCard(icon: FIcons.listOrdered, title: l.tourDetailScheduleTitle, child: Column(children: [for stop ...]))`. Each stop is an `AppListTile` with the same numbered sage prefix circle. Subtitle = arrival → departure + sheep count. Suffix = formatted euro share in muted text.
- Mark-as-completed CTA (when planned): `AppPrimaryButton(label: l.tourDetailComplete, prefixIcon: FIcons.check, onPress: () => _confirmComplete(...))`.
- Apply `AppSizes.screenPadding`.

Preserve the share button in the FHeader.nested suffixes and all the completion logic.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/presentation/tours/tour_detail_screen.dart
flutter test
flutter build apk --debug 2>&1 | tail -3
```

- [ ] **Step 4: Manual smoke**

Open a tour detail, verify:
- Hero card shows status badge above big fee number.
- Schedule rows look like cards with sage numbered circles.
- "Marquer comme réalisée" is full-width sage with a check prefix.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/tours/tour_detail_screen.dart
git commit -m "$(cat <<'EOF'
feat(tours): pastoral chic detail redesign

AppHeroCard for the fee, AppSectionCard for the schedule with numbered
AppListTiles, AppPrimaryButton complete CTA.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5.5: Refactor proximity screens

**Files:**
- Modify: `lib/presentation/proximity/proximity_screen.dart`
- Modify: `lib/presentation/proximity/proximity_list_view.dart`
- Modify: `lib/presentation/proximity/proximity_map_view.dart`

- [ ] **Step 1: `proximity_screen.dart`**

Substitutions:
- Pivot info row: keep as-is (small muted line).
- Radius card: `AppSectionCard(icon: FIcons.compass, title: l.proximityRadiusTitle, child: Column(children: [<radius value text>, <Material(transparency)+Slider>]))`.
- The Slider: keep its Material(transparency) wrapper. Tune its `activeColor: theme.colors.primary` so it shows in sage.
- Tabs (FTabs Liste/Carte): unchanged.
- Footer (selection bar): replace the FButton with `AppPrimaryButton(label: l.proximityPlanTour, prefixIcon: FIcons.route, onPress: ...)`.

- [ ] **Step 2: `proximity_list_view.dart`**

Each result row becomes an `AppListTile`:
- `prefix:` `Icon(FIcons.mapPin, color: theme.colors.mutedForeground)` (or a small sage circle with `FIcons.user` for consistency with clients list).
- `subtitle:` "{city} · {km} km · {min} min · {sheep} moutons".
- `suffix:` `Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? theme.colors.primary : Colors.transparent, border: selected ? null : Border.all(color: theme.colors.border, width: 2)), child: selected ? Icon(FIcons.check, color: theme.colors.primaryForeground, size: 16) : null)`.
- `onPress:` toggles selection.
- 12px gap between tiles.

Empty state: `AppEmptyState(illustrationAsset: 'assets/illustrations/empty-clients.svg', title: l.proximityNoneInRadius, body: l.proximityNoneInRadiusBody)` — reuse `empty-clients.svg` (we don't need a fifth illustration).

- [ ] **Step 3: `proximity_map_view.dart`**

Pin colors stay as-is from the prior pass (sage primary for selected, muted for unselected). No widget swap needed beyond verifying the colors match the new theme tokens.

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/presentation/proximity/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

- [ ] **Step 5: Manual smoke**

Open proximity from a waiting client. Verify:
- Radius card with terracotta compass icon.
- Slider in sage.
- List rows look like cards with check-circle suffix when selected.
- Map pins are sage when selected.
- Footer "Composer la tournée" is prominent.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/proximity/
git commit -m "$(cat <<'EOF'
feat(proximity): pastoral chic redesign

AppSectionCard for radius, AppListTile rows with selection check,
AppPrimaryButton footer.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5.6: Final phase sweep

- [ ] **Step 1: Run all checks**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors (or only the 2 pre-existing drift codegen infos), 54 tests pass, APK builds.

- [ ] **Step 2: Full manual smoke walk-through** on device

Fresh install (`adb shell pm clear fr.coupelaine.coupe_laine`). Walk:

1. Onboarding — pick base address.
2. Add 3 clients in different communes.
3. Mark 2 of them as waiting.
4. Open one waiting client → tap "Voir les clients à proximité" → see the third on the radius map.
5. Select the third + back to selection list → "Composer la tournée".
6. Pick date, optimise order, confirm save.
7. Land on tour detail → see hero card with total fee, schedule with numbered stops.
8. Tap "Marquer comme réalisée" → confirm.
9. Open Settings → toggle dark mode → verify everything still looks right.
10. Toggle back to light.

Each screen should feel cohesive: same heading style (Fraunces xl3), same section card pattern, same button heights, same spacing rhythm.

- [ ] **Step 3: Tag**

```bash
git tag -a v0.3.0-pastoral-chic -m "UI v2 — Pastoral chic redesign complete"
```

---

# Done

The redesign is shipped. Future enhancements that the spec marked out-of-scope:
- Animations / transitions between screens.
- High-contrast outdoor mode.
- Multi-step onboarding tutorial.
- Replacing placeholder SVGs with bespoke unDraw downloads.

When you're ready, return to the original spec/plan flow for any of those.
