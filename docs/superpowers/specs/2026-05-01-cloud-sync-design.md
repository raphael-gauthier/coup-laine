# Synchronisation cloud — Phase 1 (backup/restore) + ORS proxy

**Date :** 2026-05-01
**Statut :** Spec validée, prête pour plan d'implémentation
**Périmètre TODO :** Feature #1 (« Synchronisation cloud — priorité haute ») + dette ORS_API_KEY

---

## 1. Objectif

Permettre à un utilisateur de :

1. Sauvegarder l'intégralité de ses données vers un backend cloud (snapshot complet, gzippé).
2. Restaurer ces données sur un nouvel appareil (changement de téléphone, réinstallation, perte).
3. Conserver un historique glissant de **3 sauvegardes** (filet de sécurité contre une corruption locale ou suppression accidentelle).

En même temps, **régler la dette technique `ORS_API_KEY`** : déplacer la clé OpenRouteService du bundle app (extractable) vers une fonction backend serveur-side.

**Hors scope (Phase 2, future spec)** : sync bidirectionnelle multi-device en temps réel, deltas par enregistrement, résolution de conflits, tombstones, edits concurrents. Cette spec choisit néanmoins un backend (Supabase / Postgres) qui rend la Phase 2 réalisable sans rework profond.

## 2. Architecture globale

**Backend choisi : Supabase**, projet hébergé en `eu-west-3` (Paris). Trois services Supabase utilisés :

- **Auth** : magic link email. Session JWT, persistée par le SDK dans `flutter_secure_storage` (Keychain iOS / EncryptedSharedPreferences Android).
- **Storage** : bucket privé `backups`, organisé en `{userId}/{ISO8601}.json.gz`.
- **Edge Functions** : une fonction `ors-proxy` qui détient `ORS_API_KEY` côté serveur et relaie les requêtes ORS.

**Côté app**, nouvelle couche `lib/infra/cloud/` :
- `SupabaseClient` (singleton, init dans `main.dart`).
- `AuthService` (sign-in magic link, sign-out, état session).
- `BackupService` (snapshot → upload, restore, listing, rotation).
- `BackupScheduler` (provider lifecycle-aware, déclenche les auto-backups).
- `OrsRoutingService` modifié pour passer par le proxy.

**Pas de schéma applicatif Postgres en Phase 1.** Les snapshots sont des blobs JSON dans Storage. Une seule table Postgres `backups` indexe les snapshots pour le listing et la rotation. Le schéma Drift local n'est modifié qu'en un point : ajout de `Settings.lastBackupAt`.

```
App (Flutter)
  ├── AuthService → Supabase Auth (magic link, sessions anonymes)
  ├── BackupService → Supabase Storage + table `backups`
  ├── OrsRoutingService → Edge Function `ors-proxy` → ORS API
  └── Drift DB (local, +1 colonne)
```

## 3. Authentification

### 3.1 Modèle

- Magic link email exclusivement. Pas de mot de passe.
- Création de compte automatique à la première connexion (`shouldCreateUser: true`).
- Session anonyme automatique au premier lancement de l'app, **avant** tout opt-in cloud — requise pour appeler `ors-proxy` (qui exige un JWT). Faite via `supabase.auth.signInAnonymously()`.
- Quand l'utilisateur opte in cloud, on appelle `supabase.auth.signInWithOtp(email)` (et **pas** `updateUser`). Cela couvre uniformément les deux cas — premier opt-in avec un email neuf ET restore sur nouveau device avec un email déjà utilisé. La session anonyme précédente est orphelinée (sans conséquence : aucun backup n'y est rattaché — l'auto-backup et le bouton manuel exigent une session non-anonyme).

### 3.2 Flow magic link

