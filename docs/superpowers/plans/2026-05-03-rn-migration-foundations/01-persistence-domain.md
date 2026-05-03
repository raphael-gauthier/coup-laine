# Phase 1 — Persistence + Domain layer

**Goal:** Full Drizzle schema (all tables from spec §4), initial migration applied at app startup, seeds for first-launch (species + prestations), repositories for every table, all pure TS use cases ported from Dart with their test suites translated, all lib utilities (haversine, format-minutes, phone normalizer/formatter, text-search, text-pluralization, animal-counts mergers).

**Verification at end of phase:** `pnpm test` green with full coverage on domain use cases and repository CRUD; the app boots, runs migrations, and seeds the DB on first launch (visible by adding a debug `console.log` in `app/index.tsx` reading from a repository, then removing it before commit).

**Reference for porting:** the Dart source remains accessible via `git show flutter-final-v0.7.0:<path>`. Use it for any use case where the algorithm isn't fully captured by the test cases below.

```powershell
# Example: read the cost split logic from the Flutter snapshot
git show flutter-final-v0.7.0:lib/domain/use_cases/cost_split_calculator.dart
```

---

## Task 1.1: Define the full Drizzle schema

**Files:**
- Modify: `src/infra/db/schema.ts`

- [ ] **Step 1: Replace `src/infra/db/schema.ts` with the full schema**

```ts
// src/infra/db/schema.ts
import { sqliteTable, text, integer, real, primaryKey, index } from 'drizzle-orm/sqlite-core';

export const clients = sqliteTable(
  'clients',
  {
    id: text('id').primaryKey(),
    displayName: text('display_name').notNull(),
    firstName: text('first_name'),
    lastName: text('last_name'),
    phones: text('phones').notNull().default('[]'),
    email: text('email'),
    addressLabel: text('address_label'),
    addressCity: text('address_city'),
    addressPostcode: text('address_postcode'),
    latitude: real('latitude'),
    longitude: real('longitude'),
    isWaiting: integer('is_waiting').notNull().default(0),
    notes: text('notes'),
    lastShearingDate: text('last_shearing_date'),
    animalCounts: text('animal_counts').notNull().default('[]'),
    createdAt: text('created_at').notNull(),
    updatedAt: text('updated_at').notNull(),
  },
  (t) => ({
    waitingIdx: index('clients_is_waiting_idx').on(t.isWaiting),
    lastShearingIdx: index('clients_last_shearing_idx').on(t.lastShearingDate),
  })
);

export const species = sqliteTable('species', {
  id: text('id').primaryKey(),
  label: text('label').notNull(),
  color: text('color'),
  ordering: integer('ordering').notNull(),
  isCustom: integer('is_custom').notNull().default(0),
});

export const animalCategories = sqliteTable(
  'animal_categories',
  {
    id: text('id').primaryKey(),
    speciesId: text('species_id').notNull().references(() => species.id),
    label: text('label').notNull(),
    averageMinutesPerUnit: real('average_minutes_per_unit').notNull(),
    ordering: integer('ordering').notNull(),
    isCustom: integer('is_custom').notNull().default(0),
  },
  (t) => ({
    speciesIdx: index('animal_categories_species_idx').on(t.speciesId),
  })
);

export const prestations = sqliteTable('prestations', {
  id: text('id').primaryKey(),
  label: text('label').notNull(),
  price: real('price'),
  isActive: integer('is_active').notNull().default(1),
  ordering: integer('ordering').notNull(),
});

export const tours = sqliteTable('tours', {
  id: text('id').primaryKey(),
  scheduledDate: text('scheduled_date').notNull(),
  departureTime: text('departure_time').notNull(),
  baseLat: real('base_lat').notNull(),
  baseLng: real('base_lng').notNull(),
  status: text('status').notNull(), // 'draft' | 'planned' | 'completed'
  totalDistanceKm: real('total_distance_km'),
  totalMinutes: integer('total_minutes'),
  createdAt: text('created_at').notNull(),
  updatedAt: text('updated_at').notNull(),
});

export const tourStops = sqliteTable(
  'tour_stops',
  {
    id: text('id').primaryKey(),
    tourId: text('tour_id').notNull().references(() => tours.id, { onDelete: 'cascade' }),
    clientId: text('client_id').notNull().references(() => clients.id),
    ordering: integer('ordering').notNull(),
    arrivalTime: text('arrival_time'),
    estimatedMinutes: integer('estimated_minutes'),
    prestations: text('prestations').notNull().default('[]'),
    notes: text('notes'),
    completedAt: text('completed_at'),
  },
  (t) => ({
    tourIdx: index('tour_stops_tour_idx').on(t.tourId),
    clientIdx: index('tour_stops_client_idx').on(t.clientId),
  })
);

export const manualHistoryEntries = sqliteTable(
  'manual_history_entries',
  {
    id: text('id').primaryKey(),
    clientId: text('client_id').notNull().references(() => clients.id, { onDelete: 'cascade' }),
    date: text('date').notNull(),
    notes: text('notes'),
    prestations: text('prestations').notNull().default('[]'),
  },
  (t) => ({
    clientIdx: index('manual_history_client_idx').on(t.clientId),
  })
);

export const distanceMatrix = sqliteTable(
  'distance_matrix',
  {
    fromId: text('from_id').notNull(),
    toId: text('to_id').notNull(),
    distanceKm: real('distance_km').notNull(),
    durationMinutes: integer('duration_minutes').notNull(),
    fetchedAt: text('fetched_at').notNull(),
  },
  (t) => ({
    pk: primaryKey({ columns: [t.fromId, t.toId] }),
  })
);

export const settings = sqliteTable('settings', {
  key: text('key').primaryKey(),
  value: text('value').notNull(),
});
```

- [ ] **Step 2: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 3: Commit**

```powershell
git add -A
git commit -m "feat(db): drizzle schema for all tables"
```

---

## Task 1.2: Generate the initial migration

**Files:**
- Create: `src/infra/db/migrations/*.sql` (auto-generated)
- Create: `src/infra/db/migrations/migrations.js` (auto-generated bundle)

- [ ] **Step 1: Run drizzle-kit generate**

```powershell
pnpm db:generate
```

Expected: Drizzle generates an SQL file under `src/infra/db/migrations/0000_<name>.sql` and a metadata JSON file.

- [ ] **Step 2: Generate the migrations bundle for runtime**

Drizzle's `expo-sqlite` adapter requires a generated `migrations.js` file that imports the SQL strings. Configure it by editing `drizzle.config.ts`:

Add a script in `package.json` `scripts`:

```json
"db:bundle": "node scripts/bundle-migrations.mjs"
```

Create `scripts/bundle-migrations.mjs`:

```js
// scripts/bundle-migrations.mjs
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const migrationsDir = join(__dirname, '..', 'src', 'infra', 'db', 'migrations');

const files = readdirSync(migrationsDir)
  .filter((f) => f.endsWith('.sql'))
  .sort();

const journal = JSON.parse(
  readFileSync(join(migrationsDir, 'meta', '_journal.json'), 'utf8')
);

const entries = files.map((file) => {
  const sql = readFileSync(join(migrationsDir, file), 'utf8');
  return `  '${file}': ${JSON.stringify(sql)}`;
});

const output = `// AUTO-GENERATED. Do not edit. Run \`pnpm db:bundle\` after \`pnpm db:generate\`.
export default {
  journal: ${JSON.stringify(journal, null, 2)},
  migrations: {
${entries.join(',\n')}
  },
};
`;

writeFileSync(join(migrationsDir, 'migrations.js'), output);
console.log(`Bundled ${files.length} migrations.`);
```

- [ ] **Step 3: Run the bundle**

```powershell
pnpm db:bundle
```

Expected: `src/infra/db/migrations/migrations.js` exists.

- [ ] **Step 4: Add a type stub for the migrations bundle**

Create `src/infra/db/migrations/migrations.d.ts`:

```ts
declare const _default: {
  journal: { entries: { idx: number; tag: string; when: number; breakpoints: boolean }[] };
  migrations: Record<string, string>;
};
export default _default;
```

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "feat(db): generate initial migration and bundle for runtime"
```

---

## Task 1.3: Wire migrations + seeds at app startup

**Files:**
- Modify: `src/infra/db/client.ts`
- Create: `src/data/seeds/species-seeds.ts`
- Create: `src/data/seeds/prestation-seeds.ts`
- Create: `src/infra/db/bootstrap.ts`
- Modify: `app/_layout.tsx`

- [ ] **Step 1: Create the bootstrap module**

```ts
// src/infra/db/bootstrap.ts
import { migrate } from 'drizzle-orm/expo-sqlite/migrator';
import { db } from './client';
import migrations from './migrations/migrations';
import { seedSpeciesIfEmpty } from '@/data/seeds/species-seeds';
import { seedPrestationsIfEmpty } from '@/data/seeds/prestation-seeds';

let initialized = false;

export async function bootstrapDatabase() {
  if (initialized) return;
  await migrate(db, migrations);
  await seedSpeciesIfEmpty(db);
  await seedPrestationsIfEmpty(db);
  initialized = true;
}
```

- [ ] **Step 2: Create species seeds**

```ts
// src/data/seeds/species-seeds.ts
import { eq, sql } from 'drizzle-orm';
import { species, animalCategories } from '@/infra/db/schema';
import type { Database } from '@/infra/db/client';

const STANDARD_SPECIES = [
  {
    id: 'sheep',
    label: 'Mouton',
    color: '#A1602F',
    ordering: 0,
    isCustom: 0,
    categories: [
      { id: 'sheep-adult', label: 'Brebis adulte', averageMinutesPerUnit: 20, ordering: 0 },
      { id: 'sheep-lamb', label: 'Agneau', averageMinutesPerUnit: 15, ordering: 1 },
    ],
  },
  {
    id: 'goat',
    label: 'Chèvre',
    color: '#748E60',
    ordering: 1,
    isCustom: 0,
    categories: [
      { id: 'goat-adult', label: 'Chèvre adulte', averageMinutesPerUnit: 18, ordering: 0 },
    ],
  },
];

export async function seedSpeciesIfEmpty(db: Database) {
  const [{ count }] = await db.select({ count: sql<number>`count(*)` }).from(species);
  if (count > 0) return;

  for (const s of STANDARD_SPECIES) {
    await db.insert(species).values({
      id: s.id,
      label: s.label,
      color: s.color,
      ordering: s.ordering,
      isCustom: s.isCustom,
    });
    for (const c of s.categories) {
      await db.insert(animalCategories).values({
        id: c.id,
        speciesId: s.id,
        label: c.label,
        averageMinutesPerUnit: c.averageMinutesPerUnit,
        ordering: c.ordering,
        isCustom: 0,
      });
    }
  }
}
```

- [ ] **Step 3: Create prestation seeds**

```ts
// src/data/seeds/prestation-seeds.ts
import { sql } from 'drizzle-orm';
import { prestations } from '@/infra/db/schema';
import type { Database } from '@/infra/db/client';

const STANDARD_PRESTATIONS = [
  { id: 'shearing', label: 'Tonte', price: null, isActive: 1, ordering: 0 },
  { id: 'hoof-trimming', label: 'Parage', price: null, isActive: 1, ordering: 1 },
];

export async function seedPrestationsIfEmpty(db: Database) {
  const [{ count }] = await db.select({ count: sql<number>`count(*)` }).from(prestations);
  if (count > 0) return;

  for (const p of STANDARD_PRESTATIONS) {
    await db.insert(prestations).values(p);
  }
}
```

- [ ] **Step 4: Call bootstrap on app start**

Update `app/_layout.tsx` to add a one-shot bootstrap effect before the QueryClientProvider children render:

```tsx
import '../global.css';
import '@/i18n';
import { Stack } from 'expo-router';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from '@/ui/theme/theme-provider';
import { useEffect, useState } from 'react';
import { bootstrapDatabase } from '@/infra/db/bootstrap';
import { ActivityIndicator, View } from 'react-native';

const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000, retry: 1 } },
});

