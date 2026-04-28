# UI Polish v2 — Pastoral Chic

> Second pass at the UI after the MVP and the v1 Forui migration. Goal: make the app feel crafted and on-brand instead of "vanilla Forui blue".

## Context

The MVP (Apr 2026) shipped a fully working Android app for a Brittany sheep shearer. The v1 redesign migrated the screens from Material to Forui-native components with a `blue.light.touch` palette and light/dark mode. After that pass, four problems remain:

- Spacing too tight on lists and within cards
- Too text-heavy — no illustrations, weak empty states
- Typography hierarchy doesn't pop — titles read like body text
- Components feel like default Forui — no signature look

The redesign aims for a **chaleureux/accessible** personality (à la Headspace, AirBnB, modern cooking apps) — soft warm palette, friendly serif headlines, custom illustrations, generous spacing, and 5-6 reusable signature components that give the app its own visual identity.

## Goals

- Replace the cold blue palette with a warm sage + terracotta scheme that evokes wool/agriculture/Brittany without being cliché.
- Introduce a serif (Fraunces) for headlines and key numbers to bring personality.
- Add 4 simple SVG illustrations to enrich empty states and onboarding.
- Define a generous spacing system and apply it everywhere.
- Build 6 signature widgets (`AppHeroCard`, `AppSectionCard`, `AppListTile`, `AppBadge`, `AppEmptyState`, `AppPrimaryButton`) to capture the new patterns.
- Refactor every screen to use the new tokens, theme, and components.

## Non-goals

- Custom animations / transitions between screens.
- A separate "high-contrast outdoor mode".
- Multi-step onboarding tutorial.
- Changes to business logic, navigation, persistence, or providers.

## 1. Visual identity

### Palette

**Light mode**

| Token | Hex | Usage |
|---|---|---|
| `background` | `#F8F4ED` | Global FScaffold background (warm ivory) |
| `card` | `#FFFFFF` | FCard surfaces, AppListTile background |
| `primary` | `#4A6B52` | CTA, active states, hero accents (deep sage) |
| `primaryForeground` | `#FFFFFF` | Text on primary |
| `accent` | `#C77B5C` | Section icons, "En attente" badges, hero numbers (terracotta) |
| `accentForeground` | `#FFFFFF` | Text on accent |
| `foreground` | `#1F1B16` | Main text (warm anthracite) |
| `mutedForeground` | `#6B6359` | Secondary text (warm gray) |
| `border` | `#E8E1D4` | Card / tile borders (light warm gray) |
| `destructive` | `#B33A3A` | Delete actions, "En retard" badge (matte brick red) |
| `destructiveForeground` | `#FFFFFF` | Text on destructive |

**Dark mode**

| Token | Hex |
|---|---|
| `background` | `#1F1B16` |
| `card` | `#2B2620` |
| `primary` | `#7C9C7E` |
| `primaryForeground` | `#1F1B16` |
| `accent` | `#E0926D` |
| `accentForeground` | `#1F1B16` |
| `foreground` | `#F5F0E8` |
| `mutedForeground` | `#A89F92` |
| `border` | `#3A332A` |
| `destructive` | `#D45A5A` |

The palette is built as a custom `FColorScheme` and passed to `FThemeData`. Forui 0.21 supports custom color schemes natively. The current `blue.light.touch` is just a prebuilt `FColorScheme`; we replace it with our own.

### Typography

Two families:

- **Fraunces** (Google Fonts, OFL license, free for commercial use). Modern serif with optical-size variation. Used for screen titles, hero numbers, and section titles. Bundled in `assets/fonts/` (no runtime download — works offline).
- **Inter** (already bundled by Forui). Used for body text, labels, button text, and tabular numbers.

Type scale:

| Token | Size | Family / Weight | Usage |
|---|---|---|---|
| `display` | 40px | Fraunces 800 | Hero numbers (sheep count, total fee) |
| `xl3` | 28px | Fraunces 700 | Screen titles ("Clients", "Tournées") |
| `xl2` | 22px | Fraunces 600 | Section card titles, hero card subtitles |
| `lg` | 18px | Inter 600 | FCard titles, bold list item names |
| `md` | 15px | Inter 500 | Standard text, FTile titles |
| `sm` | 13px | Inter 400 | Subtitles, captions, metadata |
| `xs` | 11px | Inter 500 | Badge text, tiny labels |

The onboarding subtitle "Votre compagnon de tournée" is rendered in italic Fraunces 600 at `lg` size — an inline override for editorial flavor, not a type-scale token.

Tabular numbers (€, km, durations, times) use Inter with the `tnum` OpenType feature enabled to keep columns aligned.