1. Utilisateur saisit email dans écran « Connexion cloud ».
2. App appelle `supabase.auth.signInWithOtp(email, emailRedirectTo: 'coupelaine://auth/callback')`.
3. Email envoyé par Supabase avec deep-link.
4. Utilisateur tape le lien → app s'ouvre sur le callback → SDK valide le token, persiste la session.
5. État global rebuild via `authSessionProvider` (Riverpod, expose `Session?`).

### 3.3 État de session côté app

- Provider `authSessionProvider : StreamProvider<Session?>` branché sur `supabase.auth.onAuthStateChange`.
- Provider `isCloudOptedInProvider : Provider<bool>` dérivé : `true` ssi session non-anonyme.
- Listener global pour piloter le `BackupScheduler`.

### 3.4 Sign-out

- Bouton dans Réglages → « Se déconnecter du cloud ».
- Confirmation : « Cela ne supprimera pas vos données locales. Vous pourrez vous reconnecter à tout moment. »
- Action : `supabase.auth.signOut()` (clear secure storage, invalide session). L'app **rouvre une session anonyme automatiquement** pour conserver l'accès au proxy ORS.

### 3.5 Cas d'erreur magic link

- Email invalide → erreur inline.
- Pas de réseau au `signInWithOtp` → snackbar « Pas de connexion. Réessayez plus tard. »
- Lien expiré (>1h) → écran d'erreur dédié dans le callback, bouton « Renvoyer un lien ».
- Lien ouvert sur autre device : autorisé par Supabase, le device qui ouvre devient connecté (comportement standard, accepté).

## 4. Sauvegarde

### 4.1 Trigger

`BackupScheduler` s'abonne à `AppLifecycleState`. À chaque transition `inactive → resumed` :

```
si (cloudOptIn ET (lastBackupAt == null OU > 24h ago) ET hasNetwork) {
  triggerBackup(silent: true)
}
```

Bouton manuel « Sauvegarder maintenant » dans Réglages → bypass des conditions de fraîcheur, exige seulement `cloudOptIn ET hasNetwork`. Loader pendant l'upload, snackbar succès/échec.

### 4.2 Snapshot format

Le payload est produit par `JsonExportService.exportToJsonString()`, **après complétion** des 4 tables manquantes (cf. §10).

- `JsonExportService.schemaVersion` : passe de `1` à `2`.
- Clés JSON : `schema, settings, clients, distanceMatrix, tours, tourStops, species, animalCategories, prestations, manualHistoryEntries`.

Le JSON est ensuite gzippé : `gzip.encode(utf8.encode(json))`. Volume estimé sur compte chargé : ~200kb → 50kb compressé.

### 4.3 Upload flow

1. Build du JSON via `JsonExportService.exportToJsonString()`.
2. Gzip → bytes.
3. `supabase.storage.from('backups').uploadBinary(path, bytes)` avec `upsert: false`. Le timestamp ISO8601 dans le path garantit l'unicité.
4. `INSERT INTO backups (user_id, storage_path, created_at, schema_version, size_bytes)` via le SDK.
5. **Rotation** : sélectionner les rows `WHERE user_id = X ORDER BY created_at DESC OFFSET 3`. Pour chaque ligne, supprimer le fichier Storage **puis** la ligne `backups`.
6. Mettre à jour `Settings.lastBackupAt = now()`.

### 4.4 Idempotence et concurrence

- Mutex en mémoire dans `BackupService` (`_backupInProgress: bool`) : empêche deux backups concurrents (clic répété sur le bouton manuel pendant un auto-backup en cours).
- L'auto-backup attend la fin du backup en cours plutôt que d'en lancer un en parallèle.

### 4.5 Affichage utilisateur (Réglages)

Section « Compte cloud » :
- Si non connecté : bouton « Activer la sauvegarde cloud ».
- Si connecté :
  - Email connecté.
  - « Dernière sauvegarde : il y a 3h » (dérivé de `Settings.lastBackupAt`, fallback « Jamais » si null).
  - Bouton « Sauvegarder maintenant ».
  - Bouton « Restaurer un backup » (visible si au moins 1 backup existe sur le compte).
  - Bouton « Se déconnecter du cloud ».

