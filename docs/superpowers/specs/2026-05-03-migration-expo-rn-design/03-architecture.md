# 3. Architecture & organisation du code

On garde l'esprit des couches Flutter (presentation / state / domain / data / infra) mais on adapte aux conventions RN/TS et à Expo Router.

## Arborescence

```
coupe-laine-rn/                      (racine du worktree)
├── app/                              # Expo Router (file-based)
│   ├── (tabs)/
│   │   ├── _layout.tsx               # nav tabs
│   │   ├── clients/
│   │   │   ├── index.tsx             # liste
│   │   │   ├── [id].tsx              # détail
│   │   │   ├── [id]/edit.tsx
│   │   │   ├── [id]/history.tsx
│   │   │   └── new.tsx
│   │   ├── tours/
│   │   │   ├── index.tsx
│   │   │   ├── [id].tsx
│   │   │   ├── new/draft.tsx
│   │   │   ├── new/manual.tsx
│   │   │   ├── new/optimized.tsx
│   │   │   └── [id]/complete.tsx
│   │   ├── proximity/
│   │   │   └── index.tsx
│   │   ├── map/
│   │   │   └── index.tsx
│   │   └── settings/
│   │       ├── index.tsx
│   │       ├── appearance.tsx
│   │       ├── base.tsx
│   │       ├── species.tsx
│   │       ├── prestations.tsx
│   │       ├── animal-categories.tsx
│   │       └── cloud.tsx
│   ├── onboarding/
│   │   └── index.tsx
│   ├── auth/
│   │   ├── login.tsx
│   │   └── callback.tsx
│   └── _layout.tsx                   # root: providers, theme, fonts
├── src/
│   ├── domain/                       # use cases purs, zéro RN, zéro I/O
│   │   ├── models/                   # types Client, Tour, Prestation, etc.
│   │   └── use-cases/
│   │       ├── cost-split-calculator.ts
│   │       ├── bracket-counter.ts
│   │       ├── tour-duration-estimator.ts
│   │       ├── find-nearby-clients.ts
│   │       ├── tour-order-optimizer.ts
│   │       ├── build-tour-draft.ts
│   │       ├── build-optimized-tour-proposal.ts
│   │       ├── client-status.ts
│   │       └── find-communes-with-waiting.ts
│   ├── data/                         # repositories
│   │   ├── repositories/
│   │   │   ├── client-repository.ts
│   │   │   ├── tour-repository.ts
│   │   │   ├── distance-matrix-repository.ts
│   │   │   ├── prestation-repository.ts
│   │   │   ├── species-repository.ts
│   │   │   ├── animal-category-repository.ts
│   │   │   ├── manual-history-repository.ts
│   │   │   └── settings-repository.ts
│   │   └── seeds/
│   ├── infra/
│   │   ├── db/
│   │   │   ├── schema.ts             # Drizzle schema
│   │   │   ├── client.ts             # expo-sqlite + Drizzle setup
│   │   │   └── migrations/           # générées par drizzle-kit
│   │   ├── services/
│   │   │   ├── ban-geocoding.ts
│   │   │   ├── ors-routing.ts
│   │   │   └── supabase.ts
│   │   ├── cloud/
│   │   │   ├── auth.ts
│   │   │   └── backups.ts
│   │   └── config/
│   │       └── env.ts
│   ├── state/
│   │   ├── stores/
│   │   │   ├── tour-draft-store.ts
│   │   │   ├── filters-store.ts
│   │   │   ├── theme-store.ts
│   │   │   └── ...
│   │   └── queries/
│   │       ├── clients.ts            # useClientsQuery, useClientQuery, useToggleWaitingMutation
│   │       ├── tours.ts
│   │       └── ...
│   ├── ui/
│   │   ├── primitives/               # Button, Input, Sheet, Card (shadcn-style, éditables)
│   │   ├── components/               # composites métier (ClientCard, TourTimeline, MapPin)
│   │   └── theme/
│   │       ├── tokens.ts             # palette Modern Craft (light + dark)
│   │       └── tailwind.preset.js
│   ├── lib/                          # utilitaires transverses
│   │   ├── format-minutes.ts
│   │   ├── phone-formatter.ts
│   │   ├── phone-normalizer.ts
│   │   ├── text-search.ts
│   │   ├── text-pluralization.ts
│   │   └── animal-counts-merge.ts
│   └── i18n/
│       ├── index.ts
│       └── locales/fr.json
├── assets/
│   ├── icons/
│   └── illustrations/
├── tests/
│   ├── domain/                       # vitest
│   └── integration/                  # jest + sqlite mémoire
├── app.json                          # Expo config (config plugins MapLibre, SQLite)
├── eas.json
├── tailwind.config.js
├── drizzle.config.ts
├── tsconfig.json
└── package.json
```

## Règles de dépendance

Strict, équivalent au Flutter actuel:

- `domain/` ne dépend de **rien** (ni React, ni Expo, ni SQLite). 100% pur TS testable en vitest.
- `data/` dépend de `domain/` (retourne des modèles domain).
- `infra/` implémente des contrats utilisés par `data/`.
- `state/` dépend de `domain/` et `data/`.
- `app/` (écrans) et `ui/` dépendent de `state/`, **jamais directement** de `data/` ou `infra/`.

## Justifications

- `app/` séparé de `src/`: Expo Router impose le dossier `app/` à la racine. On garde tout le reste dans `src/` pour ne pas polluer le routing.
- `ui/primitives/` éditable: pas une dépendance npm opaque. On peut casser/réparer un Button quand on veut.
- Le découpage **mêmes frontières conceptuelles** que le code Flutter actuel → la traduction des use cases est mécanique (Dart pur → TS pur).
