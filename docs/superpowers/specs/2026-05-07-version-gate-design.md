# Version gate — design

**Date:** 2026-05-07
**Scope:** Compare la version installée de l'app avec une configuration distante (Supabase) pour proposer une mise à jour soft (modal dismissable) ou forcer la mise à jour (écran bloquant) — typiquement pour patcher une faille de sécurité hors cycle store.

## 1. Goals

- Détecter à chaque cold start (et au retour foreground après 6h) si l'app installée est en retard sur la dernière version publiée.
- Afficher un soft prompt dismissable (snooze 7 jours) quand `installed < latest_version` et `installed >= min_supported_version`.
- Bloquer l'app derrière un écran plein non-dismissable quand `installed < min_supported_version`, avec une échappatoire RGPD (export + suppression de compte) pour ne jamais verrouiller un utilisateur hors de ses droits art. 15/17/20.
- Fail open : si le check échoue (offline, edge function down) on s'appuie sur le cache local ; sans cache on laisse passer. Une décision déjà honorée le reste, même hors-ligne.
- Couvrir iOS et Android indépendamment (versions divergentes possibles à cause des cycles de review Apple).

## 2. Non-goals

- OTA / hotfix JS via `expo-updates` (autre projet, hors scope).
- Pipeline CI qui publie automatiquement la nouvelle version dans la table à chaque build EAS — pour le MVP, on édite la row à la main dans le dashboard Supabase au moment de chaque release.
- Granularité par utilisateur, par cohorte, ou rollout canary. Tout le monde voit la même `min_supported_version`.
- Force-update au milieu d'une session déjà ouverte (un user déjà passé par le gate au cold start ne sera bloqué qu'au prochain retour foreground avec le debounce 6h, ou au prochain cold start). Volontaire : interrompre l'édition d'une tournée serait pire que d'attendre.
- Gestion explicite du downgrade (APK side-loaded). Détecté comme `force-update` si sous le seuil, point.
- Historique des versions / changelogs in-app au-delà des release notes de la dernière release. Pas de page « What's new ».

## 3. Architecture d'ensemble

```
┌──────────────────────┐         ┌──────────────────────┐
│  Edge Function       │  SQL    │  Supabase table      │
│  GET /version-check  │ ──────▶ │  app_versions        │
│  (public, no auth)   │         │  PK: platform        │
└──────────┬───────────┘         └──────────────────────┘
           │ JSON {latest, minSupported, security, …}
           ▼
┌─────────────────────────────────────────────────────────┐
│  RN app (boot, AVANT le router)                         │
│                                                         │
│  app/_layout.tsx                                        │
│   └── <VersionGateProvider>                             │
│        ├── force ─▶ <ForceUpdateScreen />               │
│        ├── soft  ─▶ <Stack /> + <SoftUpdateModal />     │
│        └── ok    ─▶ <Stack />                           │
└─────────────────────────────────────────────────────────┘
```

Le check tourne dans le `_layout.tsx` racine, **avant** le `<Stack>`, pour pouvoir bloquer l'accès même en pré-login. Trigger : cold start systématique + `AppState` listener (foreground) avec debounce 6h.

## 4. Backend Supabase

### 4.1 Table `app_versions`

```sql
create table app_versions (
  platform              text primary key check (platform in ('ios','android')),
  latest_version        text not null,                  -- semver: '0.11.0'
  min_supported_version text not null,                  -- semver: '0.10.0'
  security_flag         boolean not null default false, -- info UX seulement (badge ⚠️)
  release_notes_fr      text,                           -- markdown court
  store_url             text not null,
  updated_at            timestamptz not null default now()
);

alter table app_versions enable row level security;

create policy "public read"
  on app_versions for select
  to anon, authenticated
  using (true);

-- INSERT/UPDATE/DELETE réservés au service_role (édition manuelle dashboard).
```

Seed initial à la livraison :

| platform | latest_version | min_supported_version | security_flag | store_url |
|---|---|---|---|---|
| ios     | (version courante) | (version courante) | false | App Store URL après publication |
| android | (version courante) | (version courante) | false | Play Store URL après publication |

### 4.2 Edge function `version-check`

Path : `supabase/functions/version-check/index.ts`. Suit la convention des autres edge functions du repo (`delete-account`, `ors-proxy`).

**Contrat HTTP** — `GET /functions/v1/version-check?platform=ios|android` :