### 4.6 Première synchro après opt-in

Au moment où la session devient non-anonyme (premier login réussi), `BackupService.onSignInResolveInitialState()` est appelée :

- Query `SELECT count(*) FROM backups WHERE user_id = X`.
- **Cas A — 0 backup** : push automatique de l'état local comme premier backup. Toast « Sauvegarde initiale effectuée ».
- **Cas B — N≥1 backups existants** : modal explicite avec deux options :
  - « Garder les données de cet appareil » → push de l'état local comme nouveau backup (les anciens restent dans la fenêtre 3, pas écrasés).
  - « Restaurer depuis le cloud » → liste des backups disponibles (cf. §5).

Pas d'option « merge » — éliminée explicitement.

### 4.7 Cas d'erreur upload

| Cas | Mode auto | Mode manuel |
|---|---|---|
| Pas de réseau | Silencieux | Snackbar « Pas de connexion. » |
| 5xx Supabase | Silencieux + log | Snackbar « Sauvegarde échouée. Réessayez. » |
| Quota Storage dépassé (free tier ~1GB, improbable à court terme) | Silencieux + log | Snackbar « Stockage cloud plein. » |

Pas de retry automatique avec backoff dans cette spec — la prochaine ouverture de l'app retentera. KISS.

## 5. Restauration

### 5.1 Points d'entrée

