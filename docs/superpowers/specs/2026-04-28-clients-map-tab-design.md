# Clients Map Tab — Design

> Add a new bottom-nav tab that shows all clients on a map, with status-driven colors that the user can customize globally and per-client.

## Context

The app currently has 3 bottom-nav tabs: Clients, Tournées, Paramètres. The user wants a 4th — a map showing every client as a colored pin. Use cases, in order of priority:

1. **Overview** — see at a glance where clients are concentrated, which areas are dense, which are empty.
2. **Quick contact / detail access** — tap a pin → small popup with the client's name and quick actions (call, SMS) + a tap-through to the full detail screen.
3. **Visualize by status** — pins are colored according to whether the client is `default`, `waiting`, `overdue`, or `recompute`. Layers panel can hide some statuses.

The user also wants to **customize** the four status colors globally (in Settings) and **override** the color per client (on the client form). Implementation includes those.

A possible Phase 2 — starting a tour from the map — is explicitly **out of scope** for this spec.

## Goals

- A new "Carte" tab in the bottom nav showing all clients as colored pins.
- Tap a pin → mini-popup over the pin with name + Appeler / SMS / chevron-to-detail.
- A search bar to find a client by name and zoom on them.
- A layers panel to toggle visibility per status.
- A recenter button to fit the map to the visible clients.
- A new Settings section to edit the 4 status colors with a predefined palette picker.
- An optional per-client color override on the client form.
- Schema migration v3 to persist the colors.

## Non-goals

- Marker clustering (`flutter_map_marker_cluster`) — deferred until pin density warrants it.
- Heatmap layer.
- Drawing tour routes on the map.
- Persisting layer visibility between sessions.
- Free-form HSV / HEX color picker — predefined palette only.
- Refactoring the proximity map view to share components with this map.

## 1. Domain & data model

### `ClientStatus` enum (derived)

A computed status, not a persisted field. Derived on the fly from existing client fields.

```dart
enum ClientStatus { defaultStatus, waiting, overdue, recompute }

extension ClientStatusX on Client {
  ClientStatus get status {
    if (needsDistanceRecompute) return ClientStatus.recompute;
    if (isWaiting) return ClientStatus.waiting;
    if (lastShearingDate != null &&
        DateTime.now().difference(lastShearingDate!).inDays > 395) {
      return ClientStatus.overdue;
    }
    return ClientStatus.defaultStatus;
  }
}
```

Priority order: `recompute` > `waiting` > `overdue` > `default`. A client both `waiting` and `overdue` is reported as `waiting` — the rationale is that "waiting" already implies the user has it on their radar, while "overdue" is for clients that have fallen out of mind.

### Color resolution

```dart
extension ClientColorX on Client {
  Color resolvedColor(Settings settings) {
    if (markerColorHex != null) {
      return _hexToColor(markerColorHex!);
    }
    return switch (status) {
      ClientStatus.recompute => _hexToColor(settings.markerRecomputeColor),
      ClientStatus.waiting   => _hexToColor(settings.markerWaitingColor),
      ClientStatus.overdue   => _hexToColor(settings.markerOverdueColor),
      ClientStatus.defaultStatus => _hexToColor(settings.markerDefaultColor),
    };
  }
}
```

The override (`markerColorHex`) trumps the status-derived color.

### New persisted fields

**On `Settings`**, all `TEXT NOT NULL` with hardcoded defaults:

| Column | Default | Purpose |
|---|---|---|
| `marker_default_color` | `#4A6B52` | Sage primary (no special status) |
| `marker_waiting_color` | `#C77B5C` | Terracotta secondary (waiting) |
| `marker_overdue_color` | `#B33A3A` | Brick red (last shearing > 13 months ago) |
| `marker_recompute_color` | `#A89F92` | Warm muted gray (matrix pending) |

**On `Client`**: `marker_color_hex TEXT` (nullable). `null` means "use the status-derived color from Settings".

### Migration v3

In `app_database.dart`:

```dart
@override
int get schemaVersion => 3;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(settingsTable, settingsTable.themeMode);
    }
    if (from < 3) {
      await m.addColumn(settingsTable, settingsTable.markerDefaultColor);
      await m.addColumn(settingsTable, settingsTable.markerWaitingColor);
      await m.addColumn(settingsTable, settingsTable.markerOverdueColor);
      await m.addColumn(settingsTable, settingsTable.markerRecomputeColor);
      await m.addColumn(clientsTable, clientsTable.markerColorHex);
    }
  },
  beforeOpen: (details) async {
    await customStatement('PRAGMA foreign_keys = ON');
  },
);
```

