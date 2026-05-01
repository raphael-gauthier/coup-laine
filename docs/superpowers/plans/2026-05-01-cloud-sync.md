# Synchronisation cloud Phase 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implémenter la feature #1 du TODO (synchronisation cloud Phase 1) définie dans `docs/superpowers/specs/2026-05-01-cloud-sync-design.md`. Backup/restore mono-device de toute la base Drift vers Supabase Storage, avec auth magic link et historique 3 jours. Inclut la migration de `ORS_API_KEY` vers une Edge Function proxy (résolution dette `project_ors_key_prod_migration` mémoire).

**Architecture:** Pipeline en 10 phases. Phase A : provisioning Supabase (manuel, hors-code). Phase B : correction du bug latent `JsonExportService` (4 tables manquantes). Phase C : migration Drift v13→v14 + transition wipe-and-recreate → incrémental. Phase D : bootstrap Supabase côté app (deps, env, main). Phase E : cutover ORS proxy. Phase F : couche auth + sessions anonymes. Phase G : couche backup (repository + service + scheduler). Phase H : UI Réglages compte cloud. Phase I : UI onboarding restore. Phase J : cleanup final.

**Tech Stack:** Flutter 3.x, Riverpod, Drift (SQLite), `forui` UI library, `supabase_flutter` (~2.x), `archive` package pour gzip. Edge Function en Deno/TypeScript. Tests : `flutter_test` avec `drift/native` in-memory pour les repos, mocks `mocktail` pour les services Supabase. Convention de commit : `type(scope): message` (ex. `feat(cloud): ...`, `fix(export): ...`, `chore(deps): ...`).

**Conventions du codebase à respecter (rappel des plans précédents) :**
- Models : pure dataclasses (pas de freezed), constructeurs `const`, `==`/`hashCode` manuels seulement quand utilisé en équivalence.
- Repos : signature `Future<T> method(...)`, retour `_toDomain(row)`. Inserts via Companion. Transactions via `_db.transaction`.
- Tests repos : `setUp` ouvre `AppDatabase.forTesting(NativeDatabase.memory())`, `tearDown` close.
- Tests use cases : pas de DB, instanciation directe.
- Drift codegen : `dart run build_runner build --delete-conflicting-outputs`.
- l10n : `lib/l10n/app_fr.arb` + `app_en.arb` synchronisés. Régénération auto via `flutter gen-l10n`.
- Cloud-spécifique : tout le code Supabase vit sous `lib/infra/cloud/`. Les types domain (`AuthSession`, `BackupMeta`, etc.) restent dans `lib/domain/models/`.

---

## Phase A — Provisioning Supabase (manuel)

### Task 1: Provisionner le projet Supabase et configurer les secrets

**Cette task est manuelle** : elle produit les valeurs `supabaseUrl`, `supabaseAnonKey` et le secret `ORS_API_KEY` côté serveur. Aucun code dans cette task — juste une checklist à exécuter sur le dashboard Supabase et avec la CLI `supabase`.

- [ ] **Step 1: Créer un projet Supabase**

Dashboard : `https://supabase.com/dashboard/projects` → New project.
- Name : `coup-laine` (ou similaire).
- Database password : généré et stocké dans un password manager (jamais commité).
- Region : `eu-west-3` (Paris).
- Plan : Free.

Noter l'URL projet (`https://{projectId}.supabase.co`) et la clé anonyme (`Project Settings → API → anon public`).

- [ ] **Step 2: Activer les sign-ins anonymes**

Dashboard → Authentication → Providers → Email : laisser activé.
Dashboard → Authentication → Providers → "Anonymous Sign-Ins" → Toggle ON.

- [ ] **Step 3: Configurer le redirect URL pour le deep-link magic link**

Dashboard → Authentication → URL Configuration :
- Site URL : `coupelaine://auth/callback`
- Additional Redirect URLs : `coupelaine://auth/callback`

- [ ] **Step 4: Personnaliser le template email magic link en français**

Dashboard → Authentication → Email Templates → Magic Link :
- Subject : `Connexion à Coup'Laine`
- Body (HTML) : adapter le template par défaut, traduire en français. Le placeholder `{{ .ConfirmationURL }}` doit rester intact.

- [ ] **Step 5: Créer la table `backups` et ses RLS policies**

Dashboard → SQL Editor → New query → coller et exécuter :

```sql
create table public.backups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  created_at timestamptz not null default now(),
  schema_version int not null,
  size_bytes int not null
);

create index backups_user_created_idx on public.backups (user_id, created_at desc);

alter table public.backups enable row level security;

create policy "users see own backups"
  on public.backups for select
  using (auth.uid() = user_id);

create policy "users insert own backups"
  on public.backups for insert
  with check (auth.uid() = user_id);

create policy "users delete own backups"
  on public.backups for delete
  using (auth.uid() = user_id);
```

Vérifier dans Table Editor : table `backups` visible avec RLS activé.

- [ ] **Step 6: Créer le bucket Storage `backups` et ses policies**

Dashboard → Storage → New bucket :
- Name : `backups`
- Public : OFF (privé)

Puis SQL Editor :

```sql
create policy "users upload own backups"
  on storage.objects for insert
  with check (
    bucket_id = 'backups'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "users read own backups"
  on storage.objects for select
  using (
    bucket_id = 'backups'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "users delete own backups"
  on storage.objects for delete
  using (
    bucket_id = 'backups'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
```

- [ ] **Step 7: Installer la CLI Supabase localement et linker le projet**

```bash
npm install -g supabase  # ou : brew install supabase/tap/supabase
supabase login
cd C:/Users/rapha/Documents/Development/coupe-laine
supabase init
supabase link --project-ref {projectId}
```

`{projectId}` = la partie devant `.supabase.co` dans l'URL projet.

- [ ] **Step 8: Configurer le secret `ORS_API_KEY` côté Supabase**

Récupérer la valeur actuelle de `ORS_API_KEY` dans `.env` (existant), puis :

```bash
supabase secrets set ORS_API_KEY=<valeur-actuelle>
```

Vérifier : `supabase secrets list` → `ORS_API_KEY` présent.

- [ ] **Step 9: Documenter les valeurs récupérées**

Créer un fichier local **non commité** `cloud-creds.local.txt` (à ajouter à `.gitignore` si pas déjà couvert par `*.local.*`) contenant :

```
SUPABASE_URL=https://{projectId}.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...
```

Ces valeurs seront hardcodées dans `lib/core/config/env.dart` à la Task 9.

- [ ] **Step 10: Pas de commit pour cette task**

Aucun fichier de code modifié. Cette task documente l'état "Supabase provisionné, secrets en place, CLI prête". On peut écrire un commit vide pour matérialiser le passage de phase :

```bash
git commit --allow-empty -m "chore(cloud): provision Supabase project (eu-west-3) + ORS_API_KEY secret"
```

---

## Phase B — Bug fix : compléter `JsonExportService`

### Task 2: Étendre `JsonExportService` aux 4 tables manquantes (export)

**Files:**
- Modify: `lib/infra/services/json_export_service.dart`

**Contexte** : le service couvre actuellement `settings, clients, distance_matrix, tours, tour_stops`. Il manque `species, animal_categories, prestations, manual_history_entries` (cf. spec §10). Cette task gère l'**export** ; la Task 3 gère l'**import** ; la Task 4 ajoute les tests.

- [ ] **Step 1: Ajouter les imports nécessaires**

Dans `lib/infra/services/json_export_service.dart`, ajouter en tête de fichier les imports manquants :

```dart
import '../../data/repositories/animal_category_repository.dart';
import '../../data/repositories/manual_history_repository.dart';
import '../../data/repositories/prestation_repository.dart';
import '../../data/repositories/species_repository.dart';
```

(Selon le code existant, certains imports peuvent déjà être présents — ne pas dupliquer.)

- [ ] **Step 2: Bumper `schemaVersion` 1 → 2**

```dart
class JsonExportService {
  static const int schemaVersion = 2;  // était 1 — bump pour les 4 tables ajoutées
  // ...
}
```

- [ ] **Step 3: Ajouter les selects et le payload d'export**

Modifier `exportToJsonString()` :

```dart
Future<String> exportToJsonString() async {
  final s = await database.select(database.settingsTable).getSingleOrNull();
  final cs = await database.select(database.clientsTable).get();
  final dm = await database.select(database.distanceMatrixTable).get();
  final ts = await database.select(database.toursTable).get();
  final stops = await database.select(database.tourStopsTable).get();
  final sp = await database.select(database.speciesTable).get();
  final ac = await database.select(database.animalCategoriesTable).get();
  final pr = await database.select(database.prestationsTable).get();
  final mh = await database.select(database.manualHistoryEntriesTable).get();
  return jsonEncode({
    'schema': schemaVersion,
    'settings': s?.toJson(),
    'clients': cs.map((r) => r.toJson()).toList(),
    'distanceMatrix': dm.map((r) => r.toJson()).toList(),
    'tours': ts.map((r) => r.toJson()).toList(),
    'tourStops': stops.map((r) => r.toJson()).toList(),
    'species': sp.map((r) => r.toJson()).toList(),
    'animalCategories': ac.map((r) => r.toJson()).toList(),
    'prestations': pr.map((r) => r.toJson()).toList(),
    'manualHistoryEntries': mh.map((r) => r.toJson()).toList(),
  });
}
```

- [ ] **Step 4: Compiler en TDD-light (vérifier pas de build break)**

```bash
cd C:/Users/rapha/Documents/Development/coupe-laine
flutter analyze
```

Expected : pas de nouvelle erreur. Si une table n'a pas de `toJson()` exposé sur sa Row class, vérifier dans `lib/infra/db/app_database.g.dart` qu'elle en a bien un (Drift le génère par défaut).

- [ ] **Step 5: Pas de commit isolé** — la Task 3 enchaîne sur le même fichier, on commit une fois les deux faites.

---

### Task 3: Compléter `JsonExportService` côté import (4 tables)

**Files:**
- Modify: `lib/infra/services/json_export_service.dart`

- [ ] **Step 1: Ajouter les `delete` dans le bon ordre FK**

Dans `importFromJsonString`, modifier la section `// wipe`. **Ordre critique** (FK descendantes — `manual_history_entries` et `prestations` référencent `animal_categories` qui référence `species`) :

```dart
await database.transaction(() async {
  // wipe — ordre important pour respecter les FK cascade
  await database.delete(database.tourStopsTable).go();
  await database.delete(database.toursTable).go();
  await database.delete(database.distanceMatrixTable).go();
  await database.delete(database.manualHistoryEntriesTable).go();
  await database.delete(database.prestationsTable).go();
  await database.delete(database.animalCategoriesTable).go();
  await database.delete(database.speciesTable).go();
  await database.delete(database.clientsTable).go();
  await database.delete(database.settingsTable).go();
  // ... la suite (inserts) après
});
```

- [ ] **Step 2: Ajouter les `insert` dans l'ordre FK ascendant**

Toujours dans la transaction, après les inserts existants (`settings → clients → distanceMatrix → tours → tourStops`), ajouter avant ou en respectant les dépendances :

**Nouvel ordre complet** (FK ascendantes) :
1. `settings` (existant)
2. `clients` (existant)
3. `species` (NOUVEAU)
4. `animalCategories` (NOUVEAU — dépend de species)
5. `prestations` (NOUVEAU — dépend de animalCategories)
6. `distanceMatrix` (existant)
7. `tours` (existant)
8. `tourStops` (existant)
9. `manualHistoryEntries` (NOUVEAU — dépend de clients + référence catégories via snapshots)

Code à insérer (après le bloc `clients`, avant `distanceMatrix`) :

```dart
for (final s in (json['species'] as List? ?? [])) {
  await database.into(database.speciesTable).insert(
        SpeciesRow.fromJson(s as Map<String, dynamic>),
        mode: InsertMode.insertOrReplace,
      );
}
for (final ac in (json['animalCategories'] as List? ?? [])) {
  await database.into(database.animalCategoriesTable).insert(
        AnimalCategoryRow.fromJson(ac as Map<String, dynamic>),
        mode: InsertMode.insertOrReplace,
      );
}
for (final pr in (json['prestations'] as List? ?? [])) {
  await database.into(database.prestationsTable).insert(
        PrestationRow.fromJson(pr as Map<String, dynamic>),
        mode: InsertMode.insertOrReplace,
      );
}
```

