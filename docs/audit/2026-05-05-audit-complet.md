# Audit complet — Coup'Laine RN/Expo

Date : 2026-05-05 · Branche : `main` · Périmètre : tout le code applicatif (`app/**`, `src/**`), config, dépendances.

Notation :
- **Sévérité** : `critique` (bloquant / risque réel) · `important` (incohérence visible ou faille latente) · `cosmétique` (polish).
- **Effort** : `S` (≤ 1h) · `M` (½ journée) · `L` (≥ 1 jour) · `XL` (chantier transverse).

Légende des IDs :
- `SEC-*` sécurité · `UX-*` UX/UI · `FORM-*` formulaires · `I18N-*` localisation · `A11Y-*` accessibilité · `DEP-*` dépendances.

---

## TL;DR — verdict global

**Solides** :
- Stack design propre et utilisée : `motion-tokens`, `Button`, `Text`, `Surface`, `ScreenHeader`, dark-mode parity, plus de `<Text>` natif, plus de `ms` magiques dans `app/`.
- Stockage de session via `expo-secure-store` ✓, `.env` correctement gitignored ✓, polyfill crypto bien placé ✓, pas de `Math.random` pour les IDs ✓, pas de fuite de session dans les logs ✓.
- i18n quasi propre : aucune chaîne FR oubliée dans le JSX, juste 7 clés référencées-mais-absentes du `fr.json`.

**Points chauds** :
1. **Sentry exfiltre potentiellement des PII** (`sendDefaultPii: true` + `enableLogs: true`).
2. **Sign-out laisse les données SQLite locales en place** → fuite de données entre comptes sur un même appareil.
3. **`wipeAndRestore` n'est pas transactionnel** → un échec partiel laisse la DB vidée.
4. **La pile formulaires "officielle" (`react-hook-form` + `zod`) n'est en réalité utilisée nulle part** : 0 import dans le repo malgré la règle CLAUDE.md et la mémoire `form-validation-pattern`. Layer 3 (haptique d'erreur) totalement absente.
5. **A11Y : 72 pressables sur 228 sans `accessibilityLabel`**, dont une bonne dizaine d'icon-only sub-44pt.
6. Plusieurs écrans paramètres sans `EmptyState` (cf. `settings/services/index.tsx`), couleurs hex dispersées dans 20+ écrans, FAB dupliqué 6 fois.

Aucune CVE bloquante en runtime — les 4 advisories `pnpm audit` sont toutes dans des transitives **dev** (`drizzle-kit`, `jest-expo`, `tailwindcss/postcss`).

---

## 1. Sécurité

### SEC-1 · `critique` · `S` — Sentry `sendDefaultPii: true` + `enableLogs: true`
- `app/_layout.tsx:34,37`
- Toute exception qui embarque un `Client` (nom, téléphones, adresse, lat/lon) sera envoyée à Sentry. `sendDefaultPii` ajoute IP et cookies. Aucun `beforeSend` scrubber.
- **Fix** : `sendDefaultPii: false`, `enableLogs: false` en prod, `beforeSend` qui strip `phones`, `email`, `addressLabel`, `latitude/longitude`, et toute clé préfixée `client*`.

### SEC-2 · `critique` · `M` — Sign-out ne purge pas la SQLite locale
- `src/state/queries/auth.ts:101-115`
- Scénario : utilisateur A signe avec email A → sign-out → utilisateur B signe avec email B → B voit les clients/historique de A jusqu'à un éventuel restore.
- **Fix** : sur succès de `signOut`, dropper toutes les tables (ou `db.delete` chacune) puis re-bootstrap. Penser au cas anonymous → email aussi.

### SEC-3 · `critique` · `S` — `wipeAndRestore` non-transactionnel
- `src/infra/cloud/backups.ts:50-70`
- 9 deletes + boucles d'inserts en statements séparés. Crash / OOM / FK error mid-restore = DB vidée sans rollback.
- **Fix** : `db.transaction(async (tx) => { … })`. Tout dedans. Bonus : valider la JSON avec `zod` avant insert (cf. SEC-4).

