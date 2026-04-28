# Phase 11 — Polish + release

**Goal:** French strings reviewed, empty states + badges everywhere, manual smoke checklist run, signed release APK built and installed on the user's phone.

**Verification at end of phase:** A signed APK runs on the user's Android phone, walks through the full happy path, and survives an export/reinstall/import cycle.

---

## Task 11.1: French strings audit

**Files:**
- Modify: `lib/l10n/app_fr.arb`

- [ ] **Step 1: Inventory**

```bash
grep -E "^\s*\".+\":" lib/l10n/app_fr.arb | wc -l
```
Take note of the count.

- [ ] **Step 2: Hard-coded strings sweep**

```bash
grep -rn "Text('" lib/presentation lib/core/routing 2>/dev/null
```

Every hard-coded `Text('Foo')` (other than debug/dev placeholders) should be moved to ARB. Pick the most important ones (visible on common screens) and migrate. Don't bother with `Text('${...}')` interpolations of variables — those are fine.

- [ ] **Step 3: Tone check**

Read each French string aloud. They should sound natural (formal but not stiff: "Enregistrer", "Annuler", "Composer la tournée"). Fix awkward phrasings.

- [ ] **Step 4: Date/time formatting**

Verify that all `DateFormat(...).format(...)` calls pass `'fr'` as the locale to render French day/month names. Ensure `intl` initialisation is done — Flutter's `flutter_localizations` package handles it once `MaterialApp.localizationsDelegates` is set up.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_fr.arb lib/l10n/app_en.arb
git commit -m "chore(l10n): polish french strings"
```

---

## Task 11.2: Empty states + overdue badge

**Files:**
- Modify: `lib/presentation/clients/clients_list_screen.dart`

- [ ] **Step 1: Overdue badge in client tiles**

In `_ClientTile`, before the existing chips:

```dart
if (client.lastShearingDate != null &&
    DateTime.now().difference(client.lastShearingDate!).inDays > 395)
  const Chip(
    label: Text('En retard'),
    visualDensity: VisualDensity.compact,
    backgroundColor: Color(0xFFFFCDD2),
  ),
```

- [ ] **Step 2: Long day badge in tour detail / draft**

In `tour_detail_screen.dart` (and similarly in `tour_draft_screen.dart`), if the tour ends after 20:00 minutes:

```dart
if (bundle.tour.startTimeMinutes +
        (bundle.tour.totalDriveSeconds ~/ 60) +
        bundle.stops.fold<int>(0, (sum, s) =>
            sum + s.sheepCountSnapshot * s.minutesPerSheepSnapshot) >
    20 * 60)
  const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Chip(
      label: Text('Journée longue'),
      backgroundColor: Color(0xFFFFE0B2),
    ),
  ),
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/
git commit -m "feat(ui): overdue + long day badges"
```

---

## Task 11.3: Run the full manual smoke checklist

> Document each step's result in a comment line below as you do it.

- [ ] Set base address from onboarding.
- [ ] Add 3 clients in different communes (real coordinates, no errors).
- [ ] Verify matrix is populated (no recompute banners).
- [ ] Toggle 2 of them as waiting.
- [ ] Run a proximity search around the third → list shows 2 results, sorted by distance; map shows pins.
- [ ] Select both, compose a tour, optimise, drag-reorder, confirm.
- [ ] Tour appears in tours list as "Planifiée".
- [ ] Open tour detail; verify schedule, fee split, totals.
- [ ] Tap "Marquer comme réalisée" → confirm → status changes to "Réalisée"; the two clients are no longer waiting; their last-shearing date is today.
- [ ] Tap Share → Android share sheet shows the recap text.
- [ ] Switch device to airplane mode → app keeps working for read-only operations.
- [ ] Try to add a new client offline → save error / banner; client created with recompute pending.
- [ ] Re-enable network → tap "Recalculer" banner → recompute succeeds.
- [ ] Export → reinstall app → import → verify integrity.

If any step fails, file an issue, fix it, re-test.

---

## Task 11.4: Build signed release APK

**Files:**
- Create: `android/key.properties` (gitignored, see `.gitignore` in Phase 0)
- Modify: `android/app/build.gradle.kts`

- [ ] **Step 1: Generate a keystore (one-time)**

```bash
keytool -genkey -v -keystore $HOME/coupe-laine-upload.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- [ ] **Step 2: Create `android/key.properties`**

```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/c/Users/rapha/coupe-laine-upload.keystore
```

- [ ] **Step 3: Wire signing in `android/app/build.gradle.kts`**

Above the `android { ... }` block:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Inside `android { ... }`, after `defaultConfig { ... }`:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String?
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = false
    }
}
```

- [ ] **Step 4: Build the APK**

```bash
flutter build apk --release
```

Expected: `build/app/outputs/flutter-apk/app-release.apk` is produced.

- [ ] **Step 5: Install on the device**

```bash
flutter install -d <android>
```

Or transfer the APK manually and side-load via Android.

- [ ] **Step 6: Commit configuration (without secrets)**

```bash
git add android/app/build.gradle.kts android/build.gradle.kts
git commit -m "chore(android): wire release signing"
```

> `android/key.properties` and the keystore stay out of git per `.gitignore`.

---

## Task 11.5: Tag the MVP

- [ ] **Step 1: Tag**

```bash
git tag -a v0.1.0 -m "MVP — Coupe-Laine"
```

- [ ] **Step 2: Final test sweep**

```bash
flutter test
```

Expected: all green.

---

**Phase 11 done. MVP shipped.** Future iterations: cloud sync (Supabase), iOS build, CSV import, drawn route polylines, push notifications for upcoming tours, multi-day planning view.