Et après le bloc `tourStops` (puisque `manual_history_entries` n'a pas de FK vers tours mais bien vers clients qui sont déjà insérés ; on le met après pour rester cohérent avec l'ordre logique d'apparition) :

```dart
for (final mh in (json['manualHistoryEntries'] as List? ?? [])) {
  final row = Map<String, dynamic>.from(mh as Map<String, dynamic>);
  if (row['prestations'] is List) {
    row['prestations'] =
        _coerceTourStopPrestations(row['prestations'] as List);
  }
  await database.into(database.manualHistoryEntriesTable).insert(
        ManualHistoryEntryRow.fromJson(row),
        mode: InsertMode.insertOrReplace,
      );
}
```

Note : `manualHistoryEntries.prestations` utilise le même converter `TourStopPrestationListConverter` que `tour_stops` — on réutilise donc `_coerceTourStopPrestations`.

- [ ] **Step 3: Élargir la validation de schéma — accepter v1 et v2**

```dart
final schema = json['schema'];
if (schema is! int || schema > schemaVersion) {
  throw JsonImportException(
    'Sauvegarde au format v$schema, non supportée (max v$schemaVersion).',
  );
}
// schema < schemaVersion : accepté en lecture (forward compat —
// les `?? []` au-dessus gèrent l'absence des nouvelles clés).
```

- [ ] **Step 4: Vérifier la compilation**

```bash
flutter analyze
```

Expected : 0 erreurs, 0 warnings nouveaux.

- [ ] **Step 5: Commit (Tasks 2 + 3 ensemble)**

```bash
git add lib/infra/services/json_export_service.dart
git commit -m "fix(export): include species/categories/prestations/manual-history in JsonExportService

Le service couvrait 5 tables sur 9. Les 4 manquantes (species, animal_categories,
prestations, manual_history_entries) ajoutées par les pivots récents n'étaient
pas exportées/importées — un export/import perdait toutes les définitions
d'espèces, catégories, catalogue prestations et historique manuel.

Schema bump v1→v2. Forward-compat : les v1 (théoriques, jamais produites en
prod fonctionnelle) restent lisibles via fallback sur listes vides."
```

---

### Task 4: Tests pour `JsonExportService` étendu

**Files:**
- Test: `test/infra/json_export_service_test.dart` (probablement existant — vérifier)
- Test alternatif si pas existant : Create

- [ ] **Step 1: Localiser le fichier de test existant**

```bash
ls test/infra/
```

Si `json_export_service_test.dart` existe, l'éditer. Sinon, le créer.

- [ ] **Step 2: Écrire les tests round-trip pour les 4 tables**

Modèle de test (à adapter selon le pattern présent dans le fichier s'il existe) :

```dart
// test/infra/json_export_service_test.dart
import 'dart:convert';

import 'package:coup_laine/data/repositories/client_repository.dart';
import 'package:coup_laine/data/repositories/distance_matrix_repository.dart';
import 'package:coup_laine/data/repositories/settings_repository.dart';
import 'package:coup_laine/data/repositories/tour_repository.dart';
import 'package:coup_laine/infra/db/app_database.dart';
import 'package:coup_laine/infra/services/json_export_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late JsonExportService svc;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    svc = JsonExportService(
      database: db,
      settings: SettingsRepository(db),
      clients: ClientRepository(db),
      matrix: DistanceMatrixRepository(db),
      tours: TourRepository(db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('round-trip — 4 tables ajoutées', () {
    test('species : round-trip préserve nom/iconKey/archivedAt', () async {
      // Arrange : insérer 2 species (1 active, 1 archivée)
      // ...via SpeciesRepository ou insert direct.
      // Act : export → wipe → import → relire.
      // Assert : les 2 species sont identiques.
    });

    test('animal_categories : round-trip préserve speciesId + name', () async {
      // ...
    });

    test('prestations : round-trip préserve priceCents/minutes/categoryId', () async {
      // ...
    });

    test('manual_history_entries : round-trip préserve prestations snapshot', () async {
      // Doit vérifier que la List<TourStopPrestation> dans `prestations` est
      // bien désérialisée (categoryNameSnapshot etc. préservés).
    });
  });

  group('round-trip complet', () {
    test('toutes les tables peuplées sont préservées après export+import', () async {
      // Setup : peupler toutes les 9 tables.
      // export → vider DB → import → vérifier toutes les tables.
    });
  });

  group('schema versioning', () {
    test('refuse un schema futur (>schemaVersion)', () async {
      final body = jsonEncode({'schema': 99, 'settings': null, 'clients': []});
      expect(
        () => svc.importFromJsonString(body),
        throwsA(isA<JsonImportException>()),
      );
    });

    test('accepte un schema passé (forward compat)', () async {
      // Construire un body avec schema=1 (sans species/animalCategories/etc.)
      final body = jsonEncode({
        'schema': 1,
        'settings': null,
        'clients': [],
        'distanceMatrix': [],
        'tours': [],
        'tourStops': [],
      });
      // Ne doit pas throw
      await svc.importFromJsonString(body);
    });
  });
}
```

**Important** : peupler les rows via les Repositories existants (pas en raw SQL) pour garantir que les converters (PhoneListConverter, TourStopPrestationListConverter, AnimalCountListConverter) sont exercés. Les détails d'arrangement (création d'un client, d'une species, d'une categorie, d'une prestation, d'un manual history) sont des appels standards aux repos déjà testés.

- [ ] **Step 3: Lancer les tests**

```bash
flutter test test/infra/json_export_service_test.dart
```

Expected : tous verts.

- [ ] **Step 4: Commit**

```bash
git add test/infra/json_export_service_test.dart
git commit -m "test(export): round-trip coverage for the 4 added tables + schema versioning"
```

---

## Phase C — Migration Drift v13 → v14

### Task 5: Ajouter `lastBackupAt` à `SettingsTable`

**Files:**
- Modify: `lib/infra/db/tables.dart`
- Modify: `lib/domain/models/settings.dart`
- Modify: `lib/data/repositories/settings_repository.dart`
- Regenerate: `lib/infra/db/app_database.g.dart` (via build_runner)

- [ ] **Step 1: Ajouter la colonne dans `SettingsTable`**

Dans `lib/infra/db/tables.dart`, dans `class SettingsTable`, après les colonnes existantes (avant `primaryKey`) :

```dart
@DataClassName('SettingsRow')
class SettingsTable extends Table {
  // ... colonnes existantes ...
  IntColumn get seasonStartedAt => integer().withDefault(const Constant(0))();
  IntColumn get lastBackupAt => integer().nullable()();  // epoch ms, null = jamais sauvegardé sur cloud

  @override
  Set<Column<Object>> get primaryKey => {id};
}
```

- [ ] **Step 2: Regénérer le code Drift**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected : `app_database.g.dart` régénéré, contient `lastBackupAt` dans `SettingsRow` et `SettingsTableCompanion`.

- [ ] **Step 3: Ajouter le champ dans le model domain `Settings`**

Dans `lib/domain/models/settings.dart`, ajouter :

```dart
class Settings {
  // ... champs existants ...
  final DateTime? lastBackupAt;

  const Settings({
    // ... params existants ...
    this.lastBackupAt,
  });

  Settings copyWith({
    // ... params existants ...
    DateTime? lastBackupAt,
    bool clearLastBackupAt = false,
  }) {
    return Settings(
      // ... champs existants copiés ...
      lastBackupAt: clearLastBackupAt ? null : (lastBackupAt ?? this.lastBackupAt),
    );
  }
}
```

Note : le pattern `clearLastBackupAt: bool` permet de remettre à null explicitement, comme c'est fait pour les autres champs nullable du codebase.

- [ ] **Step 4: Mettre à jour `SettingsRepository`**

Dans `lib/data/repositories/settings_repository.dart`, méthode `read()` :

```dart
return Settings(
  // ... champs existants ...
  seasonStartedAt: DateTime.fromMillisecondsSinceEpoch(row.seasonStartedAt),
  lastBackupAt: row.lastBackupAt == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(row.lastBackupAt!),
);
```

Méthode `save()` :

```dart
SettingsTableCompanion.insert(
  // ... params existants ...
  seasonStartedAt: Value(settings.seasonStartedAt.millisecondsSinceEpoch),
  lastBackupAt: Value(settings.lastBackupAt?.millisecondsSinceEpoch),
)
```

Ajouter une méthode dédiée pour mise à jour ciblée (évite de relire/réécrire toutes les settings) :

```dart
Future<void> setLastBackupAt(DateTime timestamp) async {
  await (_db.update(_db.settingsTable)..where((t) => t.id.equals(1))).write(
    SettingsTableCompanion(
      lastBackupAt: Value(timestamp.millisecondsSinceEpoch),
    ),
  );
}
```

- [ ] **Step 5: Vérifier la compilation**

```bash
flutter analyze
```

Expected : pas d'erreur. Si `Settings` est utilisé dans des tests ou des constructeurs avec arguments positionnels, ils restent compatibles (le nouveau champ est nommé et nullable).

- [ ] **Step 6: Pas de commit isolé** — la Task 6 enchaîne sur le schema, on commit ensemble.

---

### Task 6: Bumper `schemaVersion` 13 → 14 et passer en migration incrémentale

**Files:**
- Modify: `lib/infra/db/app_database.dart`

**Contexte** : la stratégie actuelle wipe-and-recreate était acceptable sans utilisateurs en prod. Avec la cloud sync, on transitionne vers des migrations incrémentales pour préserver les données utilisateurs (cf. spec §7.1).

- [ ] **Step 1: Modifier `schemaVersion` et la stratégie de migration**

Dans `lib/infra/db/app_database.dart` :

```dart
@override
int get schemaVersion => 14;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 13) {
      // Branche legacy pré-prod : wipe-and-recreate. Conservée pour
      // gérer les éventuels installs de dev encore en v < 13.
      for (final table in allTables.toList().reversed) {
        await m.deleteTable(table.actualTableName);
      }
      await m.createAll();
      return;
    }
    if (from < 14) {
      // v13 → v14 : ajout de Settings.lastBackupAt.
      // Migration incrémentale — préserve les données utilisateur.
      await m.addColumn(settingsTable, settingsTable.lastBackupAt);
    }
  },
  beforeOpen: (details) async {
    await customStatement('PRAGMA foreign_keys = ON');
  },
);
```

- [ ] **Step 2: Vérifier la compilation**

```bash
flutter analyze
```

- [ ] **Step 3: Test de migration (TDD)**

**Files:**
- Create: `test/infra/db/migration_v13_to_v14_test.dart`

Drift fournit `SchemaVerifier` mais sa mise en place demande un dossier `drift_schemas/` versionné. Pour cette spec, on fait un test simple via l'API de migration directe :

```dart
// test/infra/db/migration_v13_to_v14_test.dart
import 'package:coup_laine/infra/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v14 schema includes lastBackupAt nullable column', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    // Insérer des settings sans lastBackupAt — doit fonctionner.
    await db.into(db.settingsTable).insert(
          SettingsTableCompanion.insert(
            id: const Value(1),
            baseAddressLabel: 'Test',
            baseLat: 0.0,
            baseLon: 0.0,
          ),
        );
    final row = await db.select(db.settingsTable).getSingle();
    expect(row.lastBackupAt, isNull);

    // Mise à jour avec une valeur.
    await db.update(db.settingsTable).write(
          const SettingsTableCompanion(lastBackupAt: Value(1234567890)),
        );
    final updated = await db.select(db.settingsTable).getSingle();
    expect(updated.lastBackupAt, 1234567890);

    await db.close();
  });
}
```

- [ ] **Step 4: Lancer le test**

```bash
flutter test test/infra/db/migration_v13_to_v14_test.dart
```

Expected : vert.

- [ ] **Step 5: Commit (Tasks 5 + 6 ensemble)**

```bash
git add lib/infra/db/tables.dart lib/infra/db/app_database.dart lib/infra/db/app_database.g.dart \
        lib/domain/models/settings.dart lib/data/repositories/settings_repository.dart \
        test/infra/db/migration_v13_to_v14_test.dart
git commit -m "feat(db): add Settings.lastBackupAt + switch to incremental migrations (v13→v14)

Schema bump pour la cloud sync : tracking du dernier backup réussi.
Stratégie de migration passe de wipe-and-recreate (acceptable sans utilisateurs
prod) à incrémentale via addColumn — nécessaire dès la sortie de cloud sync."
```

---

## Phase D — Bootstrap Supabase côté app

### Task 7: Mettre à jour `pubspec.yaml` (dépendances + assets)

**Files:**
- Modify: `pubspec.yaml`
- Delete: `.env` (à la fin de la Task 17 — pour l'instant on retire seulement le déclarant asset)

- [ ] **Step 1: Ajouter `supabase_flutter` et `archive`**

Dans `pubspec.yaml`, section `dependencies`, ajouter (alphabétique) :

```yaml
dependencies:
  archive: ^4.0.0
  collection: ^1.19.1
  drift: ^2.32.1
  file_selector: ^1.1.0
  flutter:
    sdk: flutter
  # flutter_dotenv: ^6.0.1   # ← retiré, voir étape 2
  flutter_localizations:
    sdk: flutter
  flutter_map: ^8.3.0
  flutter_riverpod: ^3.3.1
  flutter_svg: ^2.2.4
  forui: ^0.21.3
  go_router: ^17.2.2
  http: ^1.6.0
  intl: ^0.20.2
  latlong2: ^0.9.1
  path: ^1.9.1
  path_provider: ^2.1.5
  sqlite3_flutter_libs: ^0.6.0+eol
  supabase_flutter: ^2.8.0
  url_launcher: ^6.3.2
  uuid: ^4.5.3
```

- [ ] **Step 2: Retirer `flutter_dotenv`**

Supprimer la ligne `flutter_dotenv: ^6.0.1`.

- [ ] **Step 3: Retirer `.env` de la liste des assets**

Section `flutter.assets`, supprimer la ligne `- .env` :

```yaml
flutter:
  uses-material-design: true
  generate: true
  assets:
    # - .env     ← retiré
    - assets/illustrations/
    - assets/icons/
```

- [ ] **Step 4: Récupérer les nouvelles deps**

```bash
flutter pub get
```

Expected : pas d'erreur. Si `flutter_dotenv` est encore référencé dans le code (`Env.load`, `dotenv.maybeGet`, etc.), `flutter analyze` va flag — c'est attendu, on corrige aux Tasks 8-9.

- [ ] **Step 5: Pas de commit isolé** — on commit avec les Tasks 8 et 9 ensemble (le projet doit compiler à chaque commit).

---

### Task 8: Refondre `lib/core/config/env.dart`

**Files:**
- Modify: `lib/core/config/env.dart`

- [ ] **Step 1: Remplacer le contenu complet du fichier**

Remplacer le contenu actuel par :

```dart
/// Configuration globale au build.
///
/// Les valeurs Supabase (URL projet + clé anonyme) sont publiques par design
/// — elles identifient le projet mais ne donnent aucun accès par elles-mêmes.
/// L'accès est gaté par l'auth utilisateur + Row-Level Security.
///
/// Voir `docs/superpowers/specs/2026-05-01-cloud-sync-design.md` §7.3.
class Env {
  Env._();

  /// URL du projet Supabase.
  static const String supabaseUrl = 'https://{projectId}.supabase.co';

  /// Clé anonyme publique du projet Supabase.
  static const String supabaseAnonKey = '{publicAnonKey}';
}
```

- [ ] **Step 2: Renseigner les valeurs réelles**

Remplacer `{projectId}` et `{publicAnonKey}` par les valeurs récupérées à la Task 1, Step 9 (depuis `cloud-creds.local.txt`).

- [ ] **Step 3: Vérifier**

```bash
flutter analyze lib/core/config/env.dart
```

Expected : 0 erreur.

- [ ] **Step 4: Pas de commit isolé** (cf. Task 7).

---

### Task 9: Initialiser Supabase dans `main.dart`

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Remplacer le contenu de `main.dart`**

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [SystemUiOverlay.top],
  );

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // Si pas de session existante (premier lancement, ou sign-out),
  // ouvrir une session anonyme pour permettre les appels à
  // l'Edge Function ors-proxy. Cf. spec §3.1, §6.4.
  final supabase = Supabase.instance.client;
  if (supabase.auth.currentSession == null) {
    try {
      await supabase.auth.signInAnonymously();
    } catch (e) {
      // Si l'anonymous sign-in échoue (réseau hors-ligne au premier lancement,
      // ou config Supabase qui désactive ce mode), on poursuit quand même —
      // l'app reste fonctionnelle en local, ORS échouera et tombera sur
      // le fallback straight-line existant.
      debugPrint('Anonymous sign-in failed: $e');
    }
  }

  final container = ProviderContainer();
  unawaited(container.read(consistencyCheckProvider).run());
  runApp(UncontrolledProviderScope(
    container: container,
    child: const CoupeLaineApp(),
  ));
}
```

- [ ] **Step 2: Vérifier la compilation**

```bash
flutter analyze
```

Expected : 0 erreur. Si `Env.load()` ou `Env.orsApiKey` est référencé ailleurs, ils vont flag — on les corrigera aux Tasks 12-13.

À ce stade, l'app peut compiler **uniquement si rien n'utilise encore `Env.orsApiKey`**. Si c'est le cas (probable dans `providers.dart` qui instancie `OrsRoutingService`), ne pas paniquer — la chaîne d'erreurs sera résolue par les tasks suivantes. Pour cette task, vérifier seulement que `main.dart` lui-même compile.

- [ ] **Step 3: Commit (Tasks 7 + 8 + 9)**

```bash
git add pubspec.yaml pubspec.lock lib/core/config/env.dart lib/main.dart
git commit -m "feat(cloud): bootstrap Supabase + anonymous session