### SEC-4 · `important` · `M` — Backup JSON inséré sans validation
- `backups.ts:124-129`
- Seul `schemaVersion === 2` est vérifié. Les `tables.*` sont cast `$inferInsert` aveuglément. NULL dans NOT NULL, FK invalides, strings hors-borne → crashes ou données corrompues.
- **Fix** : un schéma `zod` par table (réutiliser `src/domain/models/*` si possible), valider avant `insert`, dans la même transaction que SEC-3.

### SEC-5 · `important` · `S` — Vérifier la restriction de la clé MapTiler
- `.env` + dashboard MapTiler
- La clé est bundlée dans l'APK (normal pour `EXPO_PUBLIC_*`). Si elle n'est pas restreinte au bundle ID `fr.raphaelgauthier.couplaine`, n'importe qui peut drainer le quota.
- **Fix** : ouvrir le dashboard MapTiler → restreindre la clé au bundle ID Android + iOS.

### SEC-6 · `important` · `S` — Vérifier RLS du bucket `backups`
- Côté Supabase dashboard
- Le code écrit dans `${uid}/{filename}.json`. Il faut s'assurer que la policy SELECT/INSERT/DELETE exige `auth.uid()::text = (storage.foldername(name))[1]`.
- **Fix** : vérifier dans le SQL editor Supabase. Ne peut pas être audité depuis le client.

### SEC-7 · `important` · `M` — Anonymous → email avec email existant orphelinise les backups
- `src/state/queries/auth.ts:58-75`
- Quand l'email est déjà pris, code fait `signOut` + `signInWithOtp` → uid change → backups cloud sous ancien uid bloqués par RLS.
- **Fix** : a minima afficher un avertissement explicite avant le fallback. Idéal : snapshoter les données locales puis les ré-uploader sous le nouveau uid.

### SEC-8 · `cosmétique` · `S` — Données SQLite non chiffrées
- `src/infra/db/client.ts`
- Pour le threat model "téléphone perdu", iOS file protection + sandbox Android sont généralement suffisants. À documenter explicitement, ou migrer vers `op-sqlite` + SQLCipher si la sensibilité augmente (clé en `SecureStore`).

### SEC-9 · `cosmétique` · `S` — Fallbacks silencieux
- `app/_layout.tsx:94` (`ensureAnonymousSession` fire-and-forget) et phones/addresses passés à `Linking.openURL` sans regex de validation (`client-pin-popup.tsx:84,89,99`).
- **Fix** : envoyer les erreurs `ensureAnonymousSession` à Sentry (après scrubbing) ; valider les téléphones avec `/^\+?[\d\s().-]+$/` avant `tel:`/`sms:`.

### Confirmé propre (pas d'action)
- `.env*` gitignored, pas de `AsyncStorage` pour data sensible, polyfill `react-native-get-random-values` en première ligne de `app/_layout.tsx`, pas de `Math.random` pour IDs, pas de deep-link param-handler exécutant des mutations, BAN/ORS encodent leurs URLs proprement.

---

## 2. UX / UI

### UX-1 · `important` · `S` — `EmptyState` manquant sur 4 écrans paramètres
- `app/(tabs)/settings/services/index.tsx` (déjà flagué par toi)
- `app/(tabs)/settings/species/index.tsx`
- `app/(tabs)/settings/species/[id]/categories/index.tsx`
- `app/(tabs)/settings/species/[id].tsx:28-30` (fallback `<Surface flex-1 />` quand espèce introuvable)
- **Fix** : utiliser `<EmptyState>` existant, mirror de `tours/index.tsx`.

### UX-2 · `important` · `S` — Skeletons / loaders manquants
- `app/(tabs)/clients/[id]/history/index.tsx` (pas de skeleton initial)
- `app/(tabs)/proximity/index.tsx`, `app/(tabs)/map/index.tsx` (queries clients silencieuses)
- **Fix** : ajouter `Skeleton` ou `ActivityIndicator` selon le pattern existant dans `clients/index.tsx`.