export default function RootLayout() {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    bootstrapDatabase()
      .then(() => setReady(true))
      .catch((err) => {
        console.error('DB bootstrap failed', err);
      });
  }, []);

  if (!ready) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator />
      </View>
    );
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider>
          <Stack screenOptions={{ headerShown: false }} />
        </ThemeProvider>
      </QueryClientProvider>
    </GestureHandlerRootView>
  );
}
```

- [ ] **Step 5: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 6: Verify on device**

Run `pnpm start --dev-client` and reload the app. Expected: brief loading indicator, then the hello screen renders. No errors in the console.

- [ ] **Step 7: Commit**

```powershell
git add -A
git commit -m "feat(db): bootstrap migrations + seeds (species, prestations) on app start"
```

---

## Task 1.4: Domain models (types + Zod schemas)

**Files:**
- Create all of: `src/domain/models/coordinates.ts`, `animal-count.ts`, `client.ts`, `species.ts`, `animal-category.ts`, `prestation.ts`, `tour.ts`, `tour-stop.ts`, `tour-stop-prestation.ts`, `manual-history-entry.ts`, `distance-matrix-entry.ts`, `intervention.ts`

> Domain models are pure types. We use Zod for runtime validation at boundaries (parsing JSON from DB, parsing API responses) and infer TS types from the schemas.

- [ ] **Step 1: Install zod (already installed in J0 — sanity check)**

```powershell
pnpm list zod
```

- [ ] **Step 2: Create `coordinates.ts` with TDD**

Test:

```ts
// tests/domain/coordinates.test.ts
import { describe, it, expect } from 'vitest';
import { Coordinates } from '@/domain/models/coordinates';

describe('Coordinates', () => {
  it('parses valid coordinates', () => {
    const c = Coordinates.parse({ lat: 48.0, lon: -3.0 });
    expect(c.lat).toBe(48.0);
    expect(c.lon).toBe(-3.0);
  });

  it('rejects out-of-range latitude', () => {
    expect(() => Coordinates.parse({ lat: 91, lon: 0 })).toThrow();
    expect(() => Coordinates.parse({ lat: -91, lon: 0 })).toThrow();
  });

  it('rejects out-of-range longitude', () => {
    expect(() => Coordinates.parse({ lat: 0, lon: 181 })).toThrow();
    expect(() => Coordinates.parse({ lat: 0, lon: -181 })).toThrow();
  });
});
```

Run, expect FAIL:
```powershell
pnpm vitest run tests/domain/coordinates.test.ts
```

Implementation:

```ts
// src/domain/models/coordinates.ts
import { z } from 'zod';

export const Coordinates = z.object({
  lat: z.number().min(-90).max(90),
  lon: z.number().min(-180).max(180),
});

export type Coordinates = z.infer<typeof Coordinates>;
```

Run, expect PASS.

- [ ] **Step 3: Create `animal-count.ts`**

```ts
// src/domain/models/animal-count.ts
import { z } from 'zod';

export const AnimalCount = z.object({
  categoryId: z.string(),
  count: z.number().int().nonnegative(),
});

export type AnimalCount = z.infer<typeof AnimalCount>;

export const AnimalCountList = z.array(AnimalCount);
export type AnimalCountList = z.infer<typeof AnimalCountList>;
```

- [ ] **Step 4: Create the rest of the model files**

```ts
// src/domain/models/client.ts
import { z } from 'zod';
import { AnimalCountList } from './animal-count';

export const Client = z.object({
  id: z.string(),
  displayName: z.string(),
  firstName: z.string().nullable(),
  lastName: z.string().nullable(),
  phones: z.array(z.string()),
  email: z.string().email().nullable(),
  addressLabel: z.string().nullable(),
  addressCity: z.string().nullable(),
  addressPostcode: z.string().nullable(),
  latitude: z.number().nullable(),
  longitude: z.number().nullable(),
  isWaiting: z.boolean(),
  notes: z.string().nullable(),
  lastShearingDate: z.string().nullable(),
  animalCounts: AnimalCountList,
  createdAt: z.string(),
  updatedAt: z.string(),
});

export type Client = z.infer<typeof Client>;
```

```ts
// src/domain/models/species.ts
import { z } from 'zod';

export const Species = z.object({
  id: z.string(),
  label: z.string(),
  color: z.string().nullable(),
  ordering: z.number().int(),
  isCustom: z.boolean(),
});

export type Species = z.infer<typeof Species>;
```

```ts
// src/domain/models/animal-category.ts
import { z } from 'zod';

export const AnimalCategory = z.object({
  id: z.string(),
  speciesId: z.string(),
  label: z.string(),
  averageMinutesPerUnit: z.number().nonnegative(),
  ordering: z.number().int(),
  isCustom: z.boolean(),
});

export type AnimalCategory = z.infer<typeof AnimalCategory>;
```

```ts
// src/domain/models/prestation.ts
import { z } from 'zod';

export const Prestation = z.object({
  id: z.string(),
  label: z.string(),
  price: z.number().nullable(),
  isActive: z.boolean(),
  ordering: z.number().int(),
});

export type Prestation = z.infer<typeof Prestation>;
```

```ts
// src/domain/models/tour-stop-prestation.ts
import { z } from 'zod';
import { AnimalCountList } from './animal-count';

export const TourStopPrestation = z.object({
  prestationId: z.string(),
  animalCounts: AnimalCountList,
});

export type TourStopPrestation = z.infer<typeof TourStopPrestation>;
```

```ts
// src/domain/models/tour-stop.ts
import { z } from 'zod';
import { TourStopPrestation } from './tour-stop-prestation';

export const TourStop = z.object({
  id: z.string(),
  tourId: z.string(),
  clientId: z.string(),
  ordering: z.number().int(),
  arrivalTime: z.string().nullable(),
  estimatedMinutes: z.number().int().nullable(),
  prestations: z.array(TourStopPrestation),
  notes: z.string().nullable(),
  completedAt: z.string().nullable(),
});

export type TourStop = z.infer<typeof TourStop>;
```

```ts
// src/domain/models/tour.ts
import { z } from 'zod';

export const TourStatus = z.enum(['draft', 'planned', 'completed']);
export type TourStatus = z.infer<typeof TourStatus>;

export const Tour = z.object({
  id: z.string(),
  scheduledDate: z.string(),
  departureTime: z.string(),
  baseLat: z.number(),
  baseLng: z.number(),
  status: TourStatus,
  totalDistanceKm: z.number().nullable(),
  totalMinutes: z.number().int().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export type Tour = z.infer<typeof Tour>;
```

```ts
// src/domain/models/manual-history-entry.ts
import { z } from 'zod';
import { TourStopPrestation } from './tour-stop-prestation';

export const ManualHistoryEntry = z.object({
  id: z.string(),
  clientId: z.string(),
  date: z.string(),
  notes: z.string().nullable(),
  prestations: z.array(TourStopPrestation),
});

export type ManualHistoryEntry = z.infer<typeof ManualHistoryEntry>;
```

```ts
// src/domain/models/distance-matrix-entry.ts
import { z } from 'zod';

export const DistanceMatrixEntry = z.object({
  fromId: z.string(),
  toId: z.string(),
  distanceKm: z.number().nonnegative(),
  durationMinutes: z.number().int().nonnegative(),
  fetchedAt: z.string(),
});

export type DistanceMatrixEntry = z.infer<typeof DistanceMatrixEntry>;
```

```ts
// src/domain/models/intervention.ts
// Read-model: a unified view over completed tour stops + manual history entries,
// used by the client history screen (J9). Defined here so use cases can return it.
import { z } from 'zod';
import { TourStopPrestation } from './tour-stop-prestation';

export const InterventionSource = z.enum(['tour', 'manual']);

export const Intervention = z.object({
  source: InterventionSource,
  date: z.string(),
  prestations: z.array(TourStopPrestation),
  notes: z.string().nullable(),
  // Source-specific reference IDs; one or the other will be set.
  tourId: z.string().nullable(),
  tourStopId: z.string().nullable(),
  manualEntryId: z.string().nullable(),
});

export type Intervention = z.infer<typeof Intervention>;
```

- [ ] **Step 5: Run vitest to ensure coordinates test still passes (others have no tests yet)**

```powershell
pnpm vitest run
```

- [ ] **Step 6: Commit**

```powershell
git add -A
git commit -m "feat(domain): zod-based models for all domain entities"
```

---

## Task 1.5: lib utility — haversine distance

**Files:**
- Create: `src/lib/haversine-distance.ts`
- Create: `tests/domain/lib/haversine-distance.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// tests/domain/lib/haversine-distance.test.ts
import { describe, it, expect } from 'vitest';
import { haversineDistanceKm } from '@/lib/haversine-distance';

describe('haversineDistanceKm', () => {
  it('returns 0 for identical points', () => {
    expect(haversineDistanceKm({ lat: 48, lon: -3 }, { lat: 48, lon: -3 })).toBe(0);
  });

  it('returns ~111 km for 1° of latitude', () => {
    const d = haversineDistanceKm({ lat: 48, lon: -3 }, { lat: 49, lon: -3 });
    expect(d).toBeGreaterThan(110);
    expect(d).toBeLessThan(112);
  });

  it('returns symmetric values', () => {
    const a = { lat: 48.1, lon: -3.5 };
    const b = { lat: 48.6, lon: -2.9 };
    expect(haversineDistanceKm(a, b)).toBeCloseTo(haversineDistanceKm(b, a), 6);
  });
});
```

- [ ] **Step 2: Run, expect FAIL** — `pnpm vitest run tests/domain/lib/haversine-distance.test.ts`

- [ ] **Step 3: Implement**

```ts
// src/lib/haversine-distance.ts
import type { Coordinates } from '@/domain/models/coordinates';

const EARTH_RADIUS_KM = 6371;

const toRad = (deg: number) => (deg * Math.PI) / 180;

export function haversineDistanceKm(a: Coordinates, b: Coordinates): number {
  const dLat = toRad(b.lat - a.lat);
  const dLon = toRad(b.lon - a.lon);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);

  const sinDLat = Math.sin(dLat / 2);
  const sinDLon = Math.sin(dLon / 2);
  const h = sinDLat * sinDLat + Math.cos(lat1) * Math.cos(lat2) * sinDLon * sinDLon;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(h));
}
```

- [ ] **Step 4: Run, expect PASS**

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "feat(lib): haversine distance with tests"
```

---

## Task 1.6: lib utility — format-minutes

**Files:**
- Create: `src/lib/format-minutes.ts`
- Create: `tests/domain/lib/format-minutes.test.ts`

> Reference Dart source: `git show flutter-final-v0.7.0:lib/core/format_minutes.dart`. Mirror the same output format.

- [ ] **Step 1: Write the failing test (cases match the Dart contract: "Xh YY" or "YY min")**

```ts
// tests/domain/lib/format-minutes.test.ts
import { describe, it, expect } from 'vitest';
import { formatMinutes } from '@/lib/format-minutes';

describe('formatMinutes', () => {
  it('formats 0 as "0 min"', () => expect(formatMinutes(0)).toBe('0 min'));
  it('formats < 60 as minutes', () => expect(formatMinutes(45)).toBe('45 min'));
  it('formats exact hour as "Xh"', () => expect(formatMinutes(60)).toBe('1h'));
  it('formats hour + min', () => expect(formatMinutes(75)).toBe('1h 15'));
  it('formats multi-hour', () => expect(formatMinutes(125)).toBe('2h 05'));
  it('zero-pads minutes < 10 in compound', () => expect(formatMinutes(122)).toBe('2h 02'));
});
```

- [ ] **Step 2: Run, expect FAIL**

- [ ] **Step 3: Implement**

```ts
// src/lib/format-minutes.ts
export function formatMinutes(totalMinutes: number): string {
  if (totalMinutes < 60) return `${totalMinutes} min`;
  const hours = Math.floor(totalMinutes / 60);
  const mins = totalMinutes % 60;
  if (mins === 0) return `${hours}h`;
  return `${hours}h ${String(mins).padStart(2, '0')}`;
}
```