```jsonc
// 200 OK
{
  "platform": "ios",
  "latestVersion": "0.11.0",
  "minSupportedVersion": "0.10.0",
  "securityFlag": false,
  "releaseNotesFr": "- Tournée optimisée plus rapide\n- Correctifs",
  "storeUrl": "https://apps.apple.com/app/id..."
}
```

- `400` si `platform` manquant ou hors `('ios','android')`.
- `404` si la row n'existe pas pour la plateforme demandée.
- Pas d'auth (lecture publique). Headers de réponse : `Cache-Control: public, max-age=300` (si une couche de cache la respecte tant mieux ; sinon le cache SecureStore côté app reste le levier principal).
- Anti-abus : on s'appuie sur le rate-limiting natif Supabase, pas de logique custom.

## 5. Décision : `evaluateVersionStatus`

Use case **pur**, testé en vitest. Aucune dépendance sur le réseau, le cache, ou React.

```ts
// src/domain/models/version-status.ts
export type VersionConfig = {
  latestVersion: string;
  minSupportedVersion: string;
  securityFlag: boolean;
  releaseNotesFr: string | null;
  storeUrl: string;
};

export type VersionDecision =
  | { kind: 'ok' }
  | {
      kind: 'soft-update';
      latest: string;
      releaseNotesFr: string | null;
      security: boolean;
      storeUrl: string;
    }
  | { kind: 'force-update'; minSupported: string; storeUrl: string };
```

```ts
// src/domain/use-cases/evaluate-version-status.ts
export function evaluateVersionStatus(
  installed: string,
  config: VersionConfig,
): VersionDecision {
  if (compareSemver(installed, config.minSupportedVersion) < 0) {
    return {
      kind: 'force-update',
      minSupported: config.minSupportedVersion,
      storeUrl: config.storeUrl,
    };
  }
  if (compareSemver(installed, config.latestVersion) < 0) {
    return {
      kind: 'soft-update',
      latest: config.latestVersion,
      releaseNotesFr: config.releaseNotesFr,
      security: config.securityFlag,
      storeUrl: config.storeUrl,
    };
  }
  return { kind: 'ok' };
}
```