Ajoute supabase_flutter + archive (gzip), retire flutter_dotenv.
URL projet et clé anonyme hardcodées dans Env (publiques par design).
Init Supabase + signInAnonymously au démarrage pour permettre l'appel
à l'Edge Function ors-proxy même sans opt-in cloud."
```

---

### Task 10: Configurer le deep-link `coupelaine://auth/callback`

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist` (si iOS supporté à terme — sinon skip)

**Contexte** : le magic link envoyé par Supabase contient un lien `coupelaine://auth/callback`. L'OS doit savoir que ce schéma cible notre app, sinon le clic sur l'email ne réouvre pas Coup'Laine.

- [ ] **Step 1: Repérer le `MainActivity` dans `AndroidManifest.xml`**

```bash
cat android/app/src/main/AndroidManifest.xml
```

Localiser `<activity android:name=".MainActivity"`.

- [ ] **Step 2: Ajouter un `intent-filter` pour le custom scheme**

À l'intérieur de l'élément `<activity>`, après les autres `<intent-filter>`, ajouter :

```xml
<intent-filter android:autoVerify="false">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="coupelaine" android:host="auth" />
</intent-filter>
```

`android:autoVerify="false"` car ce n'est pas un App Link HTTP — c'est un custom scheme, pas besoin d'AssetLinks.

- [ ] **Step 3: (Optionnel iOS) Ajouter le scheme dans `Info.plist`**

Si le projet a un dossier `ios/`, dans `ios/Runner/Info.plist`, à la racine du dict, avant `</dict>` final :

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>coupelaine</string>
        </array>
    </dict>
</array>
```

- [ ] **Step 4: Smoke test manuel**

```bash
flutter run
```

Une fois l'app lancée sur device/émulateur Android, depuis un autre terminal :

```bash
adb shell am start -W -a android.intent.action.VIEW -d "coupelaine://auth/callback?test=1"
```

Expected : Coup'Laine s'ouvre (pas de browser, pas d'erreur "no app handles this URI"). Le SDK Supabase capture l'URI automatiquement quand il est initialisé.

- [ ] **Step 5: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
# si iOS modifié aussi : git add ios/Runner/Info.plist
git commit -m "feat(cloud): register coupelaine://auth/callback deep-link for Supabase magic link"
```

---

## Phase E — Cutover ORS proxy

### Task 11: Écrire et déployer l'Edge Function `ors-proxy`

**Files:**
- Create: `supabase/functions/ors-proxy/index.ts`

- [ ] **Step 1: Créer la structure de la fonction**

```bash
supabase functions new ors-proxy
```

Cela génère `supabase/functions/ors-proxy/index.ts` avec un template Deno minimal.

- [ ] **Step 2: Remplacer le contenu par le proxy ORS**

```typescript
// supabase/functions/ors-proxy/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

const ORS_BASE = 'https://api.openrouteservice.org';
const ORS_API_KEY = Deno.env.get('ORS_API_KEY');

serve(async (req: Request) => {
  // CORS preflight (le SDK supabase-flutter envoie un OPTIONS d'abord)
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  if (!ORS_API_KEY) {
    return new Response('ORS_API_KEY not configured', { status: 500 });
  }

  // Le path après /ors-proxy/ — ex. "v2/directions/driving-car/geojson",
  // "v2/matrix/driving-car"
  const url = new URL(req.url);
  const subPath = url.pathname.replace(/^\/ors-proxy\/?/, '');
  if (!subPath) {
    return new Response('Missing ORS sub-path', { status: 400 });
  }

  const targetUrl = `${ORS_BASE}/${subPath}`;
  const body = req.method === 'POST' ? await req.text() : undefined;

  let orsResponse: Response;
  try {
    orsResponse = await fetch(targetUrl, {
      method: req.method,
      headers: {
        'Authorization': ORS_API_KEY,
        'Content-Type': 'application/json',
      },
      body,
    });
  } catch (e) {
    return new Response(`Upstream fetch failed: ${e}`, { status: 502 });
  }

  // Relayer la réponse telle quelle (status + body)
  return new Response(await orsResponse.text(), {
    status: orsResponse.status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
});
```

- [ ] **Step 3: Déployer la fonction**

```bash
supabase functions deploy ors-proxy
```

Expected : output « Deployed Function ors-proxy ».

- [ ] **Step 4: Smoke test depuis le terminal**

Récupérer le JWT d'une session anonyme (le plus simple : lancer l'app avec les modifs Tasks 7-9, et récupérer `Supabase.instance.client.auth.currentSession?.accessToken` via un `debugPrint` temporaire).

```bash
curl -X POST 'https://{projectId}.supabase.co/functions/v1/ors-proxy/v2/directions/driving-car/geojson' \
  -H 'Authorization: Bearer <jwt-anon>' \
  -H 'Content-Type: application/json' \
  -d '{"coordinates":[[2.35,48.85],[2.36,48.86]]}'
```

Expected : un GeoJSON ORS valide (status 200) ou une erreur ORS structurée.

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/ors-proxy/index.ts supabase/config.toml
git commit -m "feat(cloud): ors-proxy edge function — keeps ORS_API_KEY server-side"
```

---

### Task 12: Migrer `OrsRoutingService` vers le proxy

**Files:**
- Modify: `lib/infra/services/ors_routing_service.dart`
- Modify: `lib/state/providers.dart`

- [ ] **Step 1: Refactorer `OrsRoutingService` pour utiliser `functions.invoke`**

Remplacer le constructeur et les deux méthodes pour passer par le SDK Supabase :

```dart
// lib/infra/services/ors_routing_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/coordinates.dart';

class OrsException implements Exception {
  final String message;
  final Object? cause;
  OrsException(this.message, [this.cause]);
  @override
  String toString() => 'OrsException: $message';
}

class OrsAuthException extends OrsException {
  OrsAuthException(super.message, [super.cause]);
}

class OrsQuotaException extends OrsException {
  OrsQuotaException(super.message, [super.cause]);
}

class OrsMatrixResult {
  final List<List<int>> distances;
  final List<List<int>> durations;
  const OrsMatrixResult({required this.distances, required this.durations});
}

class OrsRoutingService {
  final SupabaseClient _supabase;

  OrsRoutingService({required SupabaseClient supabase})
      : _supabase = supabase;

