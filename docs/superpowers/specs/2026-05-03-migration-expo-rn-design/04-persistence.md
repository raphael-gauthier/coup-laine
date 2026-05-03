# 4. Persistance & schéma DB

## Approche

- **Drizzle ORM** + `expo-sqlite` comme driver
- Schéma défini en TS dans `src/infra/db/schema.ts`
- Migrations générées par `drizzle-kit generate` et appliquées au démarrage de l'app via `drizzle-orm/expo-sqlite/migrator`
- Repositories dans `src/data/repositories/` font la traduction `row Drizzle ↔ modèle domain`

## Schéma initial

Parité avec Drift actuel + ajustements mineurs.

```ts
// src/infra/db/schema.ts (extrait haut niveau, pseudo-syntaxe)

clients (
  id: text PK (UUID),
  display_name: text NOT NULL,
  first_name: text,
  last_name: text,
  phones: text NOT NULL DEFAULT '[]',         // JSON array
  email: text,
  address_label: text,                         // BAN label
  address_city: text,
  address_postcode: text,
  latitude: real,
  longitude: real,
  is_waiting: integer NOT NULL DEFAULT 0,      // boolean
  notes: text,
  last_shearing_date: text,                    // ISO date YYYY-MM-DD
  animal_counts: text NOT NULL DEFAULT '[]',   // JSON array of { categoryId, count }
  created_at: text NOT NULL,
  updated_at: text NOT NULL,
)

species (
  id: text PK,
  label: text NOT NULL,
  color: text,
  ordering: integer NOT NULL,
  is_custom: integer NOT NULL DEFAULT 0,
)

animal_categories (
  id: text PK,
  species_id: text FK,
  label: text NOT NULL,
  average_minutes_per_unit: real NOT NULL,
  ordering: integer NOT NULL,
  is_custom: integer NOT NULL DEFAULT 0,
)

prestations (
  id: text PK,
  label: text NOT NULL,
  price: real,
  is_active: integer NOT NULL DEFAULT 1,
  ordering: integer NOT NULL,
)

tours (
  id: text PK,
  scheduled_date: text NOT NULL,
  departure_time: text NOT NULL,
  base_lat: real NOT NULL,
  base_lng: real NOT NULL,
  status: text NOT NULL,                       // 'draft' | 'planned' | 'completed'
  total_distance_km: real,
  total_minutes: integer,
  created_at: text NOT NULL,
  updated_at: text NOT NULL,
)

tour_stops (
  id: text PK,
  tour_id: text FK,
  client_id: text FK,
  ordering: integer NOT NULL,
  arrival_time: text,
  estimated_minutes: integer,
  prestations: text NOT NULL DEFAULT '[]',     // JSON array of { prestationId, animalCounts }
  notes: text,
  completed_at: text,
)

manual_history_entries (
  id: text PK,
  client_id: text FK,
  date: text NOT NULL,
  notes: text,
  prestations: text NOT NULL DEFAULT '[]',
)

distance_matrix (
  from_id: text NOT NULL,                      // client id ou 'BASE'
  to_id: text NOT NULL,
  distance_km: real NOT NULL,
  duration_minutes: integer NOT NULL,
  fetched_at: text NOT NULL,
  PK (from_id, to_id)
)

settings (
  key: text PK,
  value: text NOT NULL,
)
// keys: 'base_address_label', 'base_lat', 'base_lng', 'price_per_bracket',
//       'bracket_km', 'theme_mode' ('system'|'light'|'dark'),
//       'distance_matrix_ttl_days', ...
```

## Conventions vs version Flutter

- **Strings ISO** pour toutes les dates (YYYY-MM-DD ou ISO 8601). Pas de type DateTime SQLite — conversion dans les repos.
- **JSON arrays sérialisés** dans des colonnes `text` pour `phones`, `animal_counts`, `prestations` (idem Drift actuel via type converters).
- **Booleans = integer 0/1** (convention SQLite).
- **`distance_matrix`** garde sa structure (from, to, km, min) pour cacher les appels ORS et économiser le quota.

## Index

- `clients.is_waiting` (queries fréquentes "clients en attente")
- `clients.last_shearing_date` (tri historique)
- `tour_stops.tour_id` (FK déjà couverte mais explicite)
- `tour_stops.client_id`
- `manual_history_entries.client_id`

## Migrations & seeds

- **Migration initiale** = tout le schéma ci-dessus en un coup (clean slate)
- **Seed au premier lancement** (détecté via table `settings` vide):
  - Espèces standard: mouton, chèvre
  - `animal_categories` par défaut par espèce (brebis adultes, agneaux, etc. — à confirmer avec le métier)
  - Prestations par défaut: tonte, parage
- **Pas** de migration depuis l'app Flutter (clean slate, personne ne l'utilise)

## Redesigns différés

- Passer les `JSON arrays` de `tour_stops.prestations` en table relationnelle séparée (`tour_stop_prestations`). Plus propre relationnellement, mais complexifie les écritures. **Décision: on garde le JSON pour v1**, cohérent avec Drift actuel.