**A. Onboarding (chemin principal nouveau device)**
Nouvelle première étape de `OnboardingScreen` (avant la saisie d'adresse) : écran « Bienvenue » avec deux options :
- « Démarrer à zéro » → onboarding existant (adresse → espèces).
- « Restaurer depuis une sauvegarde » → écran de connexion magic link → après login, écran « Backups disponibles » → sélection → confirmation → wipe + replace → l'app saute directement à l'écran principal (skip le reste de l'onboarding).

Si compte vide après login : message « Aucune sauvegarde trouvée pour ce compte » + boutons « Démarrer à zéro » / « Réessayer avec un autre email ».

**B. Réglages (chemin de récupération)**
Section « Compte cloud » → bouton « Restaurer un backup » → même écran « Backups disponibles ».

Confirmation **renforcée** vs onboarding : « Cela écrasera toutes les données actuelles de cet appareil. Action irréversible. » + champ de saisie « Tapez RESTAURER pour confirmer ».

### 5.2 Écran « Backups disponibles »

Liste 1 à 3 backups depuis la table `backups`, triés par `created_at desc` :

```
┌─────────────────────────────────────────┐
│ Aujourd'hui à 14:30 — 47 ko             │
│ Hier à 09:12 — 46 ko                    │
│ 28 avril à 18:55 — 44 ko                │
└─────────────────────────────────────────┘
```

Date relative (aujourd'hui / hier / date longue), taille en ko/Mo. Tap → confirmation (texte adapté selon point d'entrée) → restore.

### 5.3 Flow de restauration

1. `supabase.storage.from('backups').download(path)` → bytes gzip.
2. Gunzip → string JSON.
3. `jsonDecode` → map. Validation du champ `schema` :
   - `schema == JsonExportService.schemaVersion` → import direct.
   - `schema < JsonExportService.schemaVersion` → import direct (forward compatible — Drift remplit les nouvelles colonnes via défauts).
   - `schema > JsonExportService.schemaVersion` → erreur explicite, modal « Sauvegarde plus récente que cette version. Mettez à jour l'app. »
4. `JsonExportService.importFromJsonString(jsonString)` — déjà transactionnel : wipe + replace dans une seule transaction Drift, rollback automatique si erreur.
5. Invalidation des providers Riverpod racines (clients, tours, settings, species, prestations…). Implémentation pragmatique : `ref.invalidate()` sur la liste des providers root, OU pop jusqu'à la racine + remount.
6. `Settings.lastBackupAt` n'est pas modifié (reflète le moment du backup, pas du restore).
7. Toast « Restauration terminée » → écran principal.

### 5.4 Cas d'erreur restore

- **Pas de réseau pendant download** : retry manuel (bouton). Base locale intacte.
- **JSON corrompu / décodage qui plante** : la transaction Drift de `importFromJsonString` n'a pas démarré (le wipe est dedans). Toast erreur, état local préservé.
- **Échec à mi-import** : transaction Drift rollback automatique. Toast erreur, état local préservé.
- **Schema futur** : modal claire, bouton « Compris » (pas de lien store en Phase 1).

### 5.5 Hors scope

- Aperçu du contenu du backup avant restore.
- Restauration sélective (par type d'objet).
- Téléchargement local du `.json.gz` pour archive offline.

## 6. ORS proxy

### 6.1 Edge Function

Fonction `ors-proxy` (Deno/TypeScript), déployée via `supabase functions deploy ors-proxy`.

Pseudo-code (~50 lignes) :

```typescript
serve(async (req) => {
  // 1. Auth check : Supabase exécute la function avec verify_jwt par défaut → 401 si pas de JWT valide
  // 2. Parser le sub-path après /ors-proxy/ (ex. "v2/directions/driving-car/json", "v2/matrix/driving-car")
  const subPath = new URL(req.url).pathname.replace('/ors-proxy/', '');
  // 3. Forward vers ORS avec la clé serveur
  const orsResponse = await fetch(`https://api.openrouteservice.org/${subPath}`, {
    method: req.method,
    headers: {
      'Authorization': Deno.env.get('ORS_API_KEY')!,
      'Content-Type': 'application/json',
    },
    body: req.method === 'POST' ? await req.text() : undefined,
  });
  // 4. Relayer la réponse telle quelle
  return new Response(orsResponse.body, {
    status: orsResponse.status,
    headers: { 'Content-Type': 'application/json' },
  });
});
```

Variables d'env Supabase : `ORS_API_KEY` (set via `supabase secrets set ORS_API_KEY=...`).

### 6.2 Modifications côté app

Dans `lib/infra/services/ors_routing_service.dart` :
- Base URL : `https://{project}.supabase.co/functions/v1/ors-proxy`.
- Header `Authorization: {ORS_API_KEY}` remplacé par `Authorization: Bearer {supabase.auth.currentSession.accessToken}`.
- Idéalement, utiliser `supabase.functions.invoke('ors-proxy', body: ...)` qui gère le bearer automatiquement, sinon `http.post` avec header manuel.
- Comportement face aux erreurs ORS (5xx, 429, timeout) : inchangé. L'app a déjà des fallbacks (cf. commit `33a6a51` « close-loop straight-line fallback »).

### 6.3 Cutover

**Pas de feature flag runtime.** Hard cutover dans la même release :
- Edge Function déployée et testée en pré-prod avant merge.
- `OrsRoutingService` n'a plus qu'un seul chemin (proxy).
- Suppression dans le même PR :
  - Entrée `ORS_API_KEY` dans `.env`.
  - Asset `.env` dans `pubspec.yaml`.
  - Dépendance `flutter_dotenv` (à `pubspec.yaml`).
  - Code de chargement dotenv dans `lib/core/config/env.dart`.
- Les valeurs publiques Supabase (URL projet, clé anon) sont **hardcodées comme constantes** dans `lib/core/config/env.dart`.

### 6.4 Sessions anonymes pour utilisateurs sans cloud

Tout user a un JWT Supabase, même sans avoir entré son email. Au démarrage, si pas de session existante, `supabase.auth.signInAnonymously()` crée un user anonyme. Cette session permet d'appeler `ors-proxy` mais RLS empêche tout accès aux backups (qui sont scoped sur l'`auth.uid()` d'utilisateurs avec email).