  Future<List<Coordinates>> getRouteGeometry({
    required List<Coordinates> waypoints,
  }) async {
    if (waypoints.length < 2) {
      throw ArgumentError('Need at least 2 waypoints to compute a route');
    }
    final body = <String, dynamic>{
      'coordinates': [
        for (final c in waypoints) [c.lon, c.lat],
      ],
    };

    final json = await _invokeOrs(
      'v2/directions/driving-car/geojson',
      body,
    );

    final features = json['features'] as List?;
    if (features == null || features.isEmpty) {
      throw OrsException('Empty features in directions response');
    }
    final geometry = (features.first as Map)['geometry'] as Map?;
    final coords = geometry?['coordinates'] as List?;
    if (coords == null) {
      throw OrsException('Missing coordinates in directions geometry');
    }
    final polyline = <Coordinates>[
      for (final p in coords)
        if (p is List && p.length >= 2)
          Coordinates(
            lat: (p[1] as num).toDouble(),
            lon: (p[0] as num).toDouble(),
          ),
    ];

    // Defensive close-loop (cf. ors-routing-service original — comportement
    // inchangé, copié verbatim).
    if (polyline.isNotEmpty && waypoints.length >= 2) {
      final firstWp = waypoints.first;
      final lastWp = waypoints.last;
      final loopClosed = firstWp.lat == lastWp.lat && firstWp.lon == lastWp.lon;
      if (loopClosed) {
        final endpoint = polyline.last;
        final dLat = (endpoint.lat - lastWp.lat).abs();
        final dLon = (endpoint.lon - lastWp.lon).abs();
        if (dLat > 0.001 || dLon > 0.001) {
          polyline.add(lastWp);
        }
      }
    }

    return polyline;
  }

  Future<OrsMatrixResult> matrix({
    required List<Coordinates> locations,
    List<int>? sources,
    List<int>? destinations,
  }) async {
    final body = <String, dynamic>{
      'locations': [
        for (final c in locations) [c.lon, c.lat],
      ],
      'metrics': ['distance', 'duration'],
    };
    if (sources != null) body['sources'] = sources;
    if (destinations != null) body['destinations'] = destinations;

    final json = await _invokeOrs('v2/matrix/driving-car', body);

    final distances = (json['distances'] as List)
        .map((row) => (row as List)
            .map((v) => v == null ? -1 : (v as num).round())
            .toList())
        .toList();
    final durations = (json['durations'] as List)
        .map((row) => (row as List)
            .map((v) => v == null ? -1 : (v as num).round())
            .toList())
        .toList();
    return OrsMatrixResult(distances: distances, durations: durations);
  }

  /// Appel commun via l'Edge Function ors-proxy. Le SDK gère
  /// automatiquement le bearer JWT (anonymous ou email user).
  Future<Map<String, dynamic>> _invokeOrs(
    String orsSubPath,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _supabase.functions
          .invoke(
            'ors-proxy/$orsSubPath',
            body: body,
            method: HttpMethod.post,
          )
          .timeout(const Duration(seconds: 20));

      // Le SDK décode déjà le JSON en data.
      if (response.status == 401 || response.status == 403) {
        throw OrsAuthException('Unauthorized — check session/key');
      }
      if (response.status == 429) {
        throw OrsQuotaException('ORS quota exceeded');
      }
      if (response.status >= 400) {
        throw OrsException('HTTP ${response.status}');
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw OrsException('Unexpected response shape from ors-proxy');
      }
      return data;
    } on OrsException {
      rethrow;
    } on FunctionException catch (e) {
      throw OrsException('Edge function error: ${e.details}', e);
    } on SocketException catch (e) {
      throw OrsException('Network unavailable', e);
    } on TimeoutException catch (e) {
      throw OrsException('Request timed out', e);
    } catch (e) {
      throw OrsException('Unexpected error', e);
    }
  }
}
```

Note : `http: ^1.6.0` reste dans `pubspec.yaml` (utilisé par d'autres services comme `ban_geocoding_service`), même si `OrsRoutingService` n'en dépend plus. L'import `package:http/http.dart` est retiré du fichier.

- [ ] **Step 2: Mettre à jour `orsRoutingServiceProvider` dans `providers.dart`**

Localiser dans `lib/state/providers.dart` :

```bash
grep -n 'orsRoutingService' lib/state/providers.dart
```

Remplacer la définition existante par :

```dart
final orsRoutingServiceProvider = Provider<OrsRoutingService>((ref) {
  return OrsRoutingService(supabase: Supabase.instance.client);
});
```

Et ajouter l'import en tête :

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

Retirer l'éventuelle dépendance à `Env.orsApiKey` et au `httpClient` si plus utilisé exclusivement pour ORS.

- [ ] **Step 3: Vérifier la compilation**

```bash
flutter analyze
```

Expected : 0 erreur. Si `Env.orsApiKey` est encore référencé ailleurs, retirer ces références.

- [ ] **Step 4: Smoke test manuel**

```bash
flutter run
```

- Lancer l'app sur device.
- Vérifier que la session anonyme s'ouvre (debugPrint `currentSession?.user.id` non null).
- Aller dans l'écran « Tournée optimisée » et déclencher un calcul → vérifier que les routes ORS s'affichent.
- Vérifier que la matrix de distances entre clients est calculée (les distances apparaissent dans le draft).

- [ ] **Step 5: Commit**

```bash
git add lib/infra/services/ors_routing_service.dart lib/state/providers.dart
git commit -m "feat(cloud): route ORS calls via ors-proxy edge function

Cutover complet — OrsRoutingService passe par supabase.functions.invoke
au lieu d'appeler ORS directement. ORS_API_KEY n'est plus requis côté app.
Le bearer JWT (anon ou email) est ajouté automatiquement par le SDK.
Comportement métier inchangé (close-loop fallback, gestion 401/429 etc.)."
```

---

## Phase F — Auth & sessions

### Task 13: `AuthService`

**Files:**
- Create: `lib/infra/cloud/auth_service.dart`
- Test: `test/infra/cloud/auth_service_test.dart`

- [ ] **Step 1: Écrire le test (mocktail sur SupabaseClient)**

```dart
// test/infra/cloud/auth_service_test.dart
import 'package:coup_laine/infra/cloud/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabase extends Mock implements SupabaseClient {}
class _MockAuth extends Mock implements GoTrueClient {}

void main() {
  late _MockSupabase supabase;
  late _MockAuth auth;
  late AuthService service;

  setUp(() {
    supabase = _MockSupabase();
    auth = _MockAuth();
    when(() => supabase.auth).thenReturn(auth);
    service = AuthService(supabase);
  });

  group('isCloudOptedIn', () {
    test('returns false when no session', () {
      when(() => auth.currentSession).thenReturn(null);
      expect(service.isCloudOptedIn, isFalse);
    });

    test('returns false for anonymous session', () {
      final user = User(
        id: 'u1', appMetadata: const {}, userMetadata: null,
        aud: 'authenticated', createdAt: '2026-01-01T00:00:00Z',
        isAnonymous: true,
      );
      when(() => auth.currentSession).thenReturn(_fakeSession(user));
      expect(service.isCloudOptedIn, isFalse);
    });

    test('returns true for email session', () {
      final user = User(
        id: 'u1', appMetadata: const {}, userMetadata: null,
        aud: 'authenticated', createdAt: '2026-01-01T00:00:00Z',
        isAnonymous: false, email: 'a@b.fr',
      );
      when(() => auth.currentSession).thenReturn(_fakeSession(user));
      expect(service.isCloudOptedIn, isTrue);
    });
  });

  group('signInWithMagicLink', () {
    test('appelle signInWithOtp avec emailRedirectTo', () async {
      when(() => auth.signInWithOtp(
            email: any(named: 'email'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
          )).thenAnswer((_) async {});

      await service.signInWithMagicLink('user@example.com');

      verify(() => auth.signInWithOtp(
            email: 'user@example.com',
            emailRedirectTo: 'coupelaine://auth/callback',
          )).called(1);
    });
  });

  group('signOut', () {
    test('signOut puis signInAnonymously', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});
      when(() => auth.signInAnonymously())
          .thenAnswer((_) async => AuthResponse());

      await service.signOut();

      verifyInOrder([
        () => auth.signOut(),
        () => auth.signInAnonymously(),
      ]);
    });
  });
}

Session _fakeSession(User user) => Session(
      accessToken: 'tok',
      tokenType: 'bearer',
      user: user,
    );
```

- [ ] **Step 2: Implémenter `AuthService`**

```dart
// lib/infra/cloud/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const String _redirectUrl = 'coupelaine://auth/callback';

  final SupabaseClient _supabase;

  AuthService(this._supabase);

  /// `true` si une session non-anonyme (email-based) est active.
  /// Une session anonyme (créée pour l'ORS proxy) n'est PAS un opt-in cloud.
  bool get isCloudOptedIn {
    final session = _supabase.auth.currentSession;
    return session != null && !(session.user.isAnonymous ?? false);
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Session? get currentSession => _supabase.auth.currentSession;

  /// Envoie un magic link à l'email donné. Au clic dans l'email,
  /// l'app s'ouvre sur `coupelaine://auth/callback` et le SDK valide
  /// le token automatiquement.
  Future<void> signInWithMagicLink(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: _redirectUrl,
    );
  }

  /// Déconnecte l'utilisateur du cloud puis rouvre une session anonyme
  /// pour que l'ORS proxy reste accessible.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _supabase.auth.signInAnonymously();
  }
}
```

- [ ] **Step 3: Lancer les tests**

```bash
flutter test test/infra/cloud/auth_service_test.dart
```

Expected : tous verts.

- [ ] **Step 4: Commit**

```bash
git add lib/infra/cloud/auth_service.dart test/infra/cloud/auth_service_test.dart
git commit -m "feat(cloud): AuthService — magic link sign-in, sign-out keeps anon session"
```

---

### Task 14: Providers Riverpod pour l'auth

**Files:**
- Modify: `lib/state/providers.dart`

- [ ] **Step 1: Ajouter les providers**

Dans `lib/state/providers.dart`, après les providers existants (par exemple après `appDatabaseProvider`), ajouter :

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../infra/cloud/auth_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

/// Stream de l'état d'auth Supabase. Émet à chaque sign-in/sign-out
/// et à chaque refresh JWT.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Session courante (anon ou email). Null pendant l'init de Supabase.
final currentSessionProvider = Provider<Session?>((ref) {
  // Réagit au stream pour rebuild quand l'état change.
  ref.watch(authStateChangesProvider);
  return ref.watch(authServiceProvider).currentSession;
});

/// `true` ssi une session non-anonyme est active. Pilote l'affichage
/// des fonctionnalités cloud (bouton « Sauvegarder maintenant », liste
/// des backups, etc.).
final isCloudOptedInProvider = Provider<bool>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(authServiceProvider).isCloudOptedIn;
});
```

- [ ] **Step 2: Vérifier**

```bash
flutter analyze lib/state/providers.dart
```

Expected : 0 erreur.

- [ ] **Step 3: Commit**

```bash
git add lib/state/providers.dart
git commit -m "feat(cloud): Riverpod providers for auth state (session, opt-in flag)"
```

---

## Phase G — Couche backup

### Task 15: `BackupMeta` model + `BackupsRepository`

**Files:**
- Create: `lib/domain/models/backup_meta.dart`
- Create: `lib/infra/cloud/backups_repository.dart`
- Test: `test/domain/backup_meta_test.dart`

- [ ] **Step 1: Définir le model `BackupMeta`**

```dart
// lib/domain/models/backup_meta.dart
class BackupMeta {
  final String id;
  final String userId;
  final String storagePath;
  final DateTime createdAt;
  final int schemaVersion;
  final int sizeBytes;

  const BackupMeta({
    required this.id,
    required this.userId,
    required this.storagePath,
    required this.createdAt,
    required this.schemaVersion,
    required this.sizeBytes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupMeta &&
          other.id == id &&
          other.userId == userId &&
          other.storagePath == storagePath &&
          other.createdAt == createdAt &&
          other.schemaVersion == schemaVersion &&
          other.sizeBytes == sizeBytes;

  @override
  int get hashCode => Object.hash(
        id, userId, storagePath, createdAt, schemaVersion, sizeBytes,
      );
}
```

- [ ] **Step 2: Test minimal du model**