- [ ] **Step 4: Run, expect PASS**

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "feat(lib): format-minutes utility with tests"
```

---

## Task 1.7: lib utility — phone-normalizer + phone-formatter

**Files:**
- Create: `src/lib/phone-normalizer.ts`
- Create: `src/lib/phone-formatter.ts`
- Create: `tests/domain/lib/phone-normalizer.test.ts`
- Create: `tests/domain/lib/phone-formatter.test.ts`

> Reference Dart sources:
> ```
> git show flutter-final-v0.7.0:lib/core/phone_normalizer.dart
> git show flutter-final-v0.7.0:lib/core/phone_formatter.dart
> ```
> Match the same behaviour: normaliser strips non-digits and keeps a canonical FR form (`+33` or `0` prefix); formatter renders `06 12 34 56 78` style.

- [ ] **Step 1: Write tests for the normalizer**

```ts
// tests/domain/lib/phone-normalizer.test.ts
import { describe, it, expect } from 'vitest';
import { normalizePhone } from '@/lib/phone-normalizer';

describe('normalizePhone', () => {
  it('strips spaces, dots, and dashes', () => {
    expect(normalizePhone('06 12.34-56 78')).toBe('0612345678');
  });

  it('preserves a leading +', () => {
    expect(normalizePhone('+33 6 12 34 56 78')).toBe('+33612345678');
  });

  it('returns empty for non-digit input', () => {
    expect(normalizePhone('abc')).toBe('');
  });
});
```

- [ ] **Step 2: Implement normalizer**

```ts
// src/lib/phone-normalizer.ts
export function normalizePhone(input: string): string {
  if (!input) return '';
  const trimmed = input.trim();
  const hasPlus = trimmed.startsWith('+');
  const digits = trimmed.replace(/\D/g, '');
  if (digits.length === 0) return '';
  return hasPlus ? `+${digits}` : digits;
}
```

- [ ] **Step 3: Run tests, expect PASS**

- [ ] **Step 4: Write tests for the formatter**

```ts
// tests/domain/lib/phone-formatter.test.ts
import { describe, it, expect } from 'vitest';
import { formatPhone } from '@/lib/phone-formatter';

describe('formatPhone', () => {
  it('formats a 10-digit FR number in pairs', () => {
    expect(formatPhone('0612345678')).toBe('06 12 34 56 78');
  });

  it('formats +33 number as +33 6 12 34 56 78', () => {
    expect(formatPhone('+33612345678')).toBe('+33 6 12 34 56 78');
  });

  it('returns input unchanged for unrecognized formats', () => {
    expect(formatPhone('123')).toBe('123');
  });

  it('handles empty input', () => {
    expect(formatPhone('')).toBe('');
  });
});
```

- [ ] **Step 5: Implement formatter**

```ts
// src/lib/phone-formatter.ts
import { normalizePhone } from './phone-normalizer';

export function formatPhone(input: string): string {
  if (!input) return '';
  const n = normalizePhone(input);
  if (n.length === 10 && n.startsWith('0')) {
    return n.match(/.{2}/g)!.join(' ');
  }
  if (n.startsWith('+33') && n.length === 12) {
    const rest = n.slice(3);
    return `+33 ${rest[0]} ${rest.slice(1).match(/.{2}/g)!.join(' ')}`;
  }
  return input;
}
```

- [ ] **Step 6: Run tests, expect PASS**

- [ ] **Step 7: Commit**

```powershell
git add -A
git commit -m "feat(lib): phone normalizer + formatter with tests"
```

---

## Task 1.8: lib utility — text-search and text-pluralization

**Files:**
- Create: `src/lib/text-search.ts`, `src/lib/text-pluralization.ts`
- Create: `tests/domain/lib/text-search.test.ts`, `tests/domain/lib/text-pluralization.test.ts`

> Reference Dart sources:
> ```
> git show flutter-final-v0.7.0:lib/core/text_search.dart
> git show flutter-final-v0.7.0:lib/core/text_pluralization.dart
> ```

- [ ] **Step 1: Write tests for text-search**

```ts
// tests/domain/lib/text-search.test.ts
import { describe, it, expect } from 'vitest';
import { matchesQuery, normalizeForSearch } from '@/lib/text-search';

describe('normalizeForSearch', () => {
  it('lowercases', () => expect(normalizeForSearch('FOO')).toBe('foo'));
  it('strips accents', () => expect(normalizeForSearch('élève')).toBe('eleve'));
  it('collapses whitespace', () => expect(normalizeForSearch('  a   b  ')).toBe('a b'));
});