### UX-3 · `important` · `M` — `mutation onError` absent sur 9 écrans
- `clients/[id]/history/[entryId].tsx:45,69` · `clients/[id]/history/new.tsx:24`
- `settings/services/new.tsx:23` · `settings/services/[id].tsx:37,60`
- `settings/species/new.tsx:23` · `settings/species/[id].tsx:42,68`
- `settings/species/[id]/categories/new.tsx:25` · `settings/species/[id]/categories/[categoryId].tsx:37,61`
- Viole le 3-layer `form-validation-pattern` : feedback silencieux en cas d'échec serveur/DB.
- **Fix** : ajouter `onError: mutationErrorToast(t, '...')` sur chaque mutation.

### UX-4 · `important` · `S` — Couleurs hex dispersées dans 20+ écrans
- `#A1602F` (primary) → 8 fichiers d'auth/onboarding
- `#5C4E40` (muted-fg) → 12 emplacements icônes lucide
- `#D9534F` → `clients/[id].tsx:186,187` (utiliser `text-danger` à la place)
- `#C88226` (waiting) → `clients/[id].tsx:145`
- `#FAF6F0`, `#1C1612` → `auth/login.tsx:93`
- **Fix** : créer `useMutedForegroundColor()` / `useDangerColor()` / etc. à côté de `useOnContrastColor` (`src/ui/theme/colors.ts`), et faire les remplacements.

### UX-5 · `important` · `M` — FAB dupliqué 6 fois
- `clients/index.tsx:121` · `tours/index.tsx:89` · `clients/[id]/history/index.tsx:67` · `settings/services/index.tsx:119` · `settings/species/index.tsx:52` · `settings/species/[id]/categories/index.tsx:52`
- Mêmes magic numbers (`bottom:24, right:24, shadowRadius:6, elevation:6, #000`).
- **Fix** : extraire `<Fab icon onPress accessibilityLabel />` dans `src/ui/components/fab.tsx`.

### UX-6 · `cosmétique` · `S` — `clients/[id].tsx` utilise un `<Modal>` raw + `TouchableOpacity` scrim
- `app/(tabs)/clients/[id].tsx:2,168-194`
- Incohérent avec `<CreateTourSheet>` (sheet primitive) utilisé ailleurs.
- **Fix** : extraire un composant `<ActionSheet>` ou utiliser le pattern de `create-tour-sheet`.

### Confirmé propre (pas d'action)
- 33/33 écrans utilisent `ScreenHeader`. Pas de durée `ms` magique dans `app/`. Aucun import `Text` depuis `react-native`. Dark-mode parity : 100%. Spacing globalement cohérent (`px-4`, `gap-2/3`, `rounded-2xl`).

---

## 3. Formulaires

### FORM-1 · `critique` · `XL` — La pile RHF + zod n'est utilisée nulle part
- 0 import de `react-hook-form`, `@hookform/resolvers`, `zod` dans tout le repo (sauf `package.json`). Les 18+ formulaires sont en `useState` + `useMemo`.
- Contredit la règle CLAUDE.md §5 + la mémoire `form-validation-pattern`.
- **Fix** : décision projet — soit (a) on assume la pile actuelle et on met à jour la doc, soit (b) on migre incrémentalement (commencer par `client-form` qui est le plus complexe). Mon avis : (b), avec un wrapper `FormField` qui standardise label + erreur inline + `accessibilityLabel`.

### FORM-2 · `critique` · `S` — `haptics.notificationError` totalement absent
- 0 hit en grep sur tout le repo.
- Layer 3 du `form-validation-pattern`.
- **Fix** : à câbler en même temps que FORM-1, dans `handleSubmit` quand la validation échoue.

### FORM-3 · `important` · `M` — Erreurs inline partielles
- Bons élèves : `client-form`, `service-form`, `manual-history-form`, `auth/login`.
- À renforcer : `species-form`, `animal-category-form`, `phones-editor`, `animal-counts-editor`, settings/onboarding (souvent reposent juste sur `disabled`-the-submit).
- **Fix** : afficher `errors[name]?.message` sous chaque champ requis (cf. FORM-1 wrapper).

### FORM-4 · `important` · `M` — Schémas absents ou faibles
- `phones-editor` : pas de validation E.164/FR-mobile.
- `service-form` : `priceCents = null` accepté silencieusement.
- `tour-rate.tsx`, `proximity.tsx`, `season.tsx` : pas de bounds check.
- **Fix** : à faire pendant la migration zod (FORM-1).