```dart
// test/domain/backup_meta_test.dart
import 'package:coup_laine/domain/models/backup_meta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BackupMeta supports equality', () {
    final a = BackupMeta(
      id: '1', userId: 'u', storagePath: 'p',
      createdAt: DateTime.utc(2026, 5, 1), schemaVersion: 2, sizeBytes: 100,
    );
    final b = BackupMeta(
      id: '1', userId: 'u', storagePath: 'p',
      createdAt: DateTime.utc(2026, 5, 1), schemaVersion: 2, sizeBytes: 100,
    );
    expect(a, equals(b));
  });
}
```

```bash
flutter test test/domain/backup_meta_test.dart
```

- [ ] **Step 3: Implémenter `BackupsRepository`**

```dart
// lib/infra/cloud/backups_repository.dart
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/backup_meta.dart';

class BackupsRepository {
  static const String _bucketName = 'backups';
  static const String _tableName = 'backups';

  final SupabaseClient _supabase;

  BackupsRepository(this._supabase);

  /// Liste les backups du user courant, triés par `created_at desc`.
  Future<List<BackupMeta>> listForCurrentUser() async {
    final userId = _requireUserId();
    final rows = await _supabase
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return [for (final r in rows as List) _toDomain(r as Map<String, dynamic>)];
  }

  /// Compte les backups du user courant.
  Future<int> countForCurrentUser() async {
    final userId = _requireUserId();
    final rows = await _supabase
        .from(_tableName)
        .select('id')
        .eq('user_id', userId);
    return (rows as List).length;
  }

  /// Upload un blob gzippé vers Storage et insère la ligne d'index.
  /// Retourne la `BackupMeta` créée.
  Future<BackupMeta> create({
    required Uint8List gzippedBytes,
    required int schemaVersion,
  }) async {
    final userId = _requireUserId();
    final timestamp = DateTime.now().toUtc();
    final iso = timestamp.toIso8601String().replaceAll(':', '-');
    final storagePath = '$userId/$iso.json.gz';

    await _supabase.storage.from(_bucketName).uploadBinary(
          storagePath,
          gzippedBytes,
          fileOptions: const FileOptions(
            contentType: 'application/gzip',
            upsert: false,
          ),
        );

    final inserted = await _supabase
        .from(_tableName)
        .insert({
          'user_id': userId,
          'storage_path': storagePath,
          'schema_version': schemaVersion,
          'size_bytes': gzippedBytes.length,
        })
        .select()
        .single();

    return _toDomain(inserted);
  }

  /// Télécharge le contenu d'un backup. Retourne les bytes gzippés.
  Future<Uint8List> download(String storagePath) async {
    return _supabase.storage.from(_bucketName).download(storagePath);
  }

  /// Supprime une ligne d'index ET le fichier Storage associé.
  /// Best-effort : si la suppression Storage échoue mais la row existe
  /// encore, on la supprime quand même pour ne pas laisser d'incohérence.
  Future<void> delete(BackupMeta meta) async {
    try {
      await _supabase.storage.from(_bucketName).remove([meta.storagePath]);
    } catch (_) {
      // Continue malgré l'erreur — l'orphelin Storage sera nettoyé
      // manuellement si besoin.
    }
    await _supabase.from(_tableName).delete().eq('id', meta.id);
  }

  String _requireUserId() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No active session — cannot access backups');
    }
    return userId;
  }

  BackupMeta _toDomain(Map<String, dynamic> row) {
    return BackupMeta(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      storagePath: row['storage_path'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      schemaVersion: row['schema_version'] as int,
      sizeBytes: row['size_bytes'] as int,
    );
  }
}
```

- [ ] **Step 4: Pas de tests unitaires Supabase pour le repo**

`BackupsRepository` est essentiellement un wrapper sur le SDK Supabase qui parle au backend réel. Les tester avec des mocks reproduit la signature du SDK sans valider le comportement RLS. Le smoke test en E2E (Task 28) couvre la fonctionnalité.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/models/backup_meta.dart lib/infra/cloud/backups_repository.dart \
        test/domain/backup_meta_test.dart
git commit -m "feat(cloud): BackupMeta domain + BackupsRepository (Supabase Storage + table)"
```

---

### Task 16: Helpers gzip purs et testables

**Files:**
- Create: `lib/core/cloud/gzip_codec.dart`
- Test: `test/core/cloud/gzip_codec_test.dart`

- [ ] **Step 1: Écrire le test**

```dart
// test/core/cloud/gzip_codec_test.dart
import 'dart:convert';

import 'package:coup_laine/core/cloud/gzip_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trip preserves arbitrary string', () {
    const sample = '{"clients":[{"name":"Marius"}]}';
    final compressed = gzipString(sample);
    expect(compressed, isNot(equals(utf8.encode(sample))));
    final restored = gunzipString(compressed);
    expect(restored, equals(sample));
  });

  test('compression reduces size for repetitive payload', () {
    final big = '{"a":${'x' * 5000}}';
    final compressed = gzipString(big);
    expect(compressed.length, lessThan(utf8.encode(big).length ~/ 5));
  });

  test('gunzipString throws FormatException on garbage input', () {
    expect(
      () => gunzipString(utf8.encode('not gzipped at all')),
      throwsA(isA<FormatException>()),
    );
  });
}
```

- [ ] **Step 2: Implémenter**

```dart
// lib/core/cloud/gzip_codec.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Compresse une chaîne UTF-8 en gzip.
Uint8List gzipString(String input) {
  final bytes = utf8.encode(input);
  final encoded = const GZipEncoder().encode(bytes);
  if (encoded == null) {
    throw StateError('gzip encoder returned null');
  }
  return Uint8List.fromList(encoded);
}

/// Décompresse un blob gzip et retourne la chaîne UTF-8 originale.
/// Lance [FormatException] si le blob n'est pas un gzip valide.
String gunzipString(List<int> input) {
  try {
    final decoded = const GZipDecoder().decodeBytes(input);
    return utf8.decode(decoded);
  } catch (e) {
    throw FormatException('Invalid gzip payload: $e');
  }
}
```

- [ ] **Step 3: Lancer les tests**

```bash
flutter test test/core/cloud/gzip_codec_test.dart
```

Expected : verts.

- [ ] **Step 4: Commit**

```bash
git add lib/core/cloud/gzip_codec.dart test/core/cloud/gzip_codec_test.dart
git commit -m "feat(cloud): pure gzip helpers (gzipString / gunzipString)"
```

---

### Task 17: `BackupService` — snapshot, upload, download, rotate

**Files:**
- Create: `lib/infra/cloud/backup_service.dart`
- Test: `test/infra/cloud/backup_service_test.dart`

- [ ] **Step 1: Écrire les tests pour le helper pur `shouldRunAutoBackup`**

```dart
// test/infra/cloud/backup_service_test.dart
import 'package:coup_laine/infra/cloud/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldRunAutoBackup', () {
    final now = DateTime.utc(2026, 5, 1, 12);

    test('false si pas opt-in', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: false,
          lastBackupAt: null,
          hasNetwork: true,
        ),
        isFalse,
      );
    });

    test('false si pas de réseau', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: true,
          lastBackupAt: null,
          hasNetwork: false,
        ),
        isFalse,
      );
    });

    test('true si jamais sauvegardé', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: true,
          lastBackupAt: null,
          hasNetwork: true,
        ),
        isTrue,
      );
    });

    test('false si dernier backup < 24h', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: true,
          lastBackupAt: now.subtract(const Duration(hours: 23)),
          hasNetwork: true,
        ),
        isFalse,
      );
    });

    test('true si dernier backup >= 24h', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: true,
          lastBackupAt: now.subtract(const Duration(hours: 24, minutes: 1)),
          hasNetwork: true,
        ),
        isTrue,
      );
    });
  });
}
```

- [ ] **Step 2: Implémenter `BackupService` + helper**

```dart
// lib/infra/cloud/backup_service.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../core/cloud/gzip_codec.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/backup_meta.dart';
import '../services/json_export_service.dart';
import 'backups_repository.dart';

/// Pure helper — extrait pour testabilité.
///
/// Renvoie `true` ssi un auto-backup doit être déclenché à `now`.
/// - cloudOptIn : session non-anonyme active.
/// - lastBackupAt : `null` si jamais sauvegardé.
/// - hasNetwork : best-effort (cf. note dans BackupScheduler).
bool shouldRunAutoBackup({
  required DateTime now,
  required bool cloudOptIn,
  required DateTime? lastBackupAt,
  required bool hasNetwork,
}) {
  if (!cloudOptIn || !hasNetwork) return false;
  if (lastBackupAt == null) return true;
  return now.difference(lastBackupAt) >= const Duration(hours: 24);
}

class BackupService {
  static const int _historyWindow = 3;

  final BackupsRepository _repo;
  final JsonExportService _exporter;
  final SettingsRepository _settings;

  bool _inProgress = false;

  BackupService({
    required BackupsRepository repo,
    required JsonExportService exporter,
    required SettingsRepository settings,
  })  : _repo = repo,
        _exporter = exporter,
        _settings = settings;

  /// Crée un snapshot de la base, le compresse, l'upload et fait
  /// la rotation des anciens. Idempotent : un appel concurrent retourne
  /// immédiatement sans rien faire.
  Future<BackupMeta?> runBackup() async {
    if (_inProgress) {
      debugPrint('BackupService.runBackup: already in progress, skipping');
      return null;
    }
    _inProgress = true;
    try {
      final json = await _exporter.exportToJsonString();
      final compressed = gzipString(json);
      final created = await _repo.create(
        gzippedBytes: compressed,
        schemaVersion: JsonExportService.schemaVersion,
      );
      await _settings.setLastBackupAt(DateTime.now());
      await _rotate();
      return created;
    } finally {
      _inProgress = false;
    }
  }

  /// Liste les backups disponibles pour le user courant.
  Future<List<BackupMeta>> listAvailable() {
    return _repo.listForCurrentUser();
  }

  /// Restaure un backup donné : download → gunzip → import.
  /// Lance [JsonImportException] si schema futur, ou autre erreur.
  Future<void> restore(BackupMeta meta) async {
    final compressed = await _repo.download(meta.storagePath);
    final json = gunzipString(compressed);
    await _exporter.importFromJsonString(json);
    // On NE met PAS à jour lastBackupAt — il reflète la date du
    // dernier backup, pas du restore.
  }

  /// Si le user vient de devenir non-anonyme et n'a aucun backup sur
  /// le compte cloud, push automatiquement l'état local. Sinon, le
  /// caller (UI) est responsable d'afficher la modal de choix.
  /// Retourne `true` ssi un push automatique a été fait.
  Future<bool> resolveInitialStateAfterOptIn() async {
    final count = await _repo.countForCurrentUser();
    if (count == 0) {
      await runBackup();
      return true;
    }
    return false;
  }

  Future<void> _rotate() async {
    final all = await _repo.listForCurrentUser();
    if (all.length <= _historyWindow) return;
    final toDelete = all.sublist(_historyWindow);
    for (final old in toDelete) {
      await _repo.delete(old);
    }
  }
}
```

- [ ] **Step 3: Lancer les tests**

```bash
flutter test test/infra/cloud/backup_service_test.dart
```

Expected : verts (les 5 tests sur `shouldRunAutoBackup`). Les méthodes du service (`runBackup`, `restore`, `resolveInitialStateAfterOptIn`) sont testées en E2E manuel à la Task 28 — leur logique est essentiellement de la composition de méthodes déjà testées (gzip, JsonExportService, repo).

- [ ] **Step 4: Ajouter le provider**

Dans `lib/state/providers.dart`, ajouter après les providers d'auth :

```dart
import '../infra/cloud/backup_service.dart';
import '../infra/cloud/backups_repository.dart';

final backupsRepositoryProvider = Provider<BackupsRepository>((ref) {
  return BackupsRepository(ref.watch(supabaseClientProvider));
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    repo: ref.watch(backupsRepositoryProvider),
    exporter: ref.watch(jsonExportServiceProvider),
    settings: ref.watch(settingsRepositoryProvider),
  );
});
```

Si `jsonExportServiceProvider` n'existe pas encore, l'ajouter aussi (en localisant l'instanciation actuelle de `JsonExportService` dans `providers.dart` ou ailleurs et en la convertissant en provider).

- [ ] **Step 5: Commit**

```bash
git add lib/infra/cloud/backup_service.dart test/infra/cloud/backup_service_test.dart \
        lib/state/providers.dart