describe('matchesQuery', () => {
  it('matches case-insensitively', () => expect(matchesQuery('Hello World', 'hello')).toBe(true));
  it('matches accent-insensitively', () => expect(matchesQuery('Brévent', 'brevent')).toBe(true));
  it('matches across word boundaries', () => expect(matchesQuery('Jean-Pierre', 'pierre')).toBe(true));
  it('returns false on no match', () => expect(matchesQuery('Hello', 'xyz')).toBe(false));
  it('returns true on empty query', () => expect(matchesQuery('Hello', '')).toBe(true));
});
```

- [ ] **Step 2: Implement text-search**

```ts
// src/lib/text-search.ts
export function normalizeForSearch(input: string): string {
  return input
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

export function matchesQuery(haystack: string, query: string): boolean {
  if (!query) return true;
  return normalizeForSearch(haystack).includes(normalizeForSearch(query));
}
```

- [ ] **Step 3: Run, expect PASS**

- [ ] **Step 4: Write tests for text-pluralization**

```ts
// tests/domain/lib/text-pluralization.test.ts
import { describe, it, expect } from 'vitest';
import { pluralize } from '@/lib/text-pluralization';

describe('pluralize (FR)', () => {
  it('singular for 0 in FR', () => expect(pluralize(0, 'client', 'clients')).toBe('client'));
  it('singular for 1', () => expect(pluralize(1, 'client', 'clients')).toBe('client'));
  it('plural for >1', () => expect(pluralize(2, 'client', 'clients')).toBe('clients'));
});
```

- [ ] **Step 5: Implement**

```ts
// src/lib/text-pluralization.ts
export function pluralize(count: number, singular: string, plural: string): string {
  return Math.abs(count) <= 1 ? singular : plural;
}
```

- [ ] **Step 6: Run, expect PASS**

- [ ] **Step 7: Commit**

```powershell
git add -A
git commit -m "feat(lib): text search + pluralization with tests"
```

---

## Task 1.9: lib utility — animal-counts merge & normalize

**Files:**
- Create: `src/lib/animal-counts-merge.ts`, `src/lib/animal-counts-normalizer.ts`
- Create: `tests/domain/lib/animal-counts-merge.test.ts`, `tests/domain/lib/animal-counts-normalizer.test.ts`

> Reference Dart:
> ```
> git show flutter-final-v0.7.0:lib/core/animal_counts_merge.dart
> git show flutter-final-v0.7.0:lib/core/animal_counts_normalizer.dart
> ```

- [ ] **Step 1: Write merge tests**

```ts
// tests/domain/lib/animal-counts-merge.test.ts
import { describe, it, expect } from 'vitest';
import { mergeAnimalCounts } from '@/lib/animal-counts-merge';

describe('mergeAnimalCounts', () => {
  it('returns empty for empty input', () => {
    expect(mergeAnimalCounts([])).toEqual([]);
  });

  it('sums counts by categoryId', () => {
    const result = mergeAnimalCounts([
      [{ categoryId: 'a', count: 3 }],
      [{ categoryId: 'a', count: 2 }, { categoryId: 'b', count: 5 }],
    ]);
    expect(result).toEqual([
      { categoryId: 'a', count: 5 },
      { categoryId: 'b', count: 5 },
    ]);
  });

  it('preserves first-seen ordering', () => {
    const result = mergeAnimalCounts([
      [{ categoryId: 'b', count: 1 }],
      [{ categoryId: 'a', count: 1 }],
    ]);
    expect(result.map((c) => c.categoryId)).toEqual(['b', 'a']);
  });
});
```

- [ ] **Step 2: Implement merge**

```ts
// src/lib/animal-counts-merge.ts
import type { AnimalCount } from '@/domain/models/animal-count';

export function mergeAnimalCounts(lists: AnimalCount[][]): AnimalCount[] {
  const order: string[] = [];
  const sums = new Map<string, number>();
  for (const list of lists) {
    for (const { categoryId, count } of list) {
      if (!sums.has(categoryId)) order.push(categoryId);
      sums.set(categoryId, (sums.get(categoryId) ?? 0) + count);
    }
  }
  return order.map((id) => ({ categoryId: id, count: sums.get(id)! }));
}
```

- [ ] **Step 3: Write normalizer tests**

```ts
// tests/domain/lib/animal-counts-normalizer.test.ts
import { describe, it, expect } from 'vitest';
import { normalizeAnimalCounts } from '@/lib/animal-counts-normalizer';

describe('normalizeAnimalCounts', () => {
  it('drops zero-count entries', () => {
    expect(normalizeAnimalCounts([
      { categoryId: 'a', count: 0 },
      { categoryId: 'b', count: 3 },
    ])).toEqual([{ categoryId: 'b', count: 3 }]);
  });

  it('coerces negative counts to 0 and drops them', () => {
    expect(normalizeAnimalCounts([{ categoryId: 'a', count: -2 }])).toEqual([]);
  });

  it('returns empty for empty input', () => {
    expect(normalizeAnimalCounts([])).toEqual([]);
  });
});
```

- [ ] **Step 4: Implement normalizer**

```ts
// src/lib/animal-counts-normalizer.ts
import type { AnimalCount } from '@/domain/models/animal-count';

export function normalizeAnimalCounts(list: AnimalCount[]): AnimalCount[] {
  return list.filter((c) => c.count > 0);
}
```

- [ ] **Step 5: Run, expect PASS**

- [ ] **Step 6: Commit**

```powershell
git add -A
git commit -m "feat(lib): animal-counts merge + normalizer with tests"
```

---

## Task 1.10: Use case — bracket-counter

**Files:**
- Create: `src/domain/use-cases/bracket-counter.ts`
- Create: `tests/domain/use-cases/bracket-counter.test.ts`

> Reference: `git show flutter-final-v0.7.0:lib/domain/use_cases/bracket_counter.dart`. Rule: total km divided by bracket size (10 km), rounded **up** (ceiling). 0 km = 0 brackets. 1 km = 1 bracket. 10 km = 1 bracket. 10.01 km = 2 brackets.

- [ ] **Step 1: Write the test**

```ts
// tests/domain/use-cases/bracket-counter.test.ts
import { describe, it, expect } from 'vitest';
import { countBrackets } from '@/domain/use-cases/bracket-counter';

describe('countBrackets (10km bracket size)', () => {
  it('0 km = 0 brackets', () => expect(countBrackets(0, 10)).toBe(0));
  it('0.5 km = 1 bracket', () => expect(countBrackets(0.5, 10)).toBe(1));
  it('1 km = 1 bracket', () => expect(countBrackets(1, 10)).toBe(1));
  it('10 km exactly = 1 bracket', () => expect(countBrackets(10, 10)).toBe(1));
  it('10.001 km = 2 brackets', () => expect(countBrackets(10.001, 10)).toBe(2));
  it('25 km = 3 brackets', () => expect(countBrackets(25, 10)).toBe(3));

  it('respects custom bracket size', () => {
    expect(countBrackets(15, 5)).toBe(3);
    expect(countBrackets(16, 5)).toBe(4);
  });

  it('throws on non-positive bracket size', () => {
    expect(() => countBrackets(10, 0)).toThrow();
    expect(() => countBrackets(10, -1)).toThrow();
  });
});
```

- [ ] **Step 2: Run, expect FAIL**

- [ ] **Step 3: Implement**

```ts
// src/domain/use-cases/bracket-counter.ts
export function countBrackets(distanceKm: number, bracketSizeKm: number): number {
  if (bracketSizeKm <= 0) {
    throw new Error('bracketSizeKm must be positive');
  }
  if (distanceKm <= 0) return 0;
  return Math.ceil(distanceKm / bracketSizeKm);
}
```

- [ ] **Step 4: Run, expect PASS**

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "feat(domain): bracket-counter use case with tests"
```

---

## Task 1.11: Use case — cost-split-calculator

**Files:**
- Create: `src/domain/use-cases/cost-split-calculator.ts`
- Create: `tests/domain/use-cases/cost-split-calculator.test.ts`

> Reference (read the Dart source for the full algorithm including rounding rules):
> ```
> git show flutter-final-v0.7.0:lib/domain/use_cases/cost_split_calculator.dart
> ```
> The algorithm splits the total bracketed travel fee equally across stops, with edge cases for empty stops, single stop (full fee), and rounding so the sum of splits equals the total.

- [ ] **Step 1: Write the test (translate cases from `test/domain/cost_split_calculator_test.dart`)**

```ts
// tests/domain/use-cases/cost-split-calculator.test.ts
import { describe, it, expect } from 'vitest';
import { splitTravelCost } from '@/domain/use-cases/cost-split-calculator';

describe('splitTravelCost', () => {
  it('returns empty for no stops', () => {
    expect(splitTravelCost({
      totalDistanceKm: 25,
      stopCount: 0,
      pricePerBracket: 8,
      bracketSizeKm: 10,
    })).toEqual({ totalEuros: 24, perStop: [] });
  });

  it('full fee on single stop', () => {
    expect(splitTravelCost({
      totalDistanceKm: 25,
      stopCount: 1,
      pricePerBracket: 8,
      bracketSizeKm: 10,
    })).toEqual({ totalEuros: 24, perStop: [24] });
  });

  it('splits evenly when divisible', () => {
    // 20 km = 2 brackets * 8€ = 16€ split between 2 stops = 8€ each
    expect(splitTravelCost({
      totalDistanceKm: 20,
      stopCount: 2,
      pricePerBracket: 8,
      bracketSizeKm: 10,
    })).toEqual({ totalEuros: 16, perStop: [8, 8] });
  });

  it('handles non-divisible totals (sum equals total)', () => {
    // 25 km = 3 brackets * 8€ = 24€ split between 3 stops = 8€ each
    const r = splitTravelCost({
      totalDistanceKm: 25,
      stopCount: 3,
      pricePerBracket: 8,
      bracketSizeKm: 10,
    });
    expect(r.totalEuros).toBe(24);
    expect(r.perStop.reduce((a, b) => a + b, 0)).toBe(24);
    expect(r.perStop.length).toBe(3);
  });

  it('rounds to whole euros and adjusts to make the sum exact', () => {
    // 25 km = 3 brackets * 8€ = 24€ split between 5 stops = 4.8 each → 5,5,5,5,4 (or similar)
    const r = splitTravelCost({
      totalDistanceKm: 25,
      stopCount: 5,
      pricePerBracket: 8,
      bracketSizeKm: 10,
    });
    expect(r.totalEuros).toBe(24);
    expect(r.perStop.reduce((a, b) => a + b, 0)).toBe(24);
    expect(r.perStop.length).toBe(5);
    // Each share is 4 or 5 (no extreme distribution)
    for (const v of r.perStop) {
      expect(v === 4 || v === 5).toBe(true);
    }
  });
});
```

- [ ] **Step 2: Run, expect FAIL**

- [ ] **Step 3: Implement**

```ts
// src/domain/use-cases/cost-split-calculator.ts
import { countBrackets } from './bracket-counter';

interface Input {
  totalDistanceKm: number;
  stopCount: number;
  pricePerBracket: number;
  bracketSizeKm: number;
}

interface Output {
  totalEuros: number;
  perStop: number[];
}

export function splitTravelCost(input: Input): Output {
  const { totalDistanceKm, stopCount, pricePerBracket, bracketSizeKm } = input;

  const brackets = countBrackets(totalDistanceKm, bracketSizeKm);
  const totalEuros = brackets * pricePerBracket;

  if (stopCount === 0) {
    return { totalEuros, perStop: [] };
  }
  if (stopCount === 1) {
    return { totalEuros, perStop: [totalEuros] };
  }

  // Round each share to whole euros, distribute remainder one euro at a time.
  const baseShare = Math.floor(totalEuros / stopCount);
  let remainder = totalEuros - baseShare * stopCount;
  const perStop: number[] = [];
  for (let i = 0; i < stopCount; i++) {
    if (remainder > 0) {
      perStop.push(baseShare + 1);
      remainder--;
    } else {
      perStop.push(baseShare);
    }
  }
  return { totalEuros, perStop };
}
```

- [ ] **Step 4: Run, expect PASS**

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "feat(domain): cost-split-calculator with bracketed fee splitting"
```

---

## Task 1.12: Use case — tour-duration-estimator

**Files:**
- Create: `src/domain/use-cases/tour-duration-estimator.ts`
- Create: `tests/domain/use-cases/tour-duration-estimator.test.ts`

> Reference: `git show flutter-final-v0.7.0:lib/domain/use_cases/tour_duration_estimator.dart`. Algorithm: for each stop, compute shearing minutes from animalCounts × averageMinutesPerUnit per category, then add driving minutes from a distance matrix. Total = sum of stop minutes + travel minutes between stops.

- [ ] **Step 1: Write the test**

```ts
// tests/domain/use-cases/tour-duration-estimator.test.ts
import { describe, it, expect } from 'vitest';
import { estimateTourDuration } from '@/domain/use-cases/tour-duration-estimator';

const categoriesByMinutes = new Map<string, number>([
  ['sheep-adult', 20],
  ['sheep-lamb', 15],
]);

describe('estimateTourDuration', () => {
  it('returns 0 for an empty tour', () => {
    expect(estimateTourDuration({
      stops: [],
      travelMinutesBetween: () => 0,
      categoryMinutes: categoriesByMinutes,
    })).toBe(0);
  });

  it('sums shearing minutes for one stop', () => {
    expect(estimateTourDuration({
      stops: [{ clientId: 'c1', animalCounts: [{ categoryId: 'sheep-adult', count: 3 }] }],
      travelMinutesBetween: () => 0,
      categoryMinutes: categoriesByMinutes,
    })).toBe(60);
  });

  it('mixes categories', () => {
    expect(estimateTourDuration({
      stops: [{
        clientId: 'c1',
        animalCounts: [
          { categoryId: 'sheep-adult', count: 2 },   // 40
          { categoryId: 'sheep-lamb', count: 4 },    // 60
        ],
      }],
      travelMinutesBetween: () => 0,
      categoryMinutes: categoriesByMinutes,
    })).toBe(100);
  });

  it('adds travel time between stops (base → s1 → s2)', () => {
    const travel = (from: string, to: string) =>
      ({ 'BASE-c1': 10, 'c1-c2': 15 } as const)[`${from}-${to}` as 'BASE-c1' | 'c1-c2'] ?? 0;
    expect(estimateTourDuration({
      stops: [
        { clientId: 'c1', animalCounts: [{ categoryId: 'sheep-adult', count: 1 }] }, // 20
        { clientId: 'c2', animalCounts: [{ categoryId: 'sheep-adult', count: 2 }] }, // 40
      ],
      travelMinutesBetween: travel,
      categoryMinutes: categoriesByMinutes,
    })).toBe(20 + 40 + 10 + 15);
  });

  it('ignores unknown categoryIds', () => {
    expect(estimateTourDuration({
      stops: [{ clientId: 'c1', animalCounts: [{ categoryId: 'unknown', count: 5 }] }],
      travelMinutesBetween: () => 0,
      categoryMinutes: categoriesByMinutes,
    })).toBe(0);
  });
});
```

- [ ] **Step 2: Run, expect FAIL**

- [ ] **Step 3: Implement**

```ts
// src/domain/use-cases/tour-duration-estimator.ts
import type { AnimalCount } from '@/domain/models/animal-count';

interface Stop {
  clientId: string;
  animalCounts: AnimalCount[];
}

interface Input {
  stops: Stop[];
  /** Returns minutes for from → to, where from/to are 'BASE' or a clientId. */
  travelMinutesBetween: (from: string, to: string) => number;
  categoryMinutes: Map<string, number>;
}

export function estimateTourDuration({
  stops,
  travelMinutesBetween,
  categoryMinutes,
}: Input): number {
  if (stops.length === 0) return 0;

  let total = 0;
  let previousNode = 'BASE';
  for (const stop of stops) {
    total += travelMinutesBetween(previousNode, stop.clientId);
    for (const { categoryId, count } of stop.animalCounts) {
      const perUnit = categoryMinutes.get(categoryId) ?? 0;
      total += perUnit * count;
    }
    previousNode = stop.clientId;
  }
  return total;
}
```

- [ ] **Step 4: Run, expect PASS**

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "feat(domain): tour-duration-estimator with travel + shearing minutes"
```

---

## Task 1.13: Use case — find-nearby-clients

**Files:**
- Create: `src/domain/use-cases/find-nearby-clients.ts`
- Create: `tests/domain/use-cases/find-nearby-clients.test.ts`

> Reference: `git show flutter-final-v0.7.0:lib/domain/use_cases/find_nearby_clients.dart`. Returns clients within a radius of a pivot, sorted by distance ascending. Uses haversine for the proximity test (cheap), and only returns clients with valid coordinates.

- [ ] **Step 1: Test**

```ts
// tests/domain/use-cases/find-nearby-clients.test.ts
import { describe, it, expect } from 'vitest';
import { findNearbyClients } from '@/domain/use-cases/find-nearby-clients';

const pivot = { id: 'p', lat: 48.0, lon: -3.0 };

const within10km = { id: 'c1', lat: 48.05, lon: -3.0 };  // ~5.5 km
const within20km = { id: 'c2', lat: 48.15, lon: -3.0 };  // ~16.7 km
const within40km = { id: 'c3', lat: 48.3, lon: -3.0 };   // ~33.4 km
const noCoords = { id: 'c4', lat: null, lon: null };

describe('findNearbyClients', () => {
  it('returns only clients within the radius (excluding the pivot)', () => {
    const r = findNearbyClients({
      pivot,
      radiusKm: 20,
      clients: [pivot, within10km, within20km, within40km, noCoords],
    });
    expect(r.map((c) => c.id)).toEqual(['c1', 'c2']);
  });

  it('sorts by distance ascending', () => {
    const r = findNearbyClients({
      pivot,
      radiusKm: 50,
      clients: [within40km, within10km, within20km],
    });
    expect(r.map((c) => c.id)).toEqual(['c1', 'c2', 'c3']);
  });

  it('skips clients without coordinates', () => {
    const r = findNearbyClients({ pivot, radiusKm: 50, clients: [noCoords] });
    expect(r).toEqual([]);
  });

  it('throws for non-positive radius', () => {
    expect(() => findNearbyClients({ pivot, radiusKm: 0, clients: [] })).toThrow();
  });
});
```

- [ ] **Step 2: Run, expect FAIL**

- [ ] **Step 3: Implement**

```ts
// src/domain/use-cases/find-nearby-clients.ts
import { haversineDistanceKm } from '@/lib/haversine-distance';

interface ClientPoint {
  id: string;
  lat: number | null;
  lon: number | null;
}

interface Pivot {
  id: string;
  lat: number;
  lon: number;
}

interface Input {
  pivot: Pivot;
  radiusKm: number;
  clients: ClientPoint[];
}

export interface NearbyClient {
  id: string;
  distanceKm: number;
}

export function findNearbyClients({ pivot, radiusKm, clients }: Input): NearbyClient[] {
  if (radiusKm <= 0) {
    throw new Error('radiusKm must be positive');
  }
  const result: NearbyClient[] = [];
  for (const c of clients) {
    if (c.id === pivot.id) continue;
    if (c.lat == null || c.lon == null) continue;
    const distanceKm = haversineDistanceKm(
      { lat: pivot.lat, lon: pivot.lon },
      { lat: c.lat, lon: c.lon }
    );
    if (distanceKm <= radiusKm) {
      result.push({ id: c.id, distanceKm });
    }
  }
  return result.sort((a, b) => a.distanceKm - b.distanceKm);
}
```

- [ ] **Step 4: Run, expect PASS**

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "feat(domain): find-nearby-clients use case"
```

---

## Task 1.14: Use case — find-clients-near-anchors

**Files:**
- Create: `src/domain/use-cases/find-clients-near-anchors.ts`
- Create: `tests/domain/use-cases/find-clients-near-anchors.test.ts`

> Reference: `git show flutter-final-v0.7.0:lib/domain/use_cases/find_clients_near_anchors.dart`. Generalisation of `findNearbyClients`: given multiple anchors (pivots), return clients within radius of **any** anchor. Used by tour-builder when adding more clients to a draft tour. Same sort: by min distance to any anchor, ascending.

- [ ] **Step 1: Test**

```ts
// tests/domain/use-cases/find-clients-near-anchors.test.ts
import { describe, it, expect } from 'vitest';
import { findClientsNearAnchors } from '@/domain/use-cases/find-clients-near-anchors';

const anchorA = { id: 'a', lat: 48.0, lon: -3.0 };
const anchorB = { id: 'b', lat: 48.5, lon: -3.0 };

describe('findClientsNearAnchors', () => {
  it('includes clients close to any anchor', () => {
    const c1 = { id: 'c1', lat: 48.05, lon: -3.0 };  // close to A
    const c2 = { id: 'c2', lat: 48.45, lon: -3.0 };  // close to B
    const c3 = { id: 'c3', lat: 49.0, lon: -3.0 };   // far from both

    const r = findClientsNearAnchors({
      anchors: [anchorA, anchorB],
      radiusKm: 10,
      clients: [c1, c2, c3],
    });
    expect(r.map((c) => c.id).sort()).toEqual(['c1', 'c2']);
  });

  it('excludes anchor IDs themselves', () => {
    const r = findClientsNearAnchors({
      anchors: [anchorA, anchorB],
      radiusKm: 100,
      clients: [anchorA, anchorB, { id: 'c1', lat: 48.05, lon: -3.0 }],
    });
    expect(r.map((c) => c.id)).toEqual(['c1']);
  });

  it('sorts by minimum distance to any anchor', () => {
    const c1 = { id: 'c1', lat: 48.4, lon: -3.0 };   // ~11km to B
    const c2 = { id: 'c2', lat: 48.06, lon: -3.0 };  // ~6.7km to A

    const r = findClientsNearAnchors({
      anchors: [anchorA, anchorB],
      radiusKm: 50,
      clients: [c1, c2],
    });
    expect(r.map((c) => c.id)).toEqual(['c2', 'c1']);
  });
});
```

- [ ] **Step 2: Run, expect FAIL**

- [ ] **Step 3: Implement**

```ts
// src/domain/use-cases/find-clients-near-anchors.ts
import { haversineDistanceKm } from '@/lib/haversine-distance';

interface Anchor {
  id: string;
  lat: number;
  lon: number;
}

interface ClientPoint {
  id: string;
  lat: number | null;
  lon: number | null;
}

interface Input {
  anchors: Anchor[];
  radiusKm: number;
  clients: ClientPoint[];
}

export interface NearbyClient {
  id: string;
  distanceKm: number;
}

export function findClientsNearAnchors({ anchors, radiusKm, clients }: Input): NearbyClient[] {
  if (radiusKm <= 0) throw new Error('radiusKm must be positive');
  const anchorIds = new Set(anchors.map((a) => a.id));

  const result: NearbyClient[] = [];
  for (const c of clients) {
    if (anchorIds.has(c.id)) continue;
    if (c.lat == null || c.lon == null) continue;

    let minDistance = Infinity;
    for (const a of anchors) {
      const d = haversineDistanceKm({ lat: a.lat, lon: a.lon }, { lat: c.lat, lon: c.lon });
      if (d < minDistance) minDistance = d;
    }
    if (minDistance <= radiusKm) {
      result.push({ id: c.id, distanceKm: minDistance });
    }
  }
  return result.sort((a, b) => a.distanceKm - b.distanceKm);
}
```

- [ ] **Step 4: Run, expect PASS**

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "feat(domain): find-clients-near-anchors use case"
```

---

## Task 1.15: Use case — tour-order-optimizer (TSP nearest-neighbour with 2-opt)

**Files:**
- Create: `src/domain/use-cases/tour-order-optimizer.ts`
- Create: `tests/domain/use-cases/tour-order-optimizer.test.ts`

> Reference: `git show flutter-final-v0.7.0:lib/domain/use_cases/tour_order_optimizer.dart`. Algorithm: nearest-neighbour heuristic from BASE, optionally followed by a 2-opt improvement pass. Input: stop ids + driving distance matrix (n × n where row 0 = BASE). Output: permutation of stop ids minimising total drive distance.

- [ ] **Step 1: Test**

```ts
// tests/domain/use-cases/tour-order-optimizer.test.ts
import { describe, it, expect } from 'vitest';
import { optimizeTourOrder } from '@/domain/use-cases/tour-order-optimizer';

describe('optimizeTourOrder', () => {
  it('returns input order for zero or one stops', () => {
    expect(optimizeTourOrder({ stopIds: [], distanceKm: () => 0 })).toEqual([]);
    expect(optimizeTourOrder({ stopIds: ['a'], distanceKm: () => 0 })).toEqual(['a']);
  });

  it('picks nearest neighbour from base (3 collinear stops)', () => {
    // a is 5km from base, b is 10km, c is 15km. Optimal: a → b → c.
    const distances = new Map<string, number>([
      ['BASE-a', 5], ['BASE-b', 10], ['BASE-c', 15],
      ['a-b', 5], ['a-c', 10], ['b-c', 5],
      ['a-BASE', 5], ['b-BASE', 10], ['c-BASE', 15],
      ['b-a', 5], ['c-a', 10], ['c-b', 5],
    ]);
    const dist = (from: string, to: string) => distances.get(`${from}-${to}`) ?? 0;

    const r = optimizeTourOrder({ stopIds: ['c', 'a', 'b'], distanceKm: dist });
    expect(r).toEqual(['a', 'b', 'c']);
  });

  it('improves a sub-optimal nearest-neighbour result via 2-opt', () => {
    // Constructed case where greedy nearest-neighbour picks suboptimal first step.
    // Distance graph (km):
    //   BASE → a: 1, BASE → b: 100, BASE → c: 2
    //   a → b: 50, a → c: 60, b → c: 1
    //   (symmetric)
    // Greedy NN from BASE: a (1) → c (60) → b (1) = 62
    // 2-opt should find: BASE → a → b → c → BASE? Let's check: 1 + 50 + 1 = 52. Yes, 2-opt should pick that.
    const sym = (a: string, b: string, v: number) => [`${a}-${b}`, `${b}-${a}`].map((k) => [k, v] as const);
    const distances = new Map<string, number>([
      ...sym('BASE', 'a', 1),
      ...sym('BASE', 'b', 100),
      ...sym('BASE', 'c', 2),
      ...sym('a', 'b', 50),
      ...sym('a', 'c', 60),
      ...sym('b', 'c', 1),
    ]);
    const dist = (from: string, to: string) => distances.get(`${from}-${to}`) ?? 0;

    const r = optimizeTourOrder({ stopIds: ['a', 'b', 'c'], distanceKm: dist });
    expect(r).toEqual(['a', 'b', 'c']);
  });
});
```

- [ ] **Step 2: Run, expect FAIL**

- [ ] **Step 3: Implement**

```ts
// src/domain/use-cases/tour-order-optimizer.ts
interface Input {
  stopIds: string[];
  distanceKm: (from: string, to: string) => number;
  /** If true, run 2-opt after nearest-neighbour. Default: true. */
  twoOpt?: boolean;
}

export function optimizeTourOrder({ stopIds, distanceKm, twoOpt = true }: Input): string[] {
  if (stopIds.length <= 1) return [...stopIds];

  // Step 1: nearest-neighbour from BASE.
  const remaining = new Set(stopIds);
  const order: string[] = [];
  let current = 'BASE';
  while (remaining.size > 0) {
    let best: string | null = null;
    let bestD = Infinity;
    for (const id of remaining) {
      const d = distanceKm(current, id);
      if (d < bestD) {
        bestD = d;
        best = id;
      }
    }
    if (best == null) break;
    order.push(best);
    remaining.delete(best);
    current = best;
  }

  if (!twoOpt) return order;

  // Step 2: 2-opt improvement until no swap reduces total distance.
  const totalCost = (route: string[]): number => {
    let cost = distanceKm('BASE', route[0]!);
    for (let i = 0; i < route.length - 1; i++) {
      cost += distanceKm(route[i]!, route[i + 1]!);
    }
    cost += distanceKm(route[route.length - 1]!, 'BASE');
    return cost;
  };

  let improved = true;
  while (improved) {
    improved = false;
    for (let i = 0; i < order.length - 1; i++) {
      for (let j = i + 1; j < order.length; j++) {
        const candidate = [
          ...order.slice(0, i),
          ...order.slice(i, j + 1).reverse(),
          ...order.slice(j + 1),
        ];
        if (totalCost(candidate) < totalCost(order)) {
          order.splice(0, order.length, ...candidate);
          improved = true;
        }
      }
    }
  }

  return order;
}
```

- [ ] **Step 4: Run, expect PASS**

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "feat(domain): tour-order-optimizer (nearest-neighbour + 2-opt)"
```

---

## Task 1.16: Use cases — client-status, find-communes-with-waiting, build-tour-draft, build-optimized-tour-proposal

**Files:**
- Create: `src/domain/use-cases/client-status.ts` + test
- Create: `src/domain/use-cases/find-communes-with-waiting.ts` + test
- Create: `src/domain/use-cases/build-tour-draft.ts` + test
- Create: `src/domain/use-cases/build-optimized-tour-proposal.ts` + test

> These four are smaller orchestrators / projections. Read the Dart source for each:
> ```
> git show flutter-final-v0.7.0:lib/domain/use_cases/client_status.dart
> git show flutter-final-v0.7.0:lib/domain/use_cases/find_communes_with_waiting.dart
> git show flutter-final-v0.7.0:lib/domain/use_cases/build_tour_draft.dart
> git show flutter-final-v0.7.0:lib/domain/use_cases/build_optimized_tour_proposal.dart
> ```

- [ ] **Step 1: client-status**

Test (translate from `test/domain/client_status_test.dart` if present, otherwise derive from the Dart source):

```ts
// tests/domain/use-cases/client-status.test.ts
import { describe, it, expect } from 'vitest';
import { computeClientStatus } from '@/domain/use-cases/client-status';

describe('computeClientStatus', () => {
  const today = '2026-05-03';

  it('returns "waiting" when isWaiting=true', () => {
    expect(computeClientStatus({
      isWaiting: true,
      lastShearingDate: '2025-05-01',
      today,
    })).toBe('waiting');
  });

  it('returns "shorn-recent" when last shearing within 60 days', () => {
    expect(computeClientStatus({
      isWaiting: false,
      lastShearingDate: '2026-04-15',  // 18 days ago
      today,
    })).toBe('shorn-recent');
  });

  it('returns "shorn-old" when last shearing > 60 days ago', () => {
    expect(computeClientStatus({
      isWaiting: false,
      lastShearingDate: '2025-05-01',
      today,
    })).toBe('shorn-old');
  });

  it('returns "never" when no last shearing date and not waiting', () => {
    expect(computeClientStatus({
      isWaiting: false,
      lastShearingDate: null,
      today,
    })).toBe('never');
  });
});
```

Implementation:

```ts
// src/domain/use-cases/client-status.ts
export type ClientStatus = 'waiting' | 'shorn-recent' | 'shorn-old' | 'never';

interface Input {
  isWaiting: boolean;
  lastShearingDate: string | null;
  today: string;
  recentDays?: number;
}

export function computeClientStatus({
  isWaiting,
  lastShearingDate,
  today,
  recentDays = 60,
}: Input): ClientStatus {
  if (isWaiting) return 'waiting';
  if (!lastShearingDate) return 'never';

  const last = Date.parse(lastShearingDate);
  const now = Date.parse(today);
  const daysAgo = (now - last) / (1000 * 60 * 60 * 24);
  return daysAgo <= recentDays ? 'shorn-recent' : 'shorn-old';
}
```

Run vitest, commit:

```powershell
git add -A
git commit -m "feat(domain): client-status use case"
```

- [ ] **Step 2: find-communes-with-waiting**

Test:

```ts
// tests/domain/use-cases/find-communes-with-waiting.test.ts
import { describe, it, expect } from 'vitest';
import { findCommunesWithWaiting } from '@/domain/use-cases/find-communes-with-waiting';

describe('findCommunesWithWaiting', () => {
  it('groups waiting clients by city, sorted by count desc then name asc', () => {
    const r = findCommunesWithWaiting([
      { id: '1', isWaiting: true, addressCity: 'Quimper' },
      { id: '2', isWaiting: true, addressCity: 'Brest' },
      { id: '3', isWaiting: true, addressCity: 'Quimper' },
      { id: '4', isWaiting: false, addressCity: 'Vannes' },
      { id: '5', isWaiting: true, addressCity: 'Brest' },
      { id: '6', isWaiting: true, addressCity: null },
    ]);
    expect(r).toEqual([
      { city: 'Brest', count: 2 },
      { city: 'Quimper', count: 2 },
    ]);
  });
});
```

Implementation:

```ts
// src/domain/use-cases/find-communes-with-waiting.ts
interface ClientLite {
  id: string;
  isWaiting: boolean;
  addressCity: string | null;
}

export interface CommuneCount {
  city: string;
  count: number;
}

export function findCommunesWithWaiting(clients: ClientLite[]): CommuneCount[] {
  const counts = new Map<string, number>();
  for (const c of clients) {
    if (!c.isWaiting || !c.addressCity) continue;
    counts.set(c.addressCity, (counts.get(c.addressCity) ?? 0) + 1);
  }
  return [...counts.entries()]
    .map(([city, count]) => ({ city, count }))
    .sort((a, b) => b.count - a.count || a.city.localeCompare(b.city, 'fr'));
}
```

Run vitest, commit:

```powershell
git add -A
git commit -m "feat(domain): find-communes-with-waiting use case"
```

- [ ] **Step 3: build-tour-draft**

> Reads from the Dart source. The output is a `Tour` + initial `TourStop[]` with default ordering and arrival times computed from the input.

Test:

```ts
// tests/domain/use-cases/build-tour-draft.test.ts
import { describe, it, expect } from 'vitest';
import { buildTourDraft } from '@/domain/use-cases/build-tour-draft';

describe('buildTourDraft', () => {
  it('creates a draft tour with given client ids in given order, status=draft', () => {
    const r = buildTourDraft({
      scheduledDate: '2026-05-10',
      departureTime: '08:00',
      base: { lat: 48.0, lon: -3.0 },
      clientIds: ['c1', 'c2', 'c3'],
      now: '2026-05-03T12:00:00Z',
      newId: () => 'fixed-id',
    });
    expect(r.tour.status).toBe('draft');
    expect(r.tour.scheduledDate).toBe('2026-05-10');
    expect(r.tour.departureTime).toBe('08:00');
    expect(r.tour.baseLat).toBe(48.0);
    expect(r.tour.baseLng).toBe(-3.0);
    expect(r.stops.map((s) => s.clientId)).toEqual(['c1', 'c2', 'c3']);
    expect(r.stops.map((s) => s.ordering)).toEqual([0, 1, 2]);
    for (const s of r.stops) {
      expect(s.tourId).toBe(r.tour.id);
      expect(s.prestations).toEqual([]);
    }
  });
});
```

Implementation:

```ts
// src/domain/use-cases/build-tour-draft.ts
import type { Tour } from '@/domain/models/tour';
import type { TourStop } from '@/domain/models/tour-stop';

interface Input {
  scheduledDate: string;       // YYYY-MM-DD
  departureTime: string;       // HH:mm
  base: { lat: number; lon: number };
  clientIds: string[];
  now: string;                 // ISO 8601
  newId: () => string;
}

interface Output {
  tour: Tour;
  stops: TourStop[];
}

export function buildTourDraft({
  scheduledDate,
  departureTime,
  base,
  clientIds,
  now,
  newId,
}: Input): Output {
  const tourId = newId();
  const tour: Tour = {
    id: tourId,
    scheduledDate,
    departureTime,
    baseLat: base.lat,
    baseLng: base.lon,
    status: 'draft',
    totalDistanceKm: null,
    totalMinutes: null,
    createdAt: now,
    updatedAt: now,
  };
  const stops: TourStop[] = clientIds.map((clientId, index) => ({
    id: newId(),
    tourId,
    clientId,
    ordering: index,
    arrivalTime: null,
    estimatedMinutes: null,
    prestations: [],
    notes: null,
    completedAt: null,
  }));
  return { tour, stops };
}
```

Run vitest, commit:

```powershell
git add -A
git commit -m "feat(domain): build-tour-draft use case"
```

- [ ] **Step 4: build-optimized-tour-proposal**

> Composes `optimizeTourOrder` + `buildTourDraft`. Given clients + base + a distance matrix, produce a draft tour with the optimised ordering.

Test:

```ts
// tests/domain/use-cases/build-optimized-tour-proposal.test.ts
import { describe, it, expect } from 'vitest';
import { buildOptimizedTourProposal } from '@/domain/use-cases/build-optimized-tour-proposal';

describe('buildOptimizedTourProposal', () => {
  it('orders stops via optimizer and returns a draft tour', () => {
    const distances: Record<string, number> = {
      'BASE-a': 1, 'a-BASE': 1,
      'BASE-b': 100, 'b-BASE': 100,
      'BASE-c': 2, 'c-BASE': 2,
      'a-b': 50, 'b-a': 50,
      'a-c': 60, 'c-a': 60,
      'b-c': 1, 'c-b': 1,
    };
    const r = buildOptimizedTourProposal({
      scheduledDate: '2026-05-10',
      departureTime: '08:00',
      base: { lat: 48.0, lon: -3.0 },
      clientIds: ['a', 'b', 'c'],
      distanceKm: (f, t) => distances[`${f}-${t}`] ?? 0,
      now: '2026-05-03T12:00:00Z',
      newId: (() => { let n = 0; return () => `id-${n++}`; })(),
    });
    expect(r.stops.map((s) => s.clientId)).toEqual(['a', 'b', 'c']);
    expect(r.tour.status).toBe('draft');
  });
});
```

Implementation:

```ts
// src/domain/use-cases/build-optimized-tour-proposal.ts
import { optimizeTourOrder } from './tour-order-optimizer';
import { buildTourDraft } from './build-tour-draft';
import type { Tour } from '@/domain/models/tour';
import type { TourStop } from '@/domain/models/tour-stop';

interface Input {
  scheduledDate: string;
  departureTime: string;
  base: { lat: number; lon: number };
  clientIds: string[];
  distanceKm: (from: string, to: string) => number;
  now: string;
  newId: () => string;
}

interface Output {
  tour: Tour;
  stops: TourStop[];
}

export function buildOptimizedTourProposal(input: Input): Output {
  const orderedIds = optimizeTourOrder({
    stopIds: input.clientIds,
    distanceKm: input.distanceKm,
  });
  return buildTourDraft({
    scheduledDate: input.scheduledDate,
    departureTime: input.departureTime,
    base: input.base,
    clientIds: orderedIds,
    now: input.now,
    newId: input.newId,
  });
}
```

Run vitest, commit:

```powershell
git add -A
git commit -m "feat(domain): build-optimized-tour-proposal use case"
```

---

## Task 1.17: Repository — SettingsRepository

**Files:**
- Create: `src/data/repositories/settings-repository.ts`
- Create: `tests/data/settings-repository.test.ts`

> All repos in this phase use the same TDD shape: write tests against an in-memory SQLite, implement, commit. We use jest (not vitest) because the test runs Drizzle which depends on `expo-sqlite`. We mock `expo-sqlite` with `better-sqlite3` for tests via a small helper.

- [ ] **Step 1: Install better-sqlite3 (test-only) and create a test helper**

```powershell
pnpm add -D better-sqlite3 @types/better-sqlite3 drizzle-orm
```

- [ ] **Step 2: Create `tests/data/_helpers/test-db.ts`**

```ts
// tests/data/_helpers/test-db.ts
import Database from 'better-sqlite3';
import { drizzle } from 'drizzle-orm/better-sqlite3';
import { migrate } from 'drizzle-orm/better-sqlite3/migrator';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const migrationsFolder = resolve(here, '..', '..', '..', 'src', 'infra', 'db', 'migrations');

export function createTestDb() {
  const sqlite = new Database(':memory:');
  const db = drizzle(sqlite);
  migrate(db, { migrationsFolder });
  return { db, close: () => sqlite.close() };
}
```

> Note: `migrate` for `better-sqlite3` reads `.sql` files directly from `migrationsFolder`. This works because Drizzle generated raw SQL files in Task 1.2.

- [ ] **Step 3: Test**

```ts
// tests/data/settings-repository.test.ts
import { createTestDb } from './_helpers/test-db';
import { SettingsRepository } from '@/data/repositories/settings-repository';

describe('SettingsRepository', () => {
  it('get returns null for unknown keys', async () => {
    const { db, close } = createTestDb();
    const repo = new SettingsRepository(db);
    expect(await repo.get('unknown')).toBeNull();
    close();
  });

  it('set then get returns value', async () => {
    const { db, close } = createTestDb();
    const repo = new SettingsRepository(db);
    await repo.set('theme_mode', 'dark');
    expect(await repo.get('theme_mode')).toBe('dark');
    close();
  });

  it('set overwrites existing value', async () => {
    const { db, close } = createTestDb();
    const repo = new SettingsRepository(db);
    await repo.set('theme_mode', 'light');
    await repo.set('theme_mode', 'dark');
    expect(await repo.get('theme_mode')).toBe('dark');
    close();
  });

  it('getAll returns a map of all settings', async () => {
    const { db, close } = createTestDb();
    const repo = new SettingsRepository(db);
    await repo.set('a', '1');
    await repo.set('b', '2');
    const all = await repo.getAll();
    expect(all).toEqual({ a: '1', b: '2' });
    close();
  });
});
```

- [ ] **Step 4: Run, expect FAIL** — `pnpm jest tests/data/settings-repository.test.ts`

- [ ] **Step 5: Implement**

```ts
// src/data/repositories/settings-repository.ts
import { eq } from 'drizzle-orm';
import { settings } from '@/infra/db/schema';

export class SettingsRepository {
  constructor(private readonly db: any) {}

  async get(key: string): Promise<string | null> {
    const rows = await this.db.select().from(settings).where(eq(settings.key, key));
    return rows[0]?.value ?? null;
  }

  async set(key: string, value: string): Promise<void> {
    await this.db
      .insert(settings)
      .values({ key, value })
      .onConflictDoUpdate({ target: settings.key, set: { value } });
  }

  async getAll(): Promise<Record<string, string>> {
    const rows = await this.db.select().from(settings);
    const out: Record<string, string> = {};
    for (const r of rows) out[r.key] = r.value;
    return out;
  }
}
```

- [ ] **Step 6: Run, expect PASS**

- [ ] **Step 7: Commit**

```powershell
git add -A
git commit -m "feat(data): settings repository with tests"
```

---

## Task 1.18: Repository — ClientRepository

**Files:**
- Create: `src/data/repositories/client-repository.ts`
- Create: `tests/data/client-repository.test.ts`

- [ ] **Step 1: Test**

```ts
// tests/data/client-repository.test.ts
import { createTestDb } from './_helpers/test-db';
import { ClientRepository } from '@/data/repositories/client-repository';

const NOW = '2026-05-03T12:00:00.000Z';

const sample = {
  id: 'c1',
  displayName: 'Jean Dupont',
  firstName: 'Jean',
  lastName: 'Dupont',
  phones: ['0612345678'],
  email: 'jean@example.com',
  addressLabel: '1 rue du Test, 29000 Quimper',
  addressCity: 'Quimper',
  addressPostcode: '29000',
  latitude: 48.0,
  longitude: -4.1,
  isWaiting: true,
  notes: null,
  lastShearingDate: null,
  animalCounts: [{ categoryId: 'sheep-adult', count: 12 }],
  createdAt: NOW,
  updatedAt: NOW,
};

describe('ClientRepository', () => {
  it('inserts and reads back a client (round-trip JSON fields)', async () => {
    const { db, close } = createTestDb();
    const repo = new ClientRepository(db);
    await repo.upsert(sample);
    const fetched = await repo.byId('c1');
    expect(fetched).toEqual(sample);
    close();
  });

  it('listAll returns all clients', async () => {
    const { db, close } = createTestDb();
    const repo = new ClientRepository(db);
    await repo.upsert(sample);
    await repo.upsert({ ...sample, id: 'c2', displayName: 'Marie' });
    const all = await repo.listAll();
    expect(all).toHaveLength(2);
    close();
  });

  it('listWaiting filters by isWaiting=true', async () => {
    const { db, close } = createTestDb();
    const repo = new ClientRepository(db);
    await repo.upsert(sample);
    await repo.upsert({ ...sample, id: 'c2', displayName: 'Marie', isWaiting: false });
    const waiting = await repo.listWaiting();
    expect(waiting.map((c) => c.id)).toEqual(['c1']);
    close();
  });

  it('setWaiting toggles the flag', async () => {
    const { db, close } = createTestDb();
    const repo = new ClientRepository(db);
    await repo.upsert({ ...sample, isWaiting: false });
    await repo.setWaiting('c1', true, NOW);
    expect((await repo.byId('c1'))!.isWaiting).toBe(true);
    close();
  });

  it('delete removes a client', async () => {
    const { db, close } = createTestDb();
    const repo = new ClientRepository(db);
    await repo.upsert(sample);
    await repo.delete('c1');
    expect(await repo.byId('c1')).toBeNull();
    close();
  });
});
```

- [ ] **Step 2: Run, expect FAIL**

- [ ] **Step 3: Implement**

```ts
// src/data/repositories/client-repository.ts
import { eq } from 'drizzle-orm';
import { clients } from '@/infra/db/schema';
import { Client } from '@/domain/models/client';

function toRow(c: Client) {
  return {
    id: c.id,
    displayName: c.displayName,
    firstName: c.firstName,
    lastName: c.lastName,
    phones: JSON.stringify(c.phones),
    email: c.email,
    addressLabel: c.addressLabel,
    addressCity: c.addressCity,
    addressPostcode: c.addressPostcode,
    latitude: c.latitude,
    longitude: c.longitude,
    isWaiting: c.isWaiting ? 1 : 0,
    notes: c.notes,
    lastShearingDate: c.lastShearingDate,
    animalCounts: JSON.stringify(c.animalCounts),
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
  };
}

function fromRow(r: any): Client {
  return Client.parse({
    id: r.id,
    displayName: r.displayName,
    firstName: r.firstName,
    lastName: r.lastName,
    phones: JSON.parse(r.phones),
    email: r.email,
    addressLabel: r.addressLabel,
    addressCity: r.addressCity,
    addressPostcode: r.addressPostcode,
    latitude: r.latitude,
    longitude: r.longitude,
    isWaiting: r.isWaiting === 1,
    notes: r.notes,
    lastShearingDate: r.lastShearingDate,
    animalCounts: JSON.parse(r.animalCounts),
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  });
}

export class ClientRepository {
  constructor(private readonly db: any) {}

  async byId(id: string): Promise<Client | null> {
    const rows = await this.db.select().from(clients).where(eq(clients.id, id));
    return rows[0] ? fromRow(rows[0]) : null;
  }

  async listAll(): Promise<Client[]> {
    const rows = await this.db.select().from(clients);
    return rows.map(fromRow);
  }

  async listWaiting(): Promise<Client[]> {
    const rows = await this.db.select().from(clients).where(eq(clients.isWaiting, 1));
    return rows.map(fromRow);
  }

  async upsert(c: Client): Promise<void> {
    const row = toRow(c);
    await this.db
      .insert(clients)
      .values(row)
      .onConflictDoUpdate({ target: clients.id, set: row });
  }

  async setWaiting(id: string, isWaiting: boolean, updatedAt: string): Promise<void> {
    await this.db
      .update(clients)
      .set({ isWaiting: isWaiting ? 1 : 0, updatedAt })
      .where(eq(clients.id, id));
  }

  async delete(id: string): Promise<void> {
    await this.db.delete(clients).where(eq(clients.id, id));
  }
}
```

- [ ] **Step 4: Run, expect PASS**

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "feat(data): client repository with CRUD + waiting filter + tests"
```

---

## Task 1.19: Repositories — Species, AnimalCategory, Prestation, ManualHistory, DistanceMatrix

**Files:**
- Create: `src/data/repositories/species-repository.ts`
- Create: `src/data/repositories/animal-category-repository.ts`
- Create: `src/data/repositories/prestation-repository.ts`
- Create: `src/data/repositories/manual-history-repository.ts`
- Create: `src/data/repositories/distance-matrix-repository.ts`
- Create one test file per repo under `tests/data/`

> Each follows the same pattern as ClientRepository: `byId`, `listAll`, `upsert`, `delete` for simple cases. The DistanceMatrix repo needs a composite-key API (`byPair(fromId, toId)`, `upsertEntry(...)`, `pairsOlderThan(date): Pair[]`).

- [ ] **Step 1: SpeciesRepository — write test, run (fail), implement, run (pass), commit**

Test (`tests/data/species-repository.test.ts`):

```ts
import { createTestDb } from './_helpers/test-db';
import { SpeciesRepository } from '@/data/repositories/species-repository';

const sheep = { id: 'sheep', label: 'Mouton', color: '#A1602F', ordering: 0, isCustom: false };

describe('SpeciesRepository', () => {
  it('round-trips a species', async () => {
    const { db, close } = createTestDb();
    const repo = new SpeciesRepository(db);
    await repo.upsert(sheep);
    const all = await repo.listAll();
    expect(all).toContainEqual(sheep);
    close();
  });
});
```

Implementation:

```ts
// src/data/repositories/species-repository.ts
import { eq, asc } from 'drizzle-orm';
import { species } from '@/infra/db/schema';
import { Species } from '@/domain/models/species';

function toRow(s: Species) {
  return { ...s, isCustom: s.isCustom ? 1 : 0 };
}
function fromRow(r: any): Species {
  return Species.parse({ ...r, isCustom: r.isCustom === 1 });
}

export class SpeciesRepository {
  constructor(private readonly db: any) {}

  async byId(id: string): Promise<Species | null> {
    const rows = await this.db.select().from(species).where(eq(species.id, id));
    return rows[0] ? fromRow(rows[0]) : null;
  }
  async listAll(): Promise<Species[]> {
    const rows = await this.db.select().from(species).orderBy(asc(species.ordering));
    return rows.map(fromRow);
  }
  async upsert(s: Species): Promise<void> {
    const row = toRow(s);
    await this.db.insert(species).values(row).onConflictDoUpdate({ target: species.id, set: row });
  }
  async delete(id: string): Promise<void> {
    await this.db.delete(species).where(eq(species.id, id));
  }
}
```

Run, commit:

```powershell
pnpm jest tests/data/species-repository.test.ts
git add -A
git commit -m "feat(data): species repository with tests"
```

- [ ] **Step 2: AnimalCategoryRepository**

Same pattern. Add `listBySpeciesId(speciesId)` returning categories ordered by `ordering` asc. Test for: round-trip + filter by species. Commit.

```ts
// src/data/repositories/animal-category-repository.ts
import { asc, eq } from 'drizzle-orm';
import { animalCategories } from '@/infra/db/schema';
import { AnimalCategory } from '@/domain/models/animal-category';

function toRow(c: AnimalCategory) { return { ...c, isCustom: c.isCustom ? 1 : 0 }; }
function fromRow(r: any): AnimalCategory {
  return AnimalCategory.parse({ ...r, isCustom: r.isCustom === 1 });
}

export class AnimalCategoryRepository {
  constructor(private readonly db: any) {}

  async listAll(): Promise<AnimalCategory[]> {
    const rows = await this.db.select().from(animalCategories).orderBy(asc(animalCategories.ordering));
    return rows.map(fromRow);
  }
  async listBySpecies(speciesId: string): Promise<AnimalCategory[]> {
    const rows = await this.db
      .select()
      .from(animalCategories)
      .where(eq(animalCategories.speciesId, speciesId))
      .orderBy(asc(animalCategories.ordering));
    return rows.map(fromRow);
  }
  async upsert(c: AnimalCategory): Promise<void> {
    const row = toRow(c);
    await this.db
      .insert(animalCategories)
      .values(row)
      .onConflictDoUpdate({ target: animalCategories.id, set: row });
  }
  async delete(id: string): Promise<void> {
    await this.db.delete(animalCategories).where(eq(animalCategories.id, id));
  }
}
```

Test (`tests/data/animal-category-repository.test.ts`):

```ts
import { createTestDb } from './_helpers/test-db';
import { SpeciesRepository } from '@/data/repositories/species-repository';
import { AnimalCategoryRepository } from '@/data/repositories/animal-category-repository';

describe('AnimalCategoryRepository', () => {
  it('lists categories by species', async () => {
    const { db, close } = createTestDb();
    const sRepo = new SpeciesRepository(db);
    const cRepo = new AnimalCategoryRepository(db);
    await sRepo.upsert({ id: 'sheep', label: 'Mouton', color: null, ordering: 0, isCustom: false });
    await cRepo.upsert({
      id: 'sheep-adult', speciesId: 'sheep', label: 'Brebis adulte',
      averageMinutesPerUnit: 20, ordering: 0, isCustom: false,
    });
    const cats = await cRepo.listBySpecies('sheep');
    expect(cats).toHaveLength(1);
    expect(cats[0]!.id).toBe('sheep-adult');
    close();
  });
});
```

Run, commit:

```powershell
pnpm jest tests/data/animal-category-repository.test.ts
git add -A
git commit -m "feat(data): animal-category repository with tests"
```

- [ ] **Step 3: PrestationRepository**

Mirror Species pattern. Test round-trip. Implementation:

```ts
// src/data/repositories/prestation-repository.ts
import { asc, eq } from 'drizzle-orm';
import { prestations } from '@/infra/db/schema';
import { Prestation } from '@/domain/models/prestation';

function toRow(p: Prestation) { return { ...p, isActive: p.isActive ? 1 : 0 }; }
function fromRow(r: any): Prestation {
  return Prestation.parse({ ...r, isActive: r.isActive === 1 });
}

export class PrestationRepository {
  constructor(private readonly db: any) {}

  async listAll(): Promise<Prestation[]> {
    const rows = await this.db.select().from(prestations).orderBy(asc(prestations.ordering));
    return rows.map(fromRow);
  }
  async listActive(): Promise<Prestation[]> {
    const rows = await this.db
      .select()
      .from(prestations)
      .where(eq(prestations.isActive, 1))
      .orderBy(asc(prestations.ordering));
    return rows.map(fromRow);
  }
  async upsert(p: Prestation): Promise<void> {
    const row = toRow(p);
    await this.db.insert(prestations).values(row).onConflictDoUpdate({ target: prestations.id, set: row });
  }
  async delete(id: string): Promise<void> {
    await this.db.delete(prestations).where(eq(prestations.id, id));
  }
}
```

Test, run, commit:

```powershell
git add -A
git commit -m "feat(data): prestation repository with tests"
```

- [ ] **Step 4: ManualHistoryRepository**

```ts
// src/data/repositories/manual-history-repository.ts
import { desc, eq } from 'drizzle-orm';
import { manualHistoryEntries } from '@/infra/db/schema';
import { ManualHistoryEntry } from '@/domain/models/manual-history-entry';

function toRow(e: ManualHistoryEntry) {
  return { ...e, prestations: JSON.stringify(e.prestations) };
}
function fromRow(r: any): ManualHistoryEntry {
  return ManualHistoryEntry.parse({ ...r, prestations: JSON.parse(r.prestations) });
}

export class ManualHistoryRepository {
  constructor(private readonly db: any) {}

  async listByClient(clientId: string): Promise<ManualHistoryEntry[]> {
    const rows = await this.db
      .select()
      .from(manualHistoryEntries)
      .where(eq(manualHistoryEntries.clientId, clientId))
      .orderBy(desc(manualHistoryEntries.date));
    return rows.map(fromRow);
  }
  async upsert(e: ManualHistoryEntry): Promise<void> {
    const row = toRow(e);
    await this.db
      .insert(manualHistoryEntries)
      .values(row)
      .onConflictDoUpdate({ target: manualHistoryEntries.id, set: row });
  }
  async delete(id: string): Promise<void> {
    await this.db.delete(manualHistoryEntries).where(eq(manualHistoryEntries.id, id));
  }
}
```

Test the listByClient ordering by date desc, run, commit.

```powershell
git add -A
git commit -m "feat(data): manual-history repository with tests"
```

- [ ] **Step 5: DistanceMatrixRepository**

```ts
// src/data/repositories/distance-matrix-repository.ts
import { and, eq, lt } from 'drizzle-orm';
import { distanceMatrix } from '@/infra/db/schema';
import { DistanceMatrixEntry } from '@/domain/models/distance-matrix-entry';

function fromRow(r: any): DistanceMatrixEntry {
  return DistanceMatrixEntry.parse(r);
}

export class DistanceMatrixRepository {
  constructor(private readonly db: any) {}

  async byPair(fromId: string, toId: string): Promise<DistanceMatrixEntry | null> {
    const rows = await this.db
      .select()
      .from(distanceMatrix)
      .where(and(eq(distanceMatrix.fromId, fromId), eq(distanceMatrix.toId, toId)));
    return rows[0] ? fromRow(rows[0]) : null;
  }

  async upsert(entry: DistanceMatrixEntry): Promise<void> {
    await this.db
      .insert(distanceMatrix)
      .values(entry)
      .onConflictDoUpdate({
        target: [distanceMatrix.fromId, distanceMatrix.toId],
        set: entry,
      });
  }

  async upsertMany(entries: DistanceMatrixEntry[]): Promise<void> {
    for (const e of entries) {
      await this.upsert(e);
    }
  }

  async deleteOlderThan(isoDate: string): Promise<void> {
    await this.db.delete(distanceMatrix).where(lt(distanceMatrix.fetchedAt, isoDate));
  }

  async listAll(): Promise<DistanceMatrixEntry[]> {
    const rows = await this.db.select().from(distanceMatrix);
    return rows.map(fromRow);
  }
}
```

Test:

```ts
// tests/data/distance-matrix-repository.test.ts
import { createTestDb } from './_helpers/test-db';
import { DistanceMatrixRepository } from '@/data/repositories/distance-matrix-repository';

describe('DistanceMatrixRepository', () => {
  it('upserts and reads pairs', async () => {
    const { db, close } = createTestDb();
    const repo = new DistanceMatrixRepository(db);
    await repo.upsert({ fromId: 'BASE', toId: 'c1', distanceKm: 12.4, durationMinutes: 18, fetchedAt: '2026-05-03T12:00:00Z' });
    const r = await repo.byPair('BASE', 'c1');
    expect(r?.distanceKm).toBe(12.4);
    close();
  });

  it('deletes entries older than a date', async () => {
    const { db, close } = createTestDb();
    const repo = new DistanceMatrixRepository(db);
    await repo.upsert({ fromId: 'BASE', toId: 'a', distanceKm: 1, durationMinutes: 1, fetchedAt: '2026-01-01T00:00:00Z' });
    await repo.upsert({ fromId: 'BASE', toId: 'b', distanceKm: 1, durationMinutes: 1, fetchedAt: '2026-04-01T00:00:00Z' });
    await repo.deleteOlderThan('2026-03-01T00:00:00Z');
    expect(await repo.byPair('BASE', 'a')).toBeNull();
    expect(await repo.byPair('BASE', 'b')).not.toBeNull();
    close();
  });
});
```

Run, commit:

```powershell
git add -A
git commit -m "feat(data): distance-matrix repository with tests"
```

---

## Task 1.20: Repository — TourRepository (with tour stops)

**Files:**
- Create: `src/data/repositories/tour-repository.ts`
- Create: `tests/data/tour-repository.test.ts`

> The TourRepository owns both `tours` and `tour_stops` tables since they're tightly coupled (a tour is meaningless without its stops). API: `byId(id)` returns `{ tour, stops }`, `listAll()`, `listByStatus(status)`, `upsertTour(t, stops)` (transactional), `deleteTour(id)`, `markStopCompleted(stopId, date)`.

- [ ] **Step 1: Test (key cases)**

```ts
// tests/data/tour-repository.test.ts
import { createTestDb } from './_helpers/test-db';
import { ClientRepository } from '@/data/repositories/client-repository';
import { TourRepository } from '@/data/repositories/tour-repository';

const NOW = '2026-05-03T12:00:00.000Z';

const sampleClient = (id: string) => ({
  id,
  displayName: id,
  firstName: null, lastName: null, phones: [], email: null,
  addressLabel: null, addressCity: null, addressPostcode: null,
  latitude: 48, longitude: -3,
  isWaiting: false, notes: null, lastShearingDate: null, animalCounts: [],
  createdAt: NOW, updatedAt: NOW,
});

const sampleTour = {
  id: 't1',
  scheduledDate: '2026-05-10',
  departureTime: '08:00',
  baseLat: 48.0, baseLng: -3.0,
  status: 'draft' as const,
  totalDistanceKm: null, totalMinutes: null,
  createdAt: NOW, updatedAt: NOW,
};

const sampleStops = [
  { id: 's1', tourId: 't1', clientId: 'c1', ordering: 0, arrivalTime: null,
    estimatedMinutes: null, prestations: [], notes: null, completedAt: null },
  { id: 's2', tourId: 't1', clientId: 'c2', ordering: 1, arrivalTime: null,
    estimatedMinutes: null, prestations: [], notes: null, completedAt: null },
];

describe('TourRepository', () => {
  it('round-trips a tour with stops', async () => {
    const { db, close } = createTestDb();
    const cRepo = new ClientRepository(db);
    const tRepo = new TourRepository(db);
    await cRepo.upsert(sampleClient('c1'));
    await cRepo.upsert(sampleClient('c2'));
    await tRepo.upsertTour(sampleTour, sampleStops);
    const r = await tRepo.byId('t1');
    expect(r?.tour.id).toBe('t1');
    expect(r?.stops.map((s) => s.id)).toEqual(['s1', 's2']);
    close();
  });

  it('replaces stops on upsert (no duplicates)', async () => {
    const { db, close } = createTestDb();
    const cRepo = new ClientRepository(db);
    const tRepo = new TourRepository(db);
    await cRepo.upsert(sampleClient('c1'));
    await cRepo.upsert(sampleClient('c2'));
    await tRepo.upsertTour(sampleTour, sampleStops);
    await tRepo.upsertTour(sampleTour, [sampleStops[0]!]);
    const r = await tRepo.byId('t1');
    expect(r?.stops.map((s) => s.id)).toEqual(['s1']);
    close();
  });

  it('listByStatus filters', async () => {
    const { db, close } = createTestDb();
    const cRepo = new ClientRepository(db);
    const tRepo = new TourRepository(db);
    await cRepo.upsert(sampleClient('c1'));
    await tRepo.upsertTour(sampleTour, [sampleStops[0]!]);
    await tRepo.upsertTour({ ...sampleTour, id: 't2', status: 'completed' as const }, []);
    expect((await tRepo.listByStatus('draft')).map((x) => x.tour.id)).toEqual(['t1']);
    expect((await tRepo.listByStatus('completed')).map((x) => x.tour.id)).toEqual(['t2']);
    close();
  });
});
```

- [ ] **Step 2: Implement**

```ts
// src/data/repositories/tour-repository.ts
import { asc, eq } from 'drizzle-orm';
import { tours, tourStops } from '@/infra/db/schema';
import { Tour, type TourStatus } from '@/domain/models/tour';
import { TourStop } from '@/domain/models/tour-stop';

function tourToRow(t: Tour) { return t; }
function tourFromRow(r: any): Tour { return Tour.parse(r); }

function stopToRow(s: TourStop) {
  return { ...s, prestations: JSON.stringify(s.prestations) };
}
function stopFromRow(r: any): TourStop {
  return TourStop.parse({ ...r, prestations: JSON.parse(r.prestations) });
}

export interface TourWithStops {
  tour: Tour;
  stops: TourStop[];
}

export class TourRepository {
  constructor(private readonly db: any) {}

  async byId(id: string): Promise<TourWithStops | null> {
    const tRows = await this.db.select().from(tours).where(eq(tours.id, id));
    if (!tRows[0]) return null;
    const sRows = await this.db
      .select()
      .from(tourStops)
      .where(eq(tourStops.tourId, id))
      .orderBy(asc(tourStops.ordering));
    return { tour: tourFromRow(tRows[0]), stops: sRows.map(stopFromRow) };
  }

  async listAll(): Promise<TourWithStops[]> {
    const tRows = await this.db.select().from(tours);
    const result: TourWithStops[] = [];
    for (const tr of tRows) {
      const sRows = await this.db
        .select()
        .from(tourStops)
        .where(eq(tourStops.tourId, tr.id))
        .orderBy(asc(tourStops.ordering));
      result.push({ tour: tourFromRow(tr), stops: sRows.map(stopFromRow) });
    }
    return result;
  }

  async listByStatus(status: TourStatus): Promise<TourWithStops[]> {
    const tRows = await this.db.select().from(tours).where(eq(tours.status, status));
    const result: TourWithStops[] = [];
    for (const tr of tRows) {
      const sRows = await this.db
        .select()
        .from(tourStops)
        .where(eq(tourStops.tourId, tr.id))
        .orderBy(asc(tourStops.ordering));
      result.push({ tour: tourFromRow(tr), stops: sRows.map(stopFromRow) });
    }
    return result;
  }

  async upsertTour(t: Tour, stops: TourStop[]): Promise<void> {
    const tRow = tourToRow(t);
    await this.db.insert(tours).values(tRow).onConflictDoUpdate({ target: tours.id, set: tRow });
    await this.db.delete(tourStops).where(eq(tourStops.tourId, t.id));
    for (const s of stops) {
      await this.db.insert(tourStops).values(stopToRow(s));
    }
  }

  async deleteTour(id: string): Promise<void> {
    await this.db.delete(tours).where(eq(tours.id, id));
  }

  async markStopCompleted(stopId: string, completedAt: string): Promise<void> {
    await this.db.update(tourStops).set({ completedAt }).where(eq(tourStops.id, stopId));
  }
}
```

- [ ] **Step 3: Run, expect PASS**

- [ ] **Step 4: Commit**

```powershell
git add -A
git commit -m "feat(data): tour repository (tours + tour_stops) with tests"
```

---

## Phase 1 — End checklist

- [ ] All schema tables defined in Drizzle, migration generated and bundled
- [ ] App boots, runs migrations, seeds species + prestations on first launch
- [ ] All domain models defined as Zod schemas with TS types inferred
- [ ] All lib utilities implemented and tested (haversine, format-minutes, phone normalizer/formatter, text-search, text-pluralization, animal-counts merge/normalize)
- [ ] All use cases ported with their tests passing (bracket-counter, cost-split, tour-duration, find-nearby-clients, find-clients-near-anchors, tour-order-optimizer, build-tour-draft, build-optimized-tour-proposal, client-status, find-communes-with-waiting)
- [ ] All repositories implemented and tested (settings, clients, species, animal-categories, prestations, manual-history, distance-matrix, tours)
- [ ] `pnpm test` green (vitest + jest both pass)
- [ ] `pnpm typecheck` clean

**You're ready for Phase 2.** Move to [`02-settings-theming.md`](./02-settings-theming.md).