`compareSemver(a, b)` → `-1 | 0 | 1`. Implémentation locale (~15 lignes), pas de dep `semver`. Suffixes prerelease (`0.10.0-beta.1`) traités comme la version stable correspondante (la pratique en pre-release s'appuie sur des dev builds non concernés par le gate). Versions malformées → on logge dans Sentry et on retourne `'ok'` (fail open).

## 6. Composants côté app

Découpage conforme à l'archi Clean du repo (`domain` / `data` / `infra` / `state` / `ui`).

```
src/
├── domain/
│   ├── models/version-status.ts
│   └── use-cases/
│       ├── evaluate-version-status.ts
│       └── compare-semver.ts
│
├── infra/
│   └── services/version-check-api.ts        # fetch HTTP + Zod parse
│
├── data/
│   └── repositories/version-config-repository.ts  # API + cache SecureStore
│
├── state/
│   ├── queries/version-status.ts            # useVersionStatusQuery (TanStack)
│   └── hooks/
│       ├── use-version-gate.ts              # combine query + AppState debounce
│       └── use-soft-update-snooze.ts        # SecureStore read/write snooze
│
└── ui/
    └── version-gate/
        ├── version-gate-provider.tsx        # Wrapper : décide quoi rendre
        ├── force-update-screen.tsx          # Plein écran, 3 actions
        └── soft-update-modal.tsx            # Modal dismissable
```

### 6.1 `versionConfigRepository`

```ts
type Result =
  | { status: 'fresh'; config: VersionConfig }
  | { status: 'stale'; config: VersionConfig }       // cache servi car fetch échoué
  | { status: 'unavailable'; config: null };         // pas de cache, fetch échoué

getConfig(platform: 'ios' | 'android'): Promise<Result>
```

- Timeout fetch : 3s.
- Cache : SecureStore key `version-gate.cache.{platform}` = `{ config, fetchedAt }`.
- TTL « fresh » : 24h. Au-delà, on retente le fetch ; si fail, on renvoie le cache avec `status: 'stale'` (toujours utilisable, en particulier pour qu'un force-update vu une fois reste appliqué offline).
- Si JSON cache corrompu (parse error) : on l'ignore et on retente le fetch comme s'il n'y avait pas de cache.

### 6.2 `useVersionGate`

```ts
type GateState =
  | { kind: 'loading' }
  | { kind: 'decided'; decision: VersionDecision };

useVersionGate(): GateState
```

- Lit la version installée via `Application.nativeApplicationVersion` (paquet `expo-application` à ajouter — déjà dans l'écosystème Expo SDK 54).
- Lit la plateforme via `Platform.OS`.
- Wrappe `useVersionStatusQuery` (TanStack, `staleTime: 6h`, `gcTime: 24h`). Le `staleTime` côté TanStack contrôle quand la query React est considérée comme « à rafraîchir » ; il est volontairement plus court (6h) que la freshness du cache SecureStore (24h, cf. §6.1) qui sert de filet de sécurité offline.
- Listener `AppState` : sur transition `background → active`, si `staleTime` dépassé, `refetch()`.
- Si le repo retourne `status: 'unavailable'` (pas de cache + fetch échoué) → décision `ok` (fail open).
- Si `Platform.OS === 'web'` → décision `ok` immédiate, pas de fetch (l'app cible iOS + Android, le web build n'a pas de store de référence).
- Pendant `loading` : on ne rend rien (splash Expo natif déjà visible, pas de double écran).

### 6.3 `<VersionGateProvider>`

Monté dans `app/_layout.tsx`, entoure `<Stack>` :

```tsx
<VersionGateProvider>
  <Stack />
</VersionGateProvider>
```

Logique :

- `loading` → `null` (splash natif visible).
- `force-update` → `<ForceUpdateScreen />`, `<Stack>` jamais monté.
- `soft-update` → si version pas snoozée, render `<>{children}<SoftUpdateModal /></>`. Sinon render `children` seul.
- `ok` → render `children`.

### 6.4 `<ForceUpdateScreen />`

Plein écran, fond `Surface`, layout vertical centré.

- Titre : `t('versionGate.force.title')` — « Mise à jour requise »
- Sous-titre : `t('versionGate.force.subtitle')` — « Cette version n'est plus prise en charge. Mettez à jour pour continuer. »
- Si `securityFlag === true` : badge ⚠️ + `t('versionGate.force.securityNote')`.
- CTA primaire : `<PressScale>` + haptic → `Linking.openURL(storeUrl)`. Label `t('versionGate.force.cta.update')`.
- Section secondaire « Vos données » avec deux liens texte :
  - `t('versionGate.force.cta.export')` → réutilise hook `useExportData` (déjà existant cf. RGPD MVP).
  - `t('versionGate.force.cta.deleteAccount')` → réutilise hook `useDeleteAccount` (déjà existant) + confirmation typée.
- Si pas de session active (`useAuth().session === null`), les deux liens « Vos données » sont remplacés par un texte d'aide `t('versionGate.force.cta.signInToManageData')` qui pointe vers le login. Le user logué peut alors exporter / supprimer ses données et **revient automatiquement sur le ForceUpdateScreen** une fois logué (le gate reste actif tant que la version est sous `minSupportedVersion`).

### 6.5 `<SoftUpdateModal />`

Modal centrée, dismissable.

- Titre : `t('versionGate.soft.title')` — « Une mise à jour est disponible »
- Si `security === true` : badge ⚠️ + `t('versionGate.soft.securityNote')`.
- Release notes FR (markdown simple : listes à puces, gras) ou fallback `t('versionGate.soft.fallbackNotes')`.
- CTA primaire : « Mettre à jour » → `Linking.openURL(storeUrl)`.
- CTA secondaire : « Plus tard » → snooze + close.

### 6.6 Snooze logic

`useSoftUpdateSnooze` lit/écrit SecureStore :

```ts
type Snooze = { version: string; until: number /* epoch ms */ };
```

Re-prompt si :
- pas de snooze stocké, ou
- `now > until`, ou
- `latestVersion` (config) ≠ `version` (snooze).

À chaque dismiss du soft modal : `setSnooze({ version: latest, until: now + 7 * 24 * 3600 * 1000 })`.

Pas de snooze possible sur force-update : l'écran n'a pas de bouton de fermeture.

### 6.7 i18n

Toutes les clés sous `versionGate.*` dans `src/i18n/locales/fr.json`. Pas de FR en JSX. Conformément à CLAUDE.md §6, les clés sont en anglais (`versionGate.force.title`), les valeurs en français.

## 7. Tests

Suit le partage existant : vitest pour `tests/domain/`, jest + msw pour `tests/data/` et `tests/infra/`.

### 7.1 `tests/domain/evaluate-version-status.test.ts` (vitest)

- `installed === latest` → `ok`.
- `installed > latest` (dev local en avance, build interne) → `ok`.
- `min_supported <= installed < latest` → `soft-update` avec payload (latest, releaseNotes, security, storeUrl) correctement propagé.
- `installed < min_supported` → `force-update` avec payload (minSupported, storeUrl).
- Versions malformées (`'lol'`, `''`) → `ok` (fail open).
- Prerelease (`'0.10.0-beta.1'`) traitée comme `'0.10.0'`.

### 7.2 `tests/domain/compare-semver.test.ts` (vitest)

Cas table-driven : 10 paires couvrant majeure/mineure/patch, prerelease, padding (`'0.10'` vs `'0.10.0'`).

### 7.3 `tests/data/version-config-repository.test.ts` (jest + msw)

- Fetch 200 → cache écrit, `status: 'fresh'`.
- Fetch 500 → cache existant retourné, `status: 'stale'`.
- Fetch timeout (>3s) → idem.
- Pas de cache + fetch fail → `status: 'unavailable'`.
- Cache corrompu (JSON parse error) → ignoré, refetch tenté.
- Cache plus vieux que 24h + fetch OK → cache écrasé, `status: 'fresh'`.

### 7.4 `tests/infra/version-check-api.test.ts` (jest + msw)

- Contrat HTTP : query param `platform` correctement envoyé.
- Réponse 200 : Zod parse OK, retour structuré.
- Réponse 404 : retourne `null`.
- Réponse 400 / autres erreurs : throw — caller (repository) catch et fallback cache.

### 7.5 Pas de tests E2E

Pas de Detox ou autre dans le repo. Vérification manuelle sur device réel à la première release : forcer une row `app_versions` avec `min_supported_version > installed` et vérifier l'écran bloquant + les trois actions.

## 8. Télémétrie Sentry

Trois `Sentry.addBreadcrumb` (pas d'event, pour ne pas polluer les issues) :

- `version-gate.check.success` : `{ platform, installed, latest, decision, fromCache }`
- `version-gate.check.failure` : `{ platform, errorKind: 'network' | 'timeout' | 'parse' | 'http_4xx' | 'http_5xx' }`
- `version-gate.action` : `{ kind: 'snooze' | 'open-store' | 'export-data' | 'delete-account' }`

Suffisant pour debugger un user qui rapporte « j'ai un écran bloquant » sans déployer de monitoring lourd. Pas de table d'audit Supabase (YAGNI tant qu'il n'y a pas d'analytics produit en place).

## 9. Impact RGPD

Conformément à CLAUDE.md §6, évaluation RGPD systématique :

- **Aucune nouvelle donnée personnelle stockée.** La table `app_versions` ne contient que de la config publique (versions, URLs).
- **Flux net app → backend** : envoi de `platform` (`ios` | `android`) à l'edge function. Pas de PII, pas de user-id, pas d'IP custom (l'IP TCP reste visible dans les logs Supabase comme pour toute autre requête, sans changement).
- **Échappatoire RGPD préservée** sur l'écran de force-update : un utilisateur ne peut **jamais** être verrouillé hors de ses droits art. 15 (export) et art. 17 (suppression). Les hooks réutilisés (`useExportData`, `useDeleteAccount`) sont déjà conformes (cf. spec RGPD MVP du 2026-05-06).

**Conclusion** : pas de mise à jour de la politique de confidentialité requise, pas de nouveau sous-traitant. À valider par le responsable de traitement avant implémentation.

## 10. Dépendances ajoutées

- `expo-application` (pour `nativeApplicationVersion`) — paquet officiel Expo, déjà dans l'écosystème SDK 54, zéro friction.

Aucune autre dep. `compareSemver` est implémenté localement.

## 11. Plan de livraison

Ordre conseillé pour permettre un déploiement progressif :

1. **Backend** : table `app_versions` + RLS + edge function `version-check` + seed initial (1 row iOS, 1 row Android avec la version courante de prod, `min_supported_version === latest_version`, donc gate inactif).
2. **Domain + infra + data** : `compareSemver`, `evaluateVersionStatus`, `versionCheckApi`, `versionConfigRepository` — testés isolément avant toute UI.
3. **State + UI** : hooks + provider + écrans, montés dans `app/_layout.tsx`.
4. **Vérif device** : avec `min_supported_version` artificiellement bumpé en staging, valider les 3 chemins (ok / soft / force) sur iOS et Android réels.
5. **Release** : publier la version contenant le gate. À ce moment, mettre à jour la table avec la version réelle de prod.