git commit -m "feat(cloud): BackupService — snapshot, upload, restore, rotate, initial-state resolve"
```

---

### Task 18: `BackupScheduler` — auto-backup au resume

**Files:**
- Create: `lib/infra/cloud/backup_scheduler.dart`
- Modify: `lib/app.dart` (ou autre point d'entrée widget global)

**Note sur la détection de réseau** : pour rester KISS et éviter d'ajouter une dépendance comme `connectivity_plus`, on tente le backup et on laisse le SDK Supabase échouer en cas d'absence de réseau. La fonction `shouldRunAutoBackup` reçoit toujours `hasNetwork: true` en pratique ; le paramètre est conservé pour les tests et une éventuelle évolution.

- [ ] **Step 1: Implémenter le scheduler**

```dart
// lib/infra/cloud/backup_scheduler.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../../state/providers.dart';
import 'backup_service.dart';

class BackupScheduler with WidgetsBindingObserver {
  final BackupService _service;
  final SettingsRepository _settings;
  final ProviderRef _ref;

  BackupScheduler(this._service, this._settings, this._ref);

  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_maybeRunBackup());
    }
  }

  Future<void> _maybeRunBackup() async {
    try {
      final cloudOptIn = _ref.read(isCloudOptedInProvider);
      final settings = await _settings.read();
      final lastBackupAt = settings?.lastBackupAt;
      if (!shouldRunAutoBackup(
        now: DateTime.now(),
        cloudOptIn: cloudOptIn,
        lastBackupAt: lastBackupAt,
        hasNetwork: true,
      )) {
        return;
      }
      await _service.runBackup();
    } catch (e, st) {
      debugPrint('BackupScheduler: auto-backup failed: $e\n$st');
    }
  }
}

final backupSchedulerProvider = Provider<BackupScheduler>((ref) {
  final scheduler = BackupScheduler(
    ref.watch(backupServiceProvider),
    ref.watch(settingsRepositoryProvider),
    ref,
  );
  scheduler.start();
  ref.onDispose(scheduler.stop);
  return scheduler;
});
```

- [ ] **Step 2: Démarrer le scheduler dans `CoupeLaineApp`**

Dans `lib/app.dart`, dans le widget root (`build` de `CoupeLaineApp`), invoquer le provider une fois pour qu'il s'instancie :

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Démarrer le scheduler (effet de bord : s'abonne au lifecycle)
  ref.watch(backupSchedulerProvider);
  // ... le reste du build existant
}
```

Si `CoupeLaineApp` est un `StatelessWidget` non-Consumer, le convertir en `ConsumerWidget` (ajouter l'import et changer la signature).

- [ ] **Step 3: Vérifier la compilation**

```bash
flutter analyze
```

- [ ] **Step 4: Commit**

```bash
git add lib/infra/cloud/backup_scheduler.dart lib/app.dart lib/state/providers.dart
git commit -m "feat(cloud): BackupScheduler — auto-backup on app resume (24h gating)"
```

---

## Phase H — UI : section « Compte cloud » dans Réglages

### Task 19: Section « Compte cloud » dans `settings_screen.dart`

**Files:**
- Modify: `lib/presentation/settings/settings_screen.dart`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`

**Contexte UX (cf. spec §4.5)** :
- Si non opt-in : un bouton « Activer la sauvegarde cloud » → push vers l'écran de magic link (Task 20).
- Si opt-in : email connecté, dernier backup, boutons « Sauvegarder maintenant » / « Restaurer » / « Se déconnecter ».

- [ ] **Step 1: Ajouter les clés l10n**

Dans `lib/l10n/app_fr.arb` (au sein du JSON, sans casser la syntaxe) :

```json
"settingsCloudSection": "Compte cloud",
"settingsCloudActivate": "Activer la sauvegarde cloud",
"settingsCloudConnectedAs": "Connecté avec {email}",
"@settingsCloudConnectedAs": { "placeholders": { "email": {} } },
"settingsCloudLastBackupNever": "Aucune sauvegarde",
"settingsCloudLastBackupAgo": "Dernière sauvegarde : {when}",
"@settingsCloudLastBackupAgo": { "placeholders": { "when": {} } },
"settingsCloudBackupNow": "Sauvegarder maintenant",
"settingsCloudBackupSuccess": "Sauvegarde effectuée",
"settingsCloudBackupFailed": "Sauvegarde échouée. Réessayez.",
"settingsCloudBackupNoNetwork": "Pas de connexion.",
"settingsCloudRestore": "Restaurer un backup",
"settingsCloudSignOut": "Se déconnecter du cloud",
"settingsCloudSignOutConfirm": "Cela ne supprimera pas vos données locales. Vous pourrez vous reconnecter à tout moment.",
```

Dans `lib/l10n/app_en.arb`, ajouter les mêmes clés avec traductions EN.

- [ ] **Step 2: Régénérer l10n**

```bash
flutter gen-l10n
```

(Déclenché automatiquement au prochain build, mais on peut forcer.)

- [ ] **Step 3: Ajouter la section dans `settings_screen.dart`**

Localiser la structure de `settings_screen.dart` et ajouter une nouvelle section. Le pattern à suivre dépend du code existant — typiquement un `AppSectionCard` ou équivalent. Squelette :

```dart
// Dans build()
final t = AppLocalizations.of(context)!;
final cloudOptIn = ref.watch(isCloudOptedInProvider);
final session = ref.watch(currentSessionProvider);
final settingsAsync = ref.watch(settingsRepositoryFutureProvider);

// Section :
AppSectionCard(
  title: t.settingsCloudSection,
  children: [
    if (!cloudOptIn) ...[
      AppPrimaryButton(
        label: t.settingsCloudActivate,
        onPressed: () => context.push('/settings/cloud-login'),
      ),
    ] else ...[
      // Email connecté
      Text(t.settingsCloudConnectedAs(session?.user.email ?? '')),
      // Dernière sauvegarde
      settingsAsync.when(
        data: (s) {
          if (s?.lastBackupAt == null) {
            return Text(t.settingsCloudLastBackupNever);
          }
          return Text(t.settingsCloudLastBackupAgo(
            _formatRelative(s!.lastBackupAt!),
          ));
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      // Bouton Sauvegarder
      AppPrimaryButton(
        label: t.settingsCloudBackupNow,
        onPressed: () => _onBackupNow(context, ref),
      ),
      // Bouton Restaurer (visible si au moins 1 backup)
      _RestoreButton(),
      // Bouton Sign out
      TextButton(
        onPressed: () => _onSignOut(context, ref),
        child: Text(t.settingsCloudSignOut),
      ),
    ],
  ],
);
```

Et les helpers (méthodes statiques ou widgets dédiés) :

```dart
String _formatRelative(DateTime when) {
  final now = DateTime.now();
  final diff = now.difference(when);
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  return 'il y a ${diff.inDays} j';
}

Future<void> _onBackupNow(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(backupServiceProvider).runBackup();
    if (!context.mounted) return;
    // Refresh affichage du dernier backup
    ref.invalidate(settingsRepositoryFutureProvider);
    messenger.showSnackBar(
      SnackBar(content: Text(t.settingsCloudBackupSuccess)),
    );
  } catch (e) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(t.settingsCloudBackupFailed)),
    );
  }
}

Future<void> _onSignOut(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context)!;
  final confirmed = await showConfirmDialog(
    context: context,
    title: t.settingsCloudSignOut,
    message: t.settingsCloudSignOutConfirm,
  );
  if (!confirmed) return;
  await ref.read(authServiceProvider).signOut();
}
```

- [ ] **Step 4: Vérifier la compilation**

```bash
flutter analyze
```

- [ ] **Step 5: Smoke test rapide**

```bash
flutter run
```

Naviguer vers Réglages, vérifier que la section « Compte cloud » s'affiche avec un bouton « Activer la sauvegarde cloud ». Le bouton ne fait rien encore (la route `/settings/cloud-login` n'existe pas — Task 20).

- [ ] **Step 6: Pas de commit isolé** — on commit l'écran complet à la Task 20.

---

### Task 20: Écran de connexion magic link

**Files:**
- Create: `lib/presentation/cloud/cloud_login_screen.dart`
- Modify: `lib/core/routing/app_router.dart`
- Modify: `lib/l10n/app_fr.arb` + `app_en.arb`

- [ ] **Step 1: Ajouter les clés l10n**

```json
"cloudLoginTitle": "Connexion cloud",
"cloudLoginEmailLabel": "Adresse email",
"cloudLoginEmailHint": "vous@exemple.fr",
"cloudLoginEmailInvalid": "Email invalide",
"cloudLoginSendButton": "Envoyer le lien",
"cloudLoginCheckEmail": "Lien envoyé. Vérifiez votre boîte mail puis tapez sur le lien dans cet email.",
"cloudLoginNoNetwork": "Pas de connexion.",
"cloudLoginGenericError": "Erreur. Réessayez plus tard.",
```

- [ ] **Step 2: Créer l'écran**

```dart
// lib/presentation/cloud/cloud_login_screen.dart
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../widgets/app_primary_button.dart';

class CloudLoginScreen extends ConsumerStatefulWidget {
  const CloudLoginScreen({super.key});

  @override
  ConsumerState<CloudLoginScreen> createState() => _CloudLoginScreenState();
}

class _CloudLoginScreenState extends ConsumerState<CloudLoginScreen> {
  final _emailController = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _errorKey;

  bool _isEmailValid(String s) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
  }

  Future<void> _onSubmit() async {
    final email = _emailController.text.trim();
    final t = AppLocalizations.of(context)!;
    if (!_isEmailValid(email)) {
      setState(() => _errorKey = t.cloudLoginEmailInvalid);
      return;
    }
    setState(() {
      _sending = true;
      _errorKey = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithMagicLink(email);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _errorKey = t.cloudLoginGenericError;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.cloudLoginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _sent
            ? Center(child: Text(t.cloudLoginCheckEmail, textAlign: TextAlign.center))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: t.cloudLoginEmailLabel,
                      hintText: t.cloudLoginEmailHint,
                      errorText: _errorKey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    label: t.cloudLoginSendButton,
                    isLoading: _sending,
                    onPressed: _sending ? null : _onSubmit,
                  ),
                ],
              ),
      ),
    );
  }
}
```

- [ ] **Step 3: Ajouter la route**

Dans `lib/core/routing/app_router.dart`, repérer la définition des routes (`GoRoute` ou shell), ajouter :

```dart
GoRoute(
  path: '/settings/cloud-login',
  builder: (context, state) => const CloudLoginScreen(),
),
```

Une fois la session devient non-anonyme (le user a tapé sur le lien), on veut revenir automatiquement à Réglages. Cela se fait via un listener global sur `authStateChangesProvider` placé dans le widget root — voir Task 22 pour le handler complet du callback.

- [ ] **Step 4: Vérifier la compilation**

```bash
flutter analyze
```

- [ ] **Step 5: Commit (Tasks 19 + 20)**

```bash
git add lib/presentation/settings/settings_screen.dart \
        lib/presentation/cloud/cloud_login_screen.dart \
        lib/core/routing/app_router.dart \
        lib/l10n/app_fr.arb lib/l10n/app_en.arb
git commit -m "feat(cloud): settings cloud account section + magic link login screen"
```

---

### Task 21: Handler du callback deep-link (auto-pop vers Réglages)

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Écouter `authStateChanges` au niveau root**

Dans `CoupeLaineApp` (déjà passé en `ConsumerWidget` à la Task 18) ou dans un widget enfant proche, ajouter un listener qui ferme le `CloudLoginScreen` quand la session devient non-anonyme :

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.watch(backupSchedulerProvider);

  // Listen-only : pop le login screen quand la session devient email-based.
  ref.listen<bool>(isCloudOptedInProvider, (previous, current) {
    if (previous == false && current == true) {
      // L'utilisateur vient de tomber sur le callback magic link.
      // Si le login screen est en haut de la navigation, on le pop.
      // Le router GoRouter gère le pop via context, ici on délègue à
      // un helper qui inspecte la route courante.
      _handlePostSignIn(ref);
    }
  });

  // ... le reste du build
}
```