### Iconography & illustrations

Three layers:

1. **Lucide icons via `FIcons`** — already in place. For inline actions, prefix icons in tiles, button icons. Unchanged.
2. **Hero icons** — Lucide icons sized 56-72px in a colored circle (terracotta accent). Used for empty-state illustrations when a custom SVG isn't warranted, and for section card prefixes (32×32 circle).
3. **Custom SVG illustrations** — sourced from [unDraw.co](https://undraw.co), recolored in our sage/terracotta palette before download. Bundled in `assets/illustrations/`. Rendered via `flutter_svg`. Four illustrations total:
   - `welcome.svg` — onboarding hero (~280×200)
   - `empty-clients.svg` — empty Clients list (~240×180)
   - `empty-tours.svg` — empty Tours list (~240×180)
   - `tour-completed.svg` — celebratory illustration after marking a tour completed (~200×160)

Estimated size: 5-15 KB per SVG, ~40 KB total.

## 2. Spacing system

### Token scale

Multiples of 4. All padding, margins, and gaps use these tokens.

| Token | Value | Use |
|---|---|---|
| `xxs` | 4px | Inline icon-to-text gap |
| `xs` | 8px | Very tight gap (badge to badge) |
| `sm` | 12px | Form field gap, inner FBadge padding |
| `md` | 16px | Default screen lateral padding (we'll use 20 — see below), gap between tiles |
| `lg` | 24px | FCard internal padding, gap between sections |
| `xl` | 32px | Hero card vertical padding, gap between major groups |
| `xxl` | 48px | Page top padding, around empty-state illustrations |

### Concrete application

| Element | Value |
|---|---|
| Screen lateral padding | 20px |
| Screen top padding (under header) | 24px |
| Screen bottom padding | 40px |
| Hero card padding | 24px horizontal × 32px vertical |
| Hero card bottom margin | 24px |
| Standard FCard padding | 20px all sides |
| Standard FCard bottom margin | 20px |
| AppListTile internal padding | 16px / 16px |
| Gap between AppListTiles | 12px |
| Form field gap (vertical) | 20px |
| Form section gap (between FCards) | 24px |
| FTextField min height | 56px |
| AppPrimaryButton (full-width) height | 56px |
| Secondary FButton height | 48px |
| FButton.icon size | 44×44px |
| Empty-state top padding | 64px |
| Empty-state illustration → title gap | 24px |
| Empty-state title → body gap | 8px |
| Empty-state body → CTA gap | 32px |

These constants live in `lib/core/design_tokens.dart` as `AppSpacing.{xxs,xs,sm,md,lg,xl,xxl}`.

## 3. Signature components

Six new widgets in `lib/presentation/widgets/`. Each replaces an existing pattern that today is built ad-hoc on top of Forui primitives.

### `AppHeroCard`

A featured card with asymmetric border radius (top-left 24px, others 8px) and a subtle ivory→warm-ivory vertical gradient background. Wraps `FCard.raw`.

```dart
AppHeroCard({
  Widget? badge,                  // optional badge above the big number
  required String bigNumber,       // e.g. "42"
  required String label,           // e.g. "moutons"
  String? subtitle,                // e.g. "Dernière tonte : 12/03"
})
```

Used on: client detail (sheep count), tour detail (total fee), tour-completed celebration.

### `AppSectionCard`

`FCard` with a colored 32×32 circle prefix (terracotta) holding an icon, plus a section title. Standard 20px internal padding, 20px bottom margin.

```dart
AppSectionCard({
  required IconData icon,
  required String title,
  required Widget child,
})
```

Used everywhere screens have logical sections (Identité, Adresse, Tonte, Apparence, Données, Quand, Planning…).

### `AppListTile`

Wrapper around `FTile` that forces card-like styling: 12px gap between tiles, 12px border radius per tile, card-color background, 16/16 internal padding. Each tile reads as an individual card rather than a row in a tight table.

```dart
AppListTile({
  Widget? prefix,
  required String title,
  String? subtitle,
  Widget? suffix,
  VoidCallback? onPress,
})
```

Used on: clients list, tours list, proximity list, tour stops, schedule, theme picker rows.

### `AppBadge`

Fully-rounded pill with optional 14px prefix icon. Named constructors for the six recurring states: `.waiting`, `.overdue`, `.recompute`, `.completed`, `.planned`, `.longDay`. Each binds the right color, label, and icon.

Style: `BorderRadius.circular(999)`, 6/12 padding, Inter 500 12px text, 14px icon.

### `AppEmptyState`

Unified empty-state pattern.

```dart
AppEmptyState({
  required String illustrationAsset,  // e.g. 'assets/illustrations/empty-clients.svg'
  required String title,
  required String body,
  Widget? action,                     // optional FButton
})
```

Layout: 64px top padding, illustration centered, 24px gap, title (`xl2` Fraunces 600), 8px gap, body (`md` muted), 32px gap to optional CTA.

### `AppPrimaryButton`

Wrapper around `FButton` that forces consistent visual weight on primary CTAs: height 56px, horizontal padding 24px, Inter 600 weight, optional prefix icon.

```dart
AppPrimaryButton({
  required String label,
  IconData? prefixIcon,
  required VoidCallback? onPress,
  bool loading = false,
})
```

When `loading == true`, replaces label with an `FCircularProgress(size: sm)` and disables the press handler.

### Excluded from the component library

To stay YAGNI, we do **not** create:

- Custom `AppHeader` (FHeader.nested suffices).
- Custom scroll containers (Flutter's are fine).
- Custom `FTextField` (Forui's plus our spacing tokens are enough).
- Animation primitives (default Flutter transitions).

## 4. Screen-by-screen refactor

Only changes vs current state listed; structure and logic are unchanged.

### Onboarding

- Replace the round terracotta + scissors icon with `welcome.svg`.
- "Coupe-Laine" title in `display` Fraunces 800.
- Subtitle italic Fraunces (`lg`).
- Description and address sections become `AppSectionCard` (icons: `FIcons.sparkles`, `FIcons.mapPin`).
- CTA: `AppPrimaryButton(label: 'Commencer')`.

### Clients list

- Heading and stats line: typography migrated to Fraunces (`xl3` for title, `sm` muted for stats).
- `SegmentedButton` filter unchanged.
- Recompute banner: `AppSectionCard` with `FIcons.triangleAlert`.
- Tile rows: each becomes an `AppListTile`. Avatar shows initials in sage; suffix shows `AppBadge` chips.
- Empty state: `AppEmptyState(illustrationAsset: 'assets/illustrations/empty-clients.svg', ...)`.
- FAB replaced by a floating `AppPrimaryButton` with prefix `FIcons.userPlus`, label "Nouveau client".

### Client form (create / edit)

- Header unchanged.
- Three sections become `AppSectionCard`: Identité (`FIcons.user`), Adresse (`FIcons.mapPin`), Tonte (`FIcons.scissors`).
- FTextFields heightened to 56px via spacing tokens.
- Save: `AppPrimaryButton`.

### Client detail

- Hero block: `AppHeroCard(bigNumber: '${sheepCount}', label: 'moutons', subtitle: 'Dernière tonte : …', badge: client.isWaiting ? AppBadge.waiting : null)`.
- Recompute banner: `AppSectionCard`.
- Sections (Adresse, Contact, Notes) all `AppSectionCard`.
- Status section: `AppSectionCard` containing an FTile with the `FSwitch` suffix.
- "Voir les clients à proximité": `AppPrimaryButton` full width, `FIcons.compass` prefix.

### Tours list

- Heading and stats migrated to Fraunces.
- Tile rows: `AppListTile`s. Prefix is a calendar icon in a circle (sage if completed, terracotta light if planned). Suffix uses `AppBadge.completed` or `AppBadge.planned`.
- Empty state: `AppEmptyState` with `empty-tours.svg`.

### Tour draft

- "Quand" card: `AppSectionCard(icon: FIcons.calendarClock)` with two FTiles for date/time pickers.
- "Étapes" section title in `lg` Inter 600.
- Reorderable list rows: `AppListTile`s with sage circle avatar showing the visit number and `FIcons.gripVertical` suffix.
- Summary footer: small `AppHeroCard` with the fee total.
- Action row: `AppPrimaryButton` "Enregistrer" + outline FButton "Optimiser".

### Tour detail

- Hero block: `AppHeroCard(bigNumber: '${formatEuros(totalFee)}', label: 'à répartir', subtitle: '… km · … de trajet · Départ …', badge: AppBadge.completed or AppBadge.planned)`.
- Long-day badge as standalone `AppBadge.longDay` after the hero.
- Schedule: `AppSectionCard(icon: FIcons.listOrdered)` containing numbered `AppListTile`s per stop.
- "Marquer comme réalisée": `AppPrimaryButton` full width.

### Proximity

- Pivot info row: `sm` muted line.
- "Rayon" card: `AppSectionCard(icon: FIcons.compass)`. Slider (Material, wrapped) recolored to use `theme.colors.primary` (sage) for the active track.
- Tabs `FTabs` unchanged structurally.
- List rows: `AppListTile`s with selection icon in suffix (filled sage circle when selected, outlined muted when not).
- Map: pivot star sage, selected pins sage, unselected pins muted.
- Selection footer: `AppPrimaryButton` "Composer la tournée" inside `FScaffold(footer: ...)`.

### Settings

- Heading `xl3` Fraunces.
- Four sections become `AppSectionCard`: Apparence (`FIcons.palette`), Adresse de base (`FIcons.house`), Valeurs par défaut (`FIcons.sliders`), Données (`FIcons.database`).
- Apparence: three `AppListTile`s for the three modes; the active one shows a small `AppBadge.completed`-styled checkmark instead of `FIcons.check`.
- Save (when dirty): `AppPrimaryButton`.

### Dialogs

`FDialog` style adjusted via the custom `FDialogStyle` to use new spacing (24px internal padding, 16px gap between body and actions). Action buttons sized `lg` (matches `AppPrimaryButton` height).

## 5. Implementation strategy

### Phasing

Five sub-phases, executed in order. Each is independently testable.

| # | Phase | Delivers | Verification |
|---|---|---|---|
| **P1** | Tokens + custom theme + deps | `lib/core/design_tokens.dart`, `lib/core/theme/app_themes.dart`, Fraunces bundled in `assets/fonts/`, `flutter_svg` dependency added, custom `FColorScheme` and `FTypography` wired in `app.dart` | App rebuild — palette + Fraunces visible everywhere immediately, even before screen refactor |
| **P2** | Signature components | The six widgets in `lib/presentation/widgets/` (AppEmptyState compiles thanks to flutter_svg installed in P1) | `flutter analyze` clean. No tests; usage validates them in P4-P5 |
| **P3** | Visual assets | Four SVGs in `assets/illustrations/` (sourced from unDraw, recolored) | A throwaway smoke screen confirms SVGs render |
| **P4** | Refactor simple screens | Onboarding, Settings, Tours list, Clients list | Manual smoke on device — onboarding flow polished, lists spacious, palette consistent |
| **P5** | Refactor complex screens | Client form, Client detail, Tour draft, Tour detail, Proximity | Manual smoke — full create-client → plan-tour → complete-tour flow looks coherent |

ETA: ~5-6 days of focused work.

### Specific tech choices

**Fraunces integration**

Bundled offline:

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: Fraunces
      fonts:
        - asset: assets/fonts/Fraunces-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Fraunces-Bold.ttf
          weight: 700
        - asset: assets/fonts/Fraunces-ExtraBold.ttf
          weight: 800
```

Three TTF files (~150 KB each, ~450 KB total). No `google_fonts` package — we want the app usable offline (rural Brittany, spotty signal).

**Custom theme**

`lib/core/theme/app_themes.dart` exports `appLightTheme` and `appDarkTheme` of type `FThemeData`. Built by:

1. Starting from `FThemes.blue.light.touch` (or `.dark.touch`).
2. Overriding `colorScheme` with our sage/terracotta `FColorScheme`.
3. Overriding `typography` with our Fraunces-augmented `FTypography`.

`lib/app.dart` consumes them in place of the current `FThemes.blue.light.touch`.

**Illustrations**

unDraw.co (free, commercial license, customizable color via their UI). Pick four illustrations matching our content — likely:

- `welcome.svg` → unDraw "Welcome" or "Adventure" (recolored sage/terracotta on ivory)
- `empty-clients.svg` → unDraw "Empty list" or a person+notebook
- `empty-tours.svg` → unDraw "Travel" or "Map"
- `tour-completed.svg` → unDraw "Done", "Achievement", or "Celebration"

Recolored via unDraw's hex picker before download. Loaded with `SvgPicture.asset()`.

**Dependencies added**

- `flutter_svg: ^2.0.10+1` (Dan Field, ex-Flutter team — actively maintained).

No `google_fonts` (offline first).

### Compatibility with prior work

- The `Material(type: MaterialType.transparency)` wrappers around Slider, SegmentedButton, RefreshIndicator, etc. stay in place — they're independent of theming.
- All provider invalidations stay unchanged — pure logic.
- The `file_selector` + `share_plus 13` migration is unaffected — we don't touch I/O.
- Existing `FScaffold` / `FCard` / `FTile` usage gets wrapped in our signature widgets but the underlying Forui primitives are untouched.

### Tests

No new automated tests. The 54 existing tests must stay green (they cover business logic, not visuals). Visual validation is manual on device at the end of each phase.

### Out of scope (deferred)

- Hero/slide/fade transitions between screens.
- High-contrast outdoor mode.
- Multi-step onboarding tutorial.
- Toast/snackbar styling beyond Forui defaults.
- Responsive layouts for tablets / web (still Android-only).
