# 7. Cloud, deep links, build & distribution

## Deep links (auth magic-link)

URL scheme custom dans `app.json`:

```json
{
  "expo": {
    "scheme": "coupelaine",
    "ios": { "bundleIdentifier": "fr.coupelaine.app" },
    "android": { "package": "fr.coupelaine.app" }
  }
}
```

### Flow magic-link

1. User entre email sur `/auth/login`
2. `supabase.auth.signInWithOtp({ email, options: { emailRedirectTo: 'coupelaine://auth/callback' } })`
3. Email envoyé (template Modern Craft existant, hosted Supabase) avec lien `coupelaine://auth/callback?token=...`
4. User clique le lien → OS ouvre l'app sur la route `app/auth/callback.tsx`
5. Écran callback parse le token, appelle `supabase.auth.setSession(...)`, redirige vers la racine

### À vérifier avant Jalon 11

Le template email Modern Craft (commit `f817232`) doit pointer vers `coupelaine://auth/callback` dans le bouton CTA. Vérifier dans le dashboard Supabase et corriger si besoin.

## Stockage des sessions

- `@supabase/supabase-js` configuré avec storage adapter custom utilisant `expo-secure-store`
- Pas de `localStorage` ou `AsyncStorage` pour les tokens (sécurité)

## Backup / Restore

Réutilise tel quel l'infra Supabase existante:

- Bucket Storage `backups/{user_id}/{timestamp}.json`
- Snapshot = export JSON de toutes les tables Drizzle
- Restore = drop + recréation depuis le JSON
- UI: écran Settings → "Sauvegardes cloud" → liste + boutons "Sauvegarder maintenant" / "Restaurer une sauvegarde"

## Build & distribution

### EAS Build profils

| Profile | Cible | Distribution |
|---|---|---|
| `development` | dev client (avec MapLibre + SQLite natifs) | Internal, installable sur device |
| `preview` | release builds testables | Internal sharing (lien ad hoc), pour bêta-testeurs si besoin |
| `production` | release stores | TestFlight (iOS) + Internal Testing Play Store (Android) |

### Workflow type

- Code en JS → `npx expo start` avec dev client local sur device → reload instantané
- Changement dépendance native → `eas build --profile development --platform all` → ré-installe le dev client
- Test "vraie release" → `eas build --profile preview`
- Publication → `eas build --profile production` → upload manuel TestFlight / Play Console

### EAS Update (OTA JS-only)

- `eas update --branch production` pousse une nouvelle version JS sans rebuilder l'app
- Utile pour bug fixes rapides post-publication
- Pas configuré au démarrage, on l'ajoute en distribution réelle

## Permissions

### iOS (`Info.plist` via Expo plugin)

- `NSLocationWhenInUseUsageDescription` — "Pour centrer la carte sur votre position"

### Android (`AndroidManifest.xml` via Expo)

- `ACCESS_COARSE_LOCATION`
- `ACCESS_FINE_LOCATION`

Localisation utilisateur = optionnelle (pour centrer la carte au démarrage). Pas bloquant si refusée.