L'implémentation de `_handlePostSignIn` doit :
1. Si la route courante est `/settings/cloud-login` ou `/onboarding/cloud-login` (ajouté à la Task 23), pop ou push vers la suite logique.
2. Déclencher `BackupService.resolveInitialStateAfterOptIn` pour push automatique si cloud vide, ou afficher la modal de choix sinon.

```dart
Future<void> _handlePostSignIn(WidgetRef ref) async {
  // On utilise un GlobalKey de Navigator si nécessaire, ou un helper
  // qui lit le router. Pour simplifier dans cette task, on pose un
  // navigatorKey global sur le router.
  final pushed = await ref
      .read(backupServiceProvider)
      .resolveInitialStateAfterOptIn();

  // Si pushed=true : le snackbar de succès suffit.
  // Si pushed=false : afficher la modal "garder local / restaurer cloud" — implémentée à la Task 24.
  // ... (cf. Task 24 pour le détail)
}
```

**Nota** : pour pop la route `cloud-login`, le plus simple est de faire le pop **depuis l'écran lui-même** via un `ref.listen` interne :

Modifier `cloud_login_screen.dart` : dans le `build`, ajouter :

```dart
ref.listen<bool>(isCloudOptedInProvider, (prev, curr) {
  if (curr && mounted) {
    Navigator.of(context).pop(); // ou GoRouter.of(context).pop()
  }
});
```

C'est plus localisé. Mettre cette version-là dans le code et retirer le `_handlePostSignIn` global. L'effet « modal de choix » sera gérée à la Task 24 (déclenchée depuis Réglages après le pop).

- [ ] **Step 2: Vérifier le smoke test**

```bash
flutter run
```

- Aller dans Réglages → « Activer la sauvegarde cloud » → écran login.
- Saisir un email valide → bouton → message « Lien envoyé ».
- Ouvrir le mail Supabase reçu → cliquer le lien → l'app revient au premier plan, le login screen pop automatiquement, on est de retour sur Réglages.
- Vérifier que la section Cloud affiche maintenant l'email connecté.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/cloud/cloud_login_screen.dart lib/app.dart
git commit -m "feat(cloud): auto-pop login screen on successful magic link callback"
```

---

### Task 22: Écran « Backups disponibles » + flow de restauration

**Files:**
- Create: `lib/presentation/cloud/backup_picker_screen.dart`
- Create: `lib/presentation/cloud/restore_confirm_dialog.dart`
- Modify: `lib/core/routing/app_router.dart`
- Modify: `lib/l10n/app_fr.arb` + `app_en.arb`

- [ ] **Step 1: Ajouter les clés l10n**

```json
"backupPickerTitle": "Sauvegardes disponibles",
"backupPickerEmpty": "Aucune sauvegarde pour ce compte.",
"backupPickerToday": "Aujourd'hui à {time}",
"@backupPickerToday": { "placeholders": { "time": {} } },
"backupPickerYesterday": "Hier à {time}",
"@backupPickerYesterday": { "placeholders": { "time": {} } },
"backupPickerSizeKb": "{kb} ko",
"@backupPickerSizeKb": { "placeholders": { "kb": {} } },
"restoreConfirmTitleSettings": "Restaurer ce backup ?",
"restoreConfirmMessageSettings": "Cela écrasera toutes les données actuelles de cet appareil. Action irréversible.",
"restoreConfirmTypePromptSettings": "Tapez RESTAURER pour confirmer",
"restoreConfirmConfirmButton": "Restaurer",
"restoreConfirmCancelButton": "Annuler",
"restoreInProgress": "Restauration en cours…",
"restoreSuccess": "Restauration terminée",
"restoreFailedFutureSchema": "Cette sauvegarde a été créée par une version plus récente. Mettez à jour l'app.",
"restoreFailedGeneric": "Restauration échouée.",
```

- [ ] **Step 2: Créer le picker**

```dart
// lib/presentation/cloud/backup_picker_screen.dart
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/backup_meta.dart';
import '../../state/providers.dart';
import 'restore_confirm_dialog.dart';

final _backupListProvider = FutureProvider.autoDispose<List<BackupMeta>>((ref) {
  return ref.watch(backupServiceProvider).listAvailable();
});

class BackupPickerScreen extends ConsumerWidget {
  /// `requireTypedConfirmation` = true pour le flow Réglages (UX renforcée),
  /// false pour le flow onboarding (confirmation simple suffit).
  final bool requireTypedConfirmation;

  const BackupPickerScreen({
    super.key,
    this.requireTypedConfirmation = true,
  });

  String _formatLabel(BackupMeta m, AppLocalizations t) {
    final now = DateTime.now();
    final local = m.createdAt.toLocal();
    final time = DateFormat('HH:mm').format(local);
    if (now.year == local.year && now.month == local.month && now.day == local.day) {
      return t.backupPickerToday(time);
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == local.year &&
        yesterday.month == local.month &&
        yesterday.day == local.day) {
      return t.backupPickerYesterday(time);
    }
    return DateFormat('d MMMM à HH:mm', 'fr').format(local);
  }

  String _formatSize(int bytes, AppLocalizations t) {
    final kb = (bytes / 1024).toStringAsFixed(0);
    return t.backupPickerSizeKb(kb);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final backupsAsync = ref.watch(_backupListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.backupPickerTitle)),
      body: backupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(t.backupPickerEmpty));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = list[i];
              return ListTile(
                title: Text(_formatLabel(m, t)),
                subtitle: Text(_formatSize(m.sizeBytes, t)),
                onTap: () => _onTap(context, ref, m),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, BackupMeta m) async {
    final confirmed = await showRestoreConfirmDialog(
      context: context,
      requireTypedConfirmation: requireTypedConfirmation,
    );
    if (!confirmed || !context.mounted) return;
    await _runRestore(context, ref, m);
  }

  Future<void> _runRestore(BuildContext context, WidgetRef ref, BackupMeta m) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );
    try {
      await ref.read(backupServiceProvider).restore(m);
      if (!context.mounted) return;
      Navigator.of(context).pop(); // dismiss spinner
      // Invalider tous les providers root pour rebuild l'arbre.
      ref.invalidate(settingsRepositoryFutureProvider);
      // ... ajouter d'autres invalidations selon les providers root.
      messenger.showSnackBar(SnackBar(content: Text(t.restoreSuccess)));
      // Pop jusqu'à la racine
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // dismiss spinner
      final isFutureSchema = e.toString().contains('non supportée');
      messenger.showSnackBar(SnackBar(
        content: Text(isFutureSchema
            ? t.restoreFailedFutureSchema
            : t.restoreFailedGeneric),
      ));
    }
  }
}
```

- [ ] **Step 3: Créer le dialog de confirmation**

```dart
// lib/presentation/cloud/restore_confirm_dialog.dart
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

const _confirmKeyword = 'RESTAURER';

Future<bool> showRestoreConfirmDialog({
  required BuildContext context,
  required bool requireTypedConfirmation,
}) async {
  final t = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final canConfirm = !requireTypedConfirmation ||
            controller.text.trim() == _confirmKeyword;
        return AlertDialog(
          title: Text(t.restoreConfirmTitleSettings),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.restoreConfirmMessageSettings),
              if (requireTypedConfirmation) ...[
                const SizedBox(height: 16),
                Text(t.restoreConfirmTypePromptSettings),
                TextField(
                  controller: controller,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: _confirmKeyword),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(t.restoreConfirmCancelButton),
            ),
            FilledButton(
              onPressed: canConfirm ? () => Navigator.of(ctx).pop(true) : null,
              child: Text(t.restoreConfirmConfirmButton),
            ),
          ],
        );
      },
    ),
  );
  controller.dispose();
  return result ?? false;
}
```

- [ ] **Step 4: Ajouter la route**

Dans `app_router.dart` :

```dart
GoRoute(
  path: '/settings/backups',
  builder: (context, state) => const BackupPickerScreen(),
),
GoRoute(
  path: '/onboarding/restore-pick',
  builder: (context, state) =>
      const BackupPickerScreen(requireTypedConfirmation: false),
),
```

- [ ] **Step 5: Brancher le bouton « Restaurer un backup » dans Réglages**

Modifier le widget `_RestoreButton` (Task 19) pour pousser `/settings/backups` :

```dart
class _RestoreButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    return TextButton(
      onPressed: () => context.push('/settings/backups'),
      child: Text(t.settingsCloudRestore),
    );
  }
}
```

- [ ] **Step 6: Vérifier la compilation**

```bash
flutter analyze
```

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/cloud/backup_picker_screen.dart \
        lib/presentation/cloud/restore_confirm_dialog.dart \
        lib/core/routing/app_router.dart \
        lib/presentation/settings/settings_screen.dart \
        lib/l10n/app_fr.arb lib/l10n/app_en.arb
git commit -m "feat(cloud): backup picker screen + restore confirm dialog (typed RESTAURER)"
```

---

### Task 23: Modal de résolution première connexion (cas B compte existant)

**Files:**
- Create: `lib/presentation/cloud/first_signin_resolver_dialog.dart`
- Modify: `lib/app.dart` (logique post-sign-in)
- Modify: `lib/l10n/app_fr.arb` + `app_en.arb`

**Contexte (spec §4.6)** : à la première connexion réussie, si le compte cloud a déjà des backups, on présente le choix « garder local / restaurer cloud ». Si le compte est vide, push automatique silencieux.

- [ ] **Step 1: Ajouter les clés l10n**

```json
"firstSigninTitle": "Sauvegardes existantes détectées",
"firstSigninMessage": "Ce compte cloud contient déjà des sauvegardes. Que souhaitez-vous faire ?",
"firstSigninKeepLocal": "Garder les données de cet appareil",
"firstSigninRestoreCloud": "Restaurer depuis le cloud",
"firstSigninInitialBackup": "Sauvegarde initiale effectuée",
```

- [ ] **Step 2: Créer le dialog**

```dart
// lib/presentation/cloud/first_signin_resolver_dialog.dart
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum FirstSigninChoice { keepLocal, restoreCloud }

Future<FirstSigninChoice?> showFirstSigninResolverDialog(BuildContext context) {
  final t = AppLocalizations.of(context)!;
  return showDialog<FirstSigninChoice>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(t.firstSigninTitle),
      content: Text(t.firstSigninMessage),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(ctx).pop(FirstSigninChoice.restoreCloud),
          child: Text(t.firstSigninRestoreCloud),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(ctx).pop(FirstSigninChoice.keepLocal),
          child: Text(t.firstSigninKeepLocal),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: Wirer la logique post-sign-in dans `lib/app.dart`**

Modifier le listener `ref.listen(isCloudOptedInProvider, ...)` ajouté à la Task 21 :

```dart
ref.listen<bool>(isCloudOptedInProvider, (previous, current) async {
  if (previous == false && current == true) {
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context)!;
    final service = ref.read(backupServiceProvider);
    try {
      // Tenter le push auto si cloud vide.
      final pushed = await service.resolveInitialStateAfterOptIn();
      if (pushed) {
        messenger.showSnackBar(
          SnackBar(content: Text(t.firstSigninInitialBackup)),
        );
        return;
      }
      // Cloud non vide → demander à l'utilisateur.
      if (!context.mounted) return;
      final choice = await showFirstSigninResolverDialog(context);
      if (choice == FirstSigninChoice.keepLocal) {
        await service.runBackup();
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(t.firstSigninInitialBackup)),
        );
      } else if (choice == FirstSigninChoice.restoreCloud) {
        if (!context.mounted) return;
        // Push vers le picker — sans confirmation typée
        // (l'utilisateur a déjà choisi).
        // Ici on push une route plus simple OU on show la modal du picker.
        GoRouter.of(context).push('/onboarding/restore-pick');
      }
    } catch (e) {
      debugPrint('First sign-in resolution failed: $e');
    }
  }
});
```

- [ ] **Step 4: Vérifier la compilation**

```bash
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/cloud/first_signin_resolver_dialog.dart lib/app.dart \
        lib/l10n/app_fr.arb lib/l10n/app_en.arb