Existing v2 DBs migrate cleanly via the additive `ALTER TABLE` approach.

## 2. Map screen

### Routing

A new entry in the `StatefulShellRoute.indexedStack` branches list, between Tours and Settings:

| Index | Path | Label | Icon (Forui) |
|---|---|---|---|
| 0 | `/clients` | Clients | `users` |
| 1 | `/tours` | Tournées | `route` |
| 2 | `/map` | Carte | `mapPin` (or `map` if available) |
| 3 | `/settings` | Paramètres | `settings` |

The `FBottomNavigationBar` adds the 4th destination. Existing redirect logic (onboarding gate) is unaffected.

### Layout

Full-screen `flutter_map` with overlay controls in a `Stack`:

- Bottom layer: the map (TileLayer + base marker + client markers).
- Top overlay (anchored top, edge-padded `AppSpacing.md`):
  - Search bar `FTextField` inside an `FCard.raw`.
  - Right of the search: two `FButton.icon` — Layers (`FIcons.layers`) and Recenter (`FIcons.locate` or fallback `FIcons.crosshair`).

No `FHeader.nested` — the map fills the whole screen for maximum visual real estate.

### Map widget

```dart
FlutterMap(
  options: MapOptions(
    initialCenter: _initialCenter,
    initialZoom: _initialZoom,
    minZoom: 6,
    maxZoom: 17,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'fr.coupelaine',
    ),
    MarkerLayer(markers: _buildMarkers(visibleClients, settings, baseCoords)),
  ],
)
```

`_initialCenter` and `_initialZoom` are computed once in `initState` from the client list:
- If empty → center on `settings.baseCoordinates`, zoom 11.
- Else → bounding box of all clients + base. `MapController.fitCamera(CameraFit.bounds(...))` after first frame.

### Markers

- **Base marker**: `FIcons.star` 36px in `theme.colors.primary` (sage). Position = `settings.baseCoordinates`.
- **Client markers**: a custom widget showing a colored pin (icon `FIcons.mapPin` 32×40) in `client.resolvedColor(settings)`. `width: 32, height: 40, alignment: Alignment.bottomCenter` so the tip points at the lat/lon.

### Search bar

`FTextField` with `prefixBuilder: (_, __, ___) => Icon(FIcons.search)`, placeholder "Rechercher un client…". Debounced 200ms via a `Timer`. Results dropdown (max 5) appear below the search bar in a small `FCard`. Each result is an `FTile` showing the name + city. Tap → close dropdown, animate camera to the client's coords with zoom 14, then open the popup over that pin.

Search algorithm:

```dart
final normalized = removeAccents(query.toLowerCase());
final matches = clients.where((c) =>
  removeAccents(c.name.toLowerCase()).contains(normalized)
).take(5).toList();
```

A small helper `removeAccents(String s)` strips French diacritics. Implement as a chained `replaceAll` for the common French letters: `é è ê ë → e`, `à â ä → a`, `ç → c`, `ô ö → o`, `î ï → i`, `ù û ü → u`, `ÿ → y`. Same for the uppercase variants. Stays in `lib/presentation/map/map_screen.dart` as a private top-level function (or in `client_actions.dart` if reused later).

### Layers panel

Tap on the Layers button → `showFDialog<void>` (or `showFBottomSheet` if cleaner) with 4 toggles:

```
┌────────────────────────────────────┐
│ Afficher les marqueurs             │
│                                    │
│ ●  Par défaut             [✓]      │
│ ●  En attente             [✓]      │
│ ●  En retard              [✓]      │
│ ●  À recalculer           [✓]      │
│                                    │
│            [   Fermer   ]          │
└────────────────────────────────────┘
```

Each row shows the current status color as a 16×16 dot, the label, and a switch. Toggling updates `mapVisibleStatusesProvider` (a `StateProvider<Set<ClientStatus>>`) which triggers a rebuild of the marker layer.

Default state: all four enabled. State is screen-local — closing the dialog and returning later resets to all-enabled. (Persistence is out of scope per the spec.)

### Recenter button