---

## 4. i18n

### I18N-1 · `important` · `S` — 1 clé vraiment manquante (correction du rapport initial)
| Clé | Fichier |
|---|---|
| `clients.no_services` | `last-interventions-list.tsx:56` |

Vérification a posteriori : les 6 autres "manquantes" listées par l'agent (`onboarding.recap.species_count`, `recompute.banner_title`, `tours.no_service_warning_message`, `tours.optimized_commune_option`, `tours.stop_summary`, `tours.stops_count`) sont des **formes plurielles i18next** — leurs déclinaisons `_one`/`_other` existent dans `fr.json` (lignes 165, 181, 193, 244, 466, 513). i18next résout `t('foo', { count })` via les suffixes `_one`/`_other`. Pas d'action.

Bonus : la clé existante `clients.no_prestations` est en français (viole CLAUDE.md §6, identifiants en anglais) et n'a aucun caller. Renommée en `clients.no_services` au passage.

### I18N-2 · `cosmétique` · `S` — Placeholders littéraux
- `species-form.tsx:55` (`"mouton"`)
- `service-form.tsx:99,113` (`"0,00"`, `"20"`)
- `phones-editor.tsx:72` (`"06 12 34 56 78"`)
- Format FR mais reste un littéral en JSX. Mineur.
- **Fix** : passer par `t('...')` pour cohérence stricte.

---

## 5. Accessibilité

### A11Y-1 · `critique` · `M` — 72 pressables sur 228 sans `accessibilityLabel`
- Liste d'icon-only critiques : `phones-editor.tsx:75` (X), `animal-counts-editor.tsx:46,57` (-/+), `client-pin-popup.tsx:122` (X), `create-tour-sheet.tsx:40,46,64`, `color-picker-sheet.tsx:57,74`, `map-layer-dialog.tsx:19,32,44`, `address-autocomplete-input.tsx:86`, `clients/[id].tsx:143,176,184`, `proximity/index.tsx:73,113`, `marker-colors.tsx:78`, `season.tsx:58`, `tours/new/optimized-config.tsx:136,204`, `manual-history-form.tsx:53`.
- **Fix** : `accessibilityLabel={t('...')}` partout. Le primitive `Button` est déjà OK ; le problème vient des `PressScale` ad hoc.

### A11Y-2 · `important` · `S` — `accessibilityRole` quasi-absent
- Seuls 4 fichiers en utilisent (`button.tsx`, `themed-switch.tsx`, `screen-header.tsx`, `client-card.tsx`).
- **Fix** : `accessibilityRole="button"` (ou `link`/`switch`/`header`) systématique sur les pressables ; idéalement embarquer dans `PressScale`.

### A11Y-3 · `important` · `S` — Touch targets sous 44pt
- `client-pin-popup.tsx:122` : `p-1` (≈ 30×30pt)
- `animal-counts-editor.tsx:52,63` : `w-9 h-9` (36×36pt)
- `phones-editor.tsx:76` : `w-10 h-10` (40×40pt)
- **Fix** : `w-11 h-11` minimum, ou `hitSlop={{top:8,bottom:8,left:8,right:8}}`.

### A11Y-4 · `important` · `S` — Champs `<Input>` sans `accessibilityLabel`
- Le primitive `Input` forwarde la prop mais aucun caller ne la passe. Les labels visibles `<Text>` au-dessus ne sont pas associés programmatiquement → screen reader énonce le champ sans contexte.
- **Fix** : `<Input accessibilityLabel={label}>` partout. Mieux : un wrapper `FormField` (à coupler avec FORM-1).

### A11Y-5 · `cosmétique` · `S` — Swatches couleur sans label
- `color-picker-sheet.tsx`, `marker-colors.tsx` : sélection signalée par le ring, sans `accessibilityLabel` ni `accessibilityState`.
- **Fix** : `accessibilityLabel={t('color.<name>')}` + `accessibilityState={{ selected }}`.

---

## 6. Dépendances

`pnpm audit` retourne 4 advisories — **toutes en transitives dev**, aucune en runtime :