Si plus tard l'utilisateur opte in cloud, on bascule sur un user email-permanent via `signInWithOtp` (cf. §3.1). L'identité anonyme précédente est orphelinée.

### 6.5 Hors scope ORS

- Pas de cache serveur des réponses ORS (l'app cache déjà côté `distance_matrix`).
- Pas de proxy pour BAN geocoding (clé non requise, BAN reste en direct).
- Pas de rate-limit custom au-delà de celui de Supabase Edge Functions.

## 7. Modèle de données

### 7.1 Côté app (Drift)

**Une seule modification de schéma** : `Settings.lastBackupAt`.

```dart
class SettingsTable extends Table {
  // ... colonnes existantes ...
  IntColumn get lastBackupAt => integer().nullable()();  // epoch ms, null = jamais
}
```

Migration Drift : `schemaVersion: 13 → 14`.

**Changement structurel important** : la stratégie de migration actuelle (`app_database.dart:39-49`) fait un wipe-and-recreate complet sous condition `from < 13`, justifié par l'absence d'utilisateurs en prod. Avec la sortie du cloud sync, **il y aura des utilisateurs réels avec des données qu'ils ne veulent pas perdre**. La migration v13 → v14 doit donc être un vrai `addColumn` qui préserve les données :

```dart
onUpgrade: (m, from, to) async {
  if (from < 13) {
    // Branche legacy pré-prod : wipe-and-recreate (inchangé).
    for (final table in allTables.toList().reversed) {
      await m.deleteTable(table.actualTableName);
    }
    await m.createAll();
    return;
  }
  if (from < 14) {
    await m.addColumn(settingsTable, settingsTable.lastBackupAt);
  }
}
```

Cette spec acte donc le passage à un régime de migrations incrémentales pour toutes les versions ≥ 13. Les futurs schemas (Phase 2 etc.) suivront le même pattern.

Aucune autre modification de schéma local. Pas de tombstones, pas de timestamps ajoutés ailleurs. Les tables qui ont déjà `updatedAt` le gardent ; les autres restent telles quelles. Phase 2 ajoutera ce qui manque le moment venu.

### 7.2 Côté Supabase

#### Table `backups`

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

Pas de policy `update` : un backup est immuable. La rotation delete + insert.

#### Bucket Storage `backups`

```sql
insert into storage.buckets (id, name, public) values ('backups', 'backups', false);

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

Le path est `{userId}/{timestamp}.json.gz`, donc `(storage.foldername(name))[1]` = `userId` → match avec `auth.uid()`.

#### Configuration auth (dashboard Supabase)

- Email magic link activé.
- Anonymous sign-ins activés (toggle `enable_anonymous_sign_ins`).
- Site URL : `coupelaine://auth/callback`.
- Redirect URLs whitelist : `coupelaine://auth/callback`.
- Template email magic link en français (sujet « Connexion à Coup'Laine »).

#### Edge Function secrets

```bash
supabase secrets set ORS_API_KEY=<la-clé-actuelle-du-.env>
```

### 7.3 Configuration côté app

`lib/core/config/env.dart` :

```dart
const supabaseUrl = 'https://{projectId}.supabase.co';
const supabaseAnonKey = '{publicAnonKey}';
```

Ces valeurs sont publiques par design Supabase et hardcodées en clair. Si un jour des environnements multiples (staging/prod) sont nécessaires, migration triviale vers `--dart-define`.

## 8. Versioning du format JSON

`JsonExportService.schemaVersion` passe de `1` à `2`. Politique de compatibilité au restore :

- `backup.schema == app.schema` → import direct.
- `backup.schema < app.schema` → import direct (forward compatible — Drift remplit les nouvelles colonnes via défauts).
- `backup.schema > app.schema` → erreur explicite (cf. §5.4).

Pas de migration JSON en Phase 1 (les schemas v1 existants n'ont pas été produits — la feature de cloud sync n'a jamais tourné en prod ; seul le `JsonExportService` manuel a pu produire v1, mais sans les 4 tables récentes, donc inutilisable de toute façon). Si un jour des backups v2 doivent être lus par une app v3, prévoir un `JsonImportService.migrateFromV2ToV3` à ce moment-là.

## 9. Gestion d'erreurs & observabilité

### 9.1 Principes

- Erreur en mode auto (backup au resume) → silencieuse pour l'utilisateur, log seulement.
- Erreur en mode manuel → message clair, pas de jargon.
- Aucune erreur ne doit casser l'usage local de l'app. Le cloud est strictement additionnel.

### 9.2 Inventaire

| Cas | Mode | UX |
|---|---|---|
| Pas de réseau au backup | Auto | Silencieux, log |
| Pas de réseau au backup | Manuel | Snackbar « Pas de connexion. » |
| 5xx Supabase upload | Auto | Silencieux, log |
| 5xx Supabase upload | Manuel | Snackbar « Sauvegarde échouée. » |
| Magic link expiré | — | Écran d'erreur, bouton « Renvoyer » |
| Restore download échoué | Manuel | Toast erreur, base locale intacte |
| Restore JSON corrompu | Manuel | Toast erreur, base locale intacte |
| Restore schema futur | Manuel | Modal claire |
| ORS proxy 401 | — | SDK Supabase refresh JWT auto + retry |
| ORS proxy 5xx/429 | — | Fallbacks ORS existants (straight-line) |

### 9.3 Logging et monitoring

- `debugPrint` pour tout en dev. Pas de Sentry/Crashlytics dans cette spec (à ajouter en follow-up dédié).
- Monitoring manuel des dashboards Supabase les premières semaines :
  - Storage : taille totale du bucket `backups`.
  - Auth : sign-ups, taux d'erreur magic link.
  - Edge Functions : logs `ors-proxy`, latence, taux d'erreur.

## 10. Bug latent corrigé en passant

`JsonExportService` actuel (`lib/infra/services/json_export_service.dart`) ne couvre que **5 tables sur 9** :

- ✅ Couvert : `settings`, `clients`, `distance_matrix`, `tours`, `tour_stops`.
- ❌ Manquant : `species`, `animal_categories`, `manual_history_entries`, `prestations`.

Les 4 manquants ont été ajoutés par les pivots multi-praticien (2026-04-30), historique manuel (2026-04-30) et catalogue prestations (2026-05-01). Le service n'a pas été tenu à jour. Le `TODO.md` ligne 202 affirme que les prestations sont incluses dans le round-trip — c'est faux dans le code actuel.

**Conséquence** : l'export/import manuel actuel perd ces 4 entités. Pour que le backup cloud soit utilisable, il faut compléter le service. Ajout estimé : ~80 lignes (5 selects, 5 inserts, 4 deletes dans le bon ordre FK pour respecter les contraintes), tests inclus.

Ordre de delete (FK descendantes) : `tour_stops, manual_history_entries, prestations, animal_categories, species, distance_matrix, tours, clients, settings`.

Ordre d'insert (FK ascendantes) : `settings, clients, species, animal_categories, prestations, distance_matrix, tours, tour_stops, manual_history_entries`.

## 11. Tests

### 11.1 Unitaires (Drift in-memory, mocks Supabase)

- **`JsonExportService` étendu** :
  - 4 tests round-trip (1 par table ajoutée : `species`, `animal_categories`, `prestations`, `manual_history_entries`).
  - 1 test round-trip complet sur base populée (toutes tables préservées).
  - 1 test refus de schema futur (`schema = 99`).
  - 1 test acceptation de schema passé (forward compat).
- **`BackupService.shouldRunAutoBackup`** : helper pur, ~6 cas — combinaisons `(cloudOptIn, lastBackupAt, hasNetwork)`.
- **`BackupService.rotateOldBackups`** : avec mock `BackupsRepository`, vérifier suppression au-delà des 3 plus récents (Storage + table).
- **`BackupService.onSignInResolveInitialState`** : mock listing 0 puis N backups, vérifier branchement (push auto vs prompt).
- **Validation du path Storage** : helper de génération `{userId}/{ISO8601}.json.gz`, test d'unicité sur timestamps proches.

### 11.2 Tests d'intégration

Pas requis en Phase 1. Couche Supabase testée manuellement contre l'environnement réel.

### 11.3 E2E manuel (smoke checklist QA)

- Onboarding « Démarrer à zéro » → app fonctionne, ORS marche (proxy en mode anon).
- Onboarding « Restaurer » → magic link → compte vide → message clair, fallback « Démarrer à zéro ».
- Réglages → opt-in cloud → compte vierge → premier backup auto pushé.
- Réglages → opt-in cloud → compte avec backups existants → modal de choix → restore fonctionne.
- Sauvegarde manuelle → vérification dashboard Supabase (file présent, ligne `backups` insérée).
- Auto-backup au resume après 24h+ : forcer en bidouillant `lastBackupAt` en base.
- Restore depuis Réglages → confirmation renforcée (RESTAURER) → wipe + replace observable (clients/tours différents avant/après).
- Tournée optimisée → ORS proxy → routes affichées comme avant le cutover.
- Sign-out → reconnexion anonyme silencieuse → ORS continue de fonctionner.

### 11.4 Volumétrie cible

~15 nouveaux tests automatisés. Suite passe de ~225 à ~240 verts.

## 12. Périmètre exclu (résumé)

- Sync bidirectionnelle multi-device (Phase 2).
- Tombstones / soft-delete sur les tables Drift.
- Conflict resolution / merges.
- Aperçu du contenu d'un backup avant restore.
- Restauration sélective.
- Export local du `.json.gz`.
- Sentry / Crashlytics.
- Rate-limit custom sur l'Edge Function.
- Proxy pour BAN geocoding.
- Gestion de compte (changer email, supprimer compte) : RGPD à la main pour l'instant.
- Multiple environnements Supabase (dev/staging/prod) : un seul projet en Phase 1.

## 13. Dépendances ajoutées / retirées

**Ajoutées** :
- `supabase_flutter` (ramène `gotrue`, `realtime`, `storage`, `flutter_secure_storage`).
- `archive` (ou similaire) pour `gzip.encode/decode` côté Dart.
- `app_links` ou équivalent pour gérer le deep-link `coupelaine://auth/callback` (probablement déjà présent ou trivial à ajouter).

**Retirées** :
- `flutter_dotenv`.

**Modifiées** :
- `pubspec.yaml` : asset `.env` retiré.

## 14. Articulation avec le futur (Phase 2)

Cette spec ne préempte pas les choix de la Phase 2. Points où on a explicitement préservé l'optionnalité :

- **Backend Postgres natif** : la Phase 2 (delta-sync) pourra créer des tables Postgres `clients`, `tours`, etc. mirroring le schéma Drift, avec RLS par `auth.uid()`. Architecture compatible avec des libs comme `powersync` ou une implémentation custom de log de changements.
- **`auth.users` stable** : le modèle d'identité ne change pas entre les phases. Un userId créé en Phase 1 reste valide en Phase 2.
- **Choix `signInWithOtp` plutôt que `updateUser`** : préserve la liberté d'évoluer le modèle d'identité sans dépendance à un upgrade-path anon→email préservant l'userId.

Ce qui restera à faire en Phase 2 (hors scope ici) :
- Ajout de `updatedAt` partout où il manque (settings, distance_matrix).
- Ajout de tombstones (soft-delete) ou log de changements.
- Définition d'une stratégie de résolution de conflits (last-write-wins ou autre).
- Sync engine côté app.