Tap → `MapController.fitCamera(CameraFit.bounds(latLngBounds: _bounds))` where `_bounds` is computed from currently visible clients + base. With smooth animation if `flutter_map` exposes one, else instant.

### State (Riverpod)

New providers in `lib/state/map_controller.dart`:

```dart
final mapVisibleStatusesProvider = StateProvider<Set<ClientStatus>>(
  (_) => ClientStatus.values.toSet(),
);
final mapSearchQueryProvider = StateProvider<String>((_) => '');
final mapSelectedClientIdProvider = StateProvider<int?>((_) => null);
```

`mapSelectedClientIdProvider` drives the popup visibility — when non-null, the popup for that client is rendered.

Existing providers reused: `clientsAsyncProvider`, `settingsRepositoryProvider`, `clientRepositoryProvider`.

### Map controller and lifecycle

- A `MapController` instance held in the screen state — needed for `fitCamera` and programmatic `move`.
- Disposed in `State.dispose()`.
- `MapEventStream` listened to to dismiss the popup on map drag/zoom (so it doesn't float over the wrong place).

## 3. Mini-popup

### Behavior

- **First tap on a pin** → set `mapSelectedClientIdProvider = client.id`. The popup widget watches this provider and renders if it matches.
- **Tap any blank area on the map** → set `mapSelectedClientIdProvider = null` (popup closes).
- **Tap on the popup body** (outside the action buttons) → navigate to `/clients/$id`.
- **Tap on Appeler / SMS** → launch the intent. Popup stays.
- **Re-tap on the same already-selected pin** → also navigates to `/clients/$id`.
- **Tap on a different pin while a popup is open** → switch popup to the new client.

### Layout

A widget `ClientPinPopup` rendered as a `Marker` in its own `MarkerLayer` above the regular pins, anchored to the selected client's coords with `alignment: Alignment(0, -1.4)` (or similar offset to sit above the pin tip).

```dart
ClientPinPopup({
  required Client client,
  required VoidCallback onOpenDetail,
  required VoidCallback onClose,
})
```

Internal layout:

```
┌──────────────────────────────────────┐
│ Le Gall                          ▶   │  ← name (md bold) + chevronRight
│ Quimper · 12 moutons                 │  ← sm muted
│ ──────────────────────────────────── │
│ ┌────────────┐  ┌────────────┐       │
│ │ 📞 Appeler │  │ 💬  SMS    │       │  ← outline FButton sm
│ └────────────┘  └────────────┘       │
└──────────────────────────────────────┘
```

Width: ~260px (constrained `BoxConstraints`). Height: auto.

Background: `theme.colors.card` with `BorderRadius.circular(AppBorderRadius.md)` and a subtle border `theme.colors.border`. Drop shadow allowed (the only one in the redesign — popups need to feel elevated above the map).

### Code reuse

The `_callPhone(BuildContext, String)` and `_sendSms(BuildContext, String)` helpers currently live as top-level private functions in `client_detail_screen.dart`. Move them to `lib/presentation/clients/client_actions.dart` and rename without the leading underscore (`callPhone`, `sendSms`) so they're importable from outside the file. The detail screen and the new popup both import from there.

This is the only "touched while in the area" cleanup; no other refactor.

## 4. Settings — color customization

### New section in `SettingsScreen`

A 5th `AppSectionCard` inserted between **Valeurs par défaut** and **Données**:

- Icon: `FIcons.palette` (or fallback `FIcons.droplet`)
- Title: "Couleurs des marqueurs"
- Body: a `Column` of 4 `AppListTile`s, one per status.

Each tile:

```dart
AppListTile(
  prefix: _ColorDot(hex: settings.markerDefaultColor), // 24×24 circle
  title: 'Par défaut',
  subtitle: settings.markerDefaultColor.toUpperCase(),  // e.g. "#4A6B52"
  suffix: const Icon(FIcons.chevronRight),
  onPress: () async {
    final picked = await showColorSwatchPicker(
      context: context,
      current: hexToColor(settings.markerDefaultColor),
      title: 'Couleur par défaut',
    );
    if (picked != null) {
      await ref.read(settingsRepositoryProvider).updateMarkerColor(
        ClientStatus.defaultStatus,
        colorToHex(picked),
      );
      ref.invalidate(_settingsAsyncProvider);
      ref.invalidate(clientsAsyncProvider); // refresh map / list
    }
  },
)
```

### `showColorSwatchPicker`

A new public function in `lib/presentation/widgets/color_swatch_picker.dart`:

```dart
Future<Color?> showColorSwatchPicker({
  required BuildContext context,
  required Color current,
  String title = 'Choisir une couleur',
})
```

Renders an `FDialog` with a 4×4 grid of 16 swatches (constants below). The currently-active swatch is wrapped in a thicker border (`theme.colors.foreground`, 3px). Tapping a swatch closes the dialog and returns the chosen `Color`.

A "Réinitialiser" `FButton` ghost at the bottom returns a sentinel meaning "reset to hardcoded default" — easier to implement as a separate `Future<Color?> showColorSwatchPicker(...)` returning `null` for cancel and a special "reset" action returns the hardcoded default `Color`. The caller decides what `null` means.

> Implementation note: `null` means cancel. A separate "Reset" button on the dialog can return the hardcoded default color directly. Caller saves whatever's returned.

### Predefined palette (16 swatches)

```dart
const _swatchPalette = <Color>[
  Color(0xFF4A6B52), // sage primary
  Color(0xFF7C9C7E), // sage light
  Color(0xFFC77B5C), // terracotta primary
  Color(0xFFE0926D), // terracotta light
  Color(0xFFB33A3A), // brick red
  Color(0xFFD45A5A), // red light
  Color(0xFF8B6F47), // brown
  Color(0xFFC9A66B), // ochre
  Color(0xFF6B6359), // muted warm gray
  Color(0xFFA89F92), // muted light
  Color(0xFF1F1B16), // anthracite
  Color(0xFF456D8C), // slate blue
  Color(0xFF7B96B0), // sky
  Color(0xFF8E6FA1), // muted purple
  Color(0xFFE8C547), // warm yellow
  Color(0xFFE07856), // coral
];
```

Stored in `lib/presentation/widgets/color_swatch_picker.dart`.

### `SettingsRepository.updateMarkerColor`

```dart
Future<void> updateMarkerColor(ClientStatus status, String hex) async {
  // Switch on status, write the corresponding column.
}
```

Persists immediately. No batched "Save" — same UX pattern as the theme mode picker.

### Reset behavior

A "Réinitialiser" ghost button at the bottom of the dialog → returns the hardcoded default for that status (the values from the spec table above, e.g. `#4A6B52` for default). The caller saves whatever's returned, so this resets the saved value.

The Reset button is added only at the dialog level (`showColorSwatchPicker`). The inline `ColorSwatchGrid` widget used in the per-client form (Section 5) does NOT have a Reset button — there, the "Automatique" radio toggle serves the same role.

## 5. Per-client color override

### New section on `ClientFormScreen`

A 4th `AppSectionCard`, inserted after **Tonte**:

- Icon: `FIcons.palette` (acceptable to reuse — context is different)
- Title: "Couleur sur la carte"

Body: a Column with two radio-like rows, then conditionally a swatch grid.

### Two-mode toggle

Two `AppListTile`s, exclusive:

```
●  Automatique (selon statut)        ← _markerColorHex == null
○  Personnalisée                      ← _markerColorHex != null
```

`prefix` for each is `Icon(FIcons.circle)` (deselected) or `Icon(FIcons.circleCheck, color: theme.colors.primary)` (selected).

Tapping "Automatique" → `_markerColorHex = null`.
Tapping "Personnalisée" → `_markerColorHex = currentDefault` (compute the auto-color for the current status).

### Inline swatch grid

When "Personnalisée" is active, show a `ColorSwatchGrid` widget below the toggle. Same 16 swatches as the picker dialog, but rendered inline (no dialog). Tapping a swatch updates `_markerColorHex` to its hex.

`ColorSwatchGrid` is exposed as a separate widget in `color_swatch_picker.dart`:

```dart
class ColorSwatchGrid extends StatelessWidget {
  final Color current;
  final ValueChanged<Color> onPicked;
  const ColorSwatchGrid({super.key, required this.current, required this.onPicked});
}
```

The picker dialog (`showColorSwatchPicker`) wraps this grid in an `FDialog` shell.

### Live preview

To the right of the toggle (or above the grid), a small preview pin:

```dart
Icon(FIcons.mapPin, color: _resolvedFormColor, size: 32)
```

`_resolvedFormColor` is computed from `_markerColorHex` (if set) or the auto-color based on what the form's status would be. Visual feedback so the user sees the chosen color rendered as it would be on the map.

### Saving

The `_submit()` method of `ClientFormScreen` calls a new repository method:

```dart
Future<void> ClientRepository.setMarkerColor(int id, String? hex);
```

`null` clears the override (back to automatic). Called after the existing `updateBasics` / `updateAddress` flow. Insert path also handles the new field via the existing `insert()` method (extended to accept the optional override).

### Spec validation

No validation needed. Only valid swatches are tappable, and `null` is always valid (= automatic).

## Implementation strategy

### Phasing (5 sub-phases)

| # | Phase | Delivers |
|---|---|---|
| **M1** | Domain & DB | `ClientStatus` enum + extension, `resolvedColor`, drift schema bump v3, `Settings` and `Client` model updates, migration, repository methods |
| **M2** | Color swatch picker widget | `ColorSwatchGrid` + `showColorSwatchPicker` + the 16-swatch palette constant |
| **M3** | Settings color section | New `AppSectionCard` with 4 `AppListTile`s, dialog wiring, reset behavior |
| **M4** | Map screen + bottom nav | New `/map` route, `MapScreen` widget, search bar, layers panel, recenter button, base + client markers, state providers, `client_actions.dart` extraction |
| **M5** | Mini-popup + per-client override | `ClientPinPopup` widget, popup state on map, per-client section in `ClientFormScreen` |

ETA: ~2-3 days of focused work.

### File changes summary

```
lib/
  domain/
    models/
      client.dart                            (M1) MODIFY: add markerColorHex field
      settings.dart                          (M1) MODIFY: add 4 marker color fields
    use_cases/
      client_status.dart                     (M1) NEW: ClientStatus enum + extensions
  infra/db/
    tables.dart                              (M1) MODIFY: add columns
    app_database.dart                        (M1) MODIFY: bump schemaVersion + migration
  data/repositories/
    settings_repository.dart                 (M1, M3) MODIFY: read/write color fields, updateMarkerColor()
    client_repository.dart                   (M1, M5) MODIFY: read/write markerColorHex, setMarkerColor()
  state/
    map_controller.dart                      (M4) NEW: 3 providers
  core/
    routing/
      app_router.dart                        (M4) MODIFY: add /map branch
  presentation/
    widgets/
      color_swatch_picker.dart               (M2) NEW: showColorSwatchPicker, ColorSwatchGrid
    settings/
      settings_screen.dart                   (M3) MODIFY: add color section
    clients/
      client_actions.dart                    (M4) NEW: extracted call/sms helpers
      client_detail_screen.dart              (M4) MODIFY: import helpers from client_actions.dart
      client_form_screen.dart                (M5) MODIFY: add color override section
    map/
      map_screen.dart                        (M4) NEW: main screen
      client_pin_popup.dart                  (M5) NEW: anchored popup widget
test/
  domain/
    client_status_test.dart                  (M1) NEW: unit tests for status priority
  data/
    settings_repository_test.dart            (M1, M3) MODIFY: cover marker color round-trips
    client_repository_test.dart              (M1, M5) MODIFY: cover markerColorHex round-trip
```

### Verification

- All existing tests stay green (54+).
- New unit tests for `ClientStatus` priority resolution (covering combinations).
- New repository tests for the round-trip of marker color fields.
- Manual smoke on device: navigate to Carte tab → see all clients → tap pin → see popup → tap Appeler / SMS → verify intent → tap chevron → verify navigation.
- Manual smoke: edit a marker color in Settings → verify the map and the lists rerender with new color.
- Manual smoke: edit a client's per-client color → verify only that pin changes, others still follow Settings.

### Out-of-scope (deferred)

- Marker clustering.
- Heatmap layer.
- Drawing planned tour routes on the map.
- Persisting layer visibility between sessions.
- Free-form HEX/HSV color picker beyond the predefined palette.
- Refactoring proximity_map_view to share the marker widget.

### Compatibility

- Schema v2 → v3 migration is purely additive (new columns with defaults). Existing data survives.
- The existing screens (Clients list, Tours list, etc.) continue to use `AppBadge` for status indicators. They could be tinted with the customized colors in a follow-up — out of scope for now.
- The `proximity_map_view` retains its existing behavior — it has different needs (multi-selection, no popup) and refactoring is YAGNI.