| ID | Module | Sévérité | Chaîne | Fix |
|---|---|---|---|---|
| GHSA-67mh-4wv8-2f99 | `esbuild` <0.25.0 | moderate | `drizzle-kit > @esbuild-kit/...` | Resté ouvert tant que `drizzle-kit` ne bump pas — uniquement dev server, pas d'impact prod |
| GHSA-qx2v-qp2m-jg93 | `postcss` <8.5.10 (CVE-2026-41305) | moderate | `tailwindcss > postcss` | `pnpm update postcss` (override) |
| GHSA-w5hq-g745-h8pq | `uuid` <14.0.0 (xcode) | moderate | `jest-expo > @expo/config > xcode > uuid` | Out-of-band fix — attendre bump `xcode`. Notre runtime utilise `uuid@14.0.0` ✓ |
| GHSA-vpq2-c234-7xj6 | `@tootallnate/once` <3.0.1 (CVE-2026-3449) | low | `jest-expo > jsdom > ...` | Idem — bump amont |

### DEP-1 · `cosmétique` · `S` — Override `postcss`
Ajouter dans `package.json` :
```json
"pnpm": { "overrides": { "postcss": "^8.5.10" } }
```

---

## Synthèse priorisée

| ✓ | Rang | ID | Sévérité | Effort | Sujet |
|---|---|---|---|---|---|
| ☑ | 1 | SEC-1 | critique | S | Sentry PII scrubbing |
| ☑ | 2 | SEC-3 | critique | S | `wipeAndRestore` transactionnel |
| ☑ | 3 | SEC-2 | critique | M | Wipe SQLite au sign-out (avec dialogue de confirmation) |
| ☑ | 4 | I18N-1 | important | S | Clé `clients.no_services` (rapport revu — voir I18N-1) |
| ☐ | 5 | SEC-5/6 | important | S | Vérifs MapTiler + RLS Supabase (dashboards) |
| ☑ | 6 | SEC-4 | important | M | Validation zod du JSON de backup |
| ☑ | 7 | UX-1/2/3 | important | M | Empty/loading/error states (UX-3 était un faux positif — onError déjà au niveau hook) |
| ☑ | 8 | A11Y-1 | important | M | `accessibilityLabel` obligatoire (TS-required dans `PressScale`) |
| ☑ | 9 | A11Y-2/4 | important | M | `accessibilityRole="button"` par défaut dans `PressScale` (A11Y-2). `Input.accessibilityLabel` TS-required + 18 callers fixés (A11Y-4). A11Y-3 reste partiel (3/3 cibles connues bumpées). |
| ☑ | 10 | UX-4 | important | M | Tokeniser les hex restants (28 occurrences sur 16 fichiers) |
| ☑ | 11 | UX-5 | important | M | Primitive `<Fab>` (6 call-sites dédupliqués) |
| ☑ | 12 | FORM-1/2 | critique | XL | Migration RHF + zod + haptics : 6 formulaires migrés (5 forms réutilisables + auth/login + tour-rate). `FormField` + `RHFTextField` créés. `haptics.error()` câblé sur tous les `onInvalid`. Settings sans validation (base/season/proximity/marker-colors) laissés en useState. |
| ☑ | 13 | DEP-1 | cosmétique | S | Override `postcss` |
| ☑ | 14 | SEC-7/8/9 | cosmétique | S–M | Polish sécurité |

### Décisions actées (2026-05-05)
- **FORM-1** → on migre vers `react-hook-form` + `zod`. La règle CLAUDE.md reste, on rattrape le code.
- **A11Y-1** → on rend `accessibilityLabel` **TypeScript-required** dans `PressScale` pour empêcher toute régression future (pas un patch, un type-level fix).
- **SEC-2** → on purge la SQLite au sign-out, mais après un **`<ConfirmDialog>`** qui prévient l'utilisateur que toutes les données locales seront effacées.

---

## Périmètres non auditables sans accès dashboard

- Restriction de la clé MapTiler (bundle ID).
- Policies RLS Supabase (tables + bucket `backups`).
- Edge function `ors-proxy` : doit exiger un JWT valide.

À vérifier manuellement dans les consoles correspondantes.