git commit -m "feat(cloud): first sign-in resolver — auto-push if cloud empty, prompt otherwise"
```

---

## Phase I — UI : path restore dans l'onboarding

### Task 24: Étape « Bienvenue » dans l'onboarding (zéro vs restaurer)

**Files:**
- Modify: `lib/presentation/onboarding/onboarding_screen.dart`
- Modify: `lib/l10n/app_fr.arb` + `app_en.arb`

- [ ] **Step 1: Ajouter les clés l10n**

```json
"onboardingWelcomeTitle": "Bienvenue dans Coup'Laine",
"onboardingWelcomeStartFresh": "Démarrer à zéro",
"onboardingWelcomeRestore": "Restaurer depuis une sauvegarde",
```

- [ ] **Step 2: Ajouter une étape `_step = 0` (Bienvenue) avant l'étape adresse**

Le code actuel a `int _step = 0` qui est l'étape adresse (`_step1Ready` = `_picked != null`). On décale tout :

```dart
class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;  // 0=welcome, 1=address, 2=species
  // ... reste inchangé

  bool get _addressReady => _picked != null;
  bool get _speciesReady => _seedSpeciesActive.isNotEmpty || _customSpecies.isNotEmpty;

  // ... le build dispatch sur _step
}
```

L'étape welcome :

```dart
Widget _buildWelcomeStep(AppLocalizations t) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(t.onboardingWelcomeTitle, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 32),
      AppPrimaryButton(
        label: t.onboardingWelcomeStartFresh,
        onPressed: () => setState(() => _step = 1),
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: _onRestore,
        child: Text(t.onboardingWelcomeRestore),
      ),
    ],
  );
}

Future<void> _onRestore() async {
  // Push vers le login screen, en mode "onboarding" (le retour ne pop
  // pas vers Réglages mais reste dans l'onboarding flow).
  await context.push('/onboarding/cloud-login');
  // Si à la fin du flow login + restore, le user est connecté ET il a
  // restoré (provider settings non null), on quitte l'onboarding via
  // le router root.
}
```

- [ ] **Step 3: Ajouter la route `/onboarding/cloud-login`**

Dans `app_router.dart` :

```dart
GoRoute(
  path: '/onboarding/cloud-login',
  builder: (context, state) => const CloudLoginScreen(),
),
```

(Le même `CloudLoginScreen` est utilisé. Il pop quand `isCloudOptedIn` devient true — Task 21 — et le flow continue depuis l'onboarding.)

- [ ] **Step 4: Comportement post-login en mode onboarding**

Quand le user revient de magic link sur la route `/onboarding/cloud-login`, le pop revient à l'écran onboarding sur l'étape welcome. Là, le listener `isCloudOptedInProvider` (qui vit déjà dans `app.dart` Task 21+23) déclenche la résolution. **Différence importante** : en mode onboarding, le cas A (cloud vide) ne pushe pas un backup automatique (l'utilisateur n'a rien à sauvegarder pour l'instant) — on ramène simplement à l'étape adresse pour continuer l'onboarding normal.

Pour gérer ce cas, on ajoute un flag dans l'app state qui distingue le mode :

**Solution simple** : ajouter dans `OnboardingScreen` un `ref.listen` local qui réagit au `isCloudOptedInProvider`, et qui :
- Si `pushed=false` (cloud vide) : reste sur l'étape welcome ou push vers étape adresse (au choix UX — push direct ferait moins de friction).
- Si l'utilisateur a choisi « Restaurer » dans la modal et que le restore réussit : l'app skip l'onboarding (pop jusqu'à la racine et le router redirige vers `/` qui est l'écran principal puisque settings est non-null).

Le router doit savoir si settings existe pour rediriger : c'est probablement déjà le cas (cf. `CoupeLaineApp` qui décide d'afficher onboarding vs main selon `settings == null`). À vérifier dans `app_router.dart`.

```dart
// Dans onboarding_screen.dart, dans build :
ref.listen<bool>(isCloudOptedInProvider, (prev, curr) async {
  if (prev == false && curr == true) {
    final pushed = await ref
        .read(backupServiceProvider)
        .resolveInitialStateAfterOptIn();
    if (!mounted) return;
    if (pushed) {
      // Cloud vide — on continue l'onboarding normalement.
      // Avancer à l'étape adresse pour ne pas bloquer.
      setState(() => _step = 1);
    } else {
      // Cloud avec backups — afficher la modal.
      final choice = await showFirstSigninResolverDialog(context);
      if (choice == FirstSigninChoice.keepLocal) {
        // En onboarding, "garder local" ne fait pas sens (rien à garder)
        // → on continue l'onboarding.
        if (mounted) setState(() => _step = 1);
      } else if (choice == FirstSigninChoice.restoreCloud) {
        if (mounted) context.push('/onboarding/restore-pick');
      }
    }
  }
});
```

**Important** : pour éviter le double-listener (un dans `app.dart` et un dans onboarding), conditionner celui de `app.dart` sur la route courante. Le plus simple : dans `app.dart`, ajouter une garde :

```dart
ref.listen<bool>(isCloudOptedInProvider, (previous, current) async {
  if (previous == false && current == true) {
    final loc = GoRouterState.of(context).uri.path;
    if (loc.startsWith('/onboarding')) return; // géré par OnboardingScreen
    // ... le code existant
  }
});
```

- [ ] **Step 5: Vérifier la compilation**

```bash
flutter analyze
```

- [ ] **Step 6: Smoke test manuel — happy path restore**

1. Désinstaller l'app + réinstaller (ou supprimer la base SQLite locale via `flutter run -d <device>` après wipe data).
2. À l'écran onboarding step 0 (welcome), cliquer « Restaurer depuis une sauvegarde ».
3. Saisir l'email du compte cloud qui a au moins 1 backup.
4. Cliquer le magic link → app revient à onboarding.
5. Modal apparaît → choisir « Restaurer depuis le cloud ».
6. Picker apparaît, choisir le backup.
7. Restore se déroule → l'app pop vers l'écran principal avec les données restaurées.

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/onboarding/onboarding_screen.dart \
        lib/core/routing/app_router.dart \
        lib/app.dart \
        lib/l10n/app_fr.arb lib/l10n/app_en.arb
git commit -m "feat(cloud): onboarding welcome step — start fresh vs restore from backup"
```

---

## Phase J — Cleanup final

### Task 25: Supprimer `flutter_dotenv`, `.env`, et le fichier `Env.orsApiKey` legacy

**Files:**
- Delete: `.env`
- Verify: `pubspec.yaml` (déjà nettoyé Task 7)
- Verify: `lib/core/config/env.dart` (déjà refondu Task 8)
- Search: tout le code pour des références résiduelles à `dotenv`, `Env.orsApiKey`, `ORS_API_KEY`

- [ ] **Step 1: Vérifier qu'aucune référence ne subsiste**

```bash
grep -rn 'dotenv' lib/ test/ || echo "OK no dotenv references"
grep -rn 'orsApiKey\|ORS_API_KEY' lib/ test/ || echo "OK no ORS key references"
grep -rn 'flutter_dotenv' lib/ test/ pubspec.yaml || echo "OK no flutter_dotenv references"
```

Expected : tous renvoient « OK ».

- [ ] **Step 2: Supprimer le fichier `.env`**

```bash
rm .env
```

(S'il est dans `.gitignore`, vérifier que la suppression est bien tracée si `.env` était commité ; sinon `git status` ne montrera rien.)

```bash
git status
```

Si `.env` apparaît comme deleted, le stage. Sinon (ignoré par git), c'est juste un cleanup local.

- [ ] **Step 3: Smoke test final**

```bash
flutter clean
flutter pub get
flutter run
```

- App compile et démarre sans erreur.
- Tournée optimisée fonctionne (ORS via proxy).
- Réglages → cloud section visible.
- Sign-in → backup → backup picker → restore → tout passe.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore(cloud): drop .env file (last reference to flutter_dotenv removed)"
```

---

### Task 26: Mettre à jour `TODO.md` et la mémoire

**Files:**
- Modify: `TODO.md`

- [ ] **Step 1: Déplacer la feature #1 dans « Livrées »**

Dans `TODO.md`, retirer la section « 1. Synchronisation cloud — priorité haute » de « À venir » et ajouter dans « Livrées » :

```markdown
### Synchronisation cloud Phase 1 — backup/restore + ORS proxy
**Mergé sur `main`** — 2026-05-XX (commit de merge `<sha>`)
**Spec :** `docs/superpowers/specs/2026-05-01-cloud-sync-design.md`
**Plan :** `docs/superpowers/plans/2026-05-01-cloud-sync.md`

#### Ce qui a été livré
- Backup/restore mono-device via Supabase Storage (bucket privé `backups`, RLS).
- Auth magic link, sessions anonymes pour l'ORS proxy.
- ORS proxy via Edge Function — `ORS_API_KEY` n'est plus dans le bundle (dette résolue).
- Auto-backup au resume de l'app (gating 24h) + bouton manuel.
- Historique 3 backups glissants avec rotation auto.
- Restauration depuis onboarding (chemin nouveau device) ET depuis Réglages (récupération).
- Schema Drift v13 → v14 (ajout `Settings.lastBackupAt`) + transition vers migrations incrémentales.
- Bug latent fixé : `JsonExportService` couvrait 5 tables sur 9 — désormais complet.
```

- [ ] **Step 2: Mettre à jour la mémoire ORS**

Ajouter une entrée à la mémoire pour acter que la dette est résolue. Le fichier `MEMORY.md` doit être mis à jour pour pointer vers une nouvelle entrée ou supprimer l'ancienne :

Dans `C:\Users\rapha\.claude\projects\C--Users-rapha-Documents-Development-coupe-laine\memory\project_ors_key_prod_migration.md`, modifier le contenu pour acter la résolution OU supprimer le fichier et mettre à jour `MEMORY.md`. Un suivi-up post-merge à faire en interactif (cf. brainstorming skill instructions sur la mémoire).

**Action concrète** : ne pas modifier la mémoire dans le code. Mentionner dans le commit message que la dette est résolue, et faire la mise à jour mémoire dans la session de review post-merge.

- [ ] **Step 3: Commit final**

```bash
git add TODO.md
git commit -m "docs(todo): move cloud sync phase 1 to delivered + ORS_API_KEY debt resolved"
```

---

## Self-Review (résultat)

**Couverture de la spec :**
- §2 Architecture → Tasks 7-9, 13, 17 ✔
- §3 Auth → Tasks 13-14, 20-21 ✔
- §4 Sauvegarde → Tasks 17-18, 19 (UI) ✔
- §4.6 Première synchro → Task 23 ✔
- §5 Restauration → Tasks 22, 24 ✔
- §6 ORS proxy → Tasks 11-12 ✔
- §6.4 Sessions anonymes → Task 9 ✔
- §7 Modèle de données → Tasks 1, 5-6 ✔
- §7.1 Migration Drift incrémentale → Task 6 ✔
- §8 Versioning JSON → Tasks 2-3 ✔
- §9 Erreurs → couverte dans chaque task UI (snackbars, dialogs) ✔
- §10 Bug latent JsonExportService → Tasks 2-4 ✔
- §11 Tests → Tasks 4, 13, 16, 17 (parties testables) + smoke E2E manuels ✔
- §13 Deps → Task 7 ✔

**Placeholder scan :** OK — tous les snippets de code sont complets, les chemins sont absolus, les commandes sont concrètes. Les `{projectId}` / `{publicAnonKey}` dans `env.dart` sont des placeholders **à remplir par valeur réelle** à la Task 8 Step 2 (explicitement appelé), pas des placeholders de plan.

**Type consistency :** OK — `BackupMeta`, `JsonExportService.schemaVersion`, `Settings.lastBackupAt`, `AuthService.isCloudOptedIn`, `BackupService.runBackup/restore/listAvailable/resolveInitialStateAfterOptIn` sont nommés de manière cohérente entre les tasks où ils sont définis et utilisés.

---

**Plan complet et sauvegardé. Deux options d'exécution :**

**1. Subagent-Driven (recommandée)** — Je dispatche un subagent par task, je review entre chaque, itération rapide.

**2. Inline Execution** — Tasks exécutées dans cette session via `executing-plans`, exécution batch avec checkpoints.

**Laquelle ?**
