# RGPD MVP — Anonymisation client (Section B) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer le « delete client » actuel (qui plante en présence de tour stops à cause d'une FK `notNull()`) par une vraie anonymisation conforme RGPD : scrub identité + adresse + notes, préservation des éléments comptables (montants, dates, paiements) conformément à l'art. L123-22 du Code de commerce.

**Architecture:** Nouveau use case domaine pur `planAnonymization` (zéro I/O, testable). Nouvelle méthode `ClientRepository.anonymize(id, now)` qui exécute le plan dans une transaction unique. Filtrage des clients anonymisés hors des listes UI via une nouvelle colonne `clients.anonymized_at`. Bump du backup schema v3 → v4 pour transporter la nouvelle colonne. La mutation `useDeleteClient` existante est renommée `useAnonymizeClient` et bascule sur la nouvelle méthode repo. L'écran fiche client utilise `ConfirmTypedDialog` (mot `SUPPRIMER` à taper) au lieu du simple `confirm()`.

**Tech Stack:** TypeScript, Zod, Drizzle ORM, vitest (`tests/domain`), jest (`tests/data`), `@tanstack/react-query`, NativeWind, i18next.

---

## Spec reference

Implements Section B de `docs/superpowers/specs/2026-05-06-rgpd-mvp-design.md`. Re-lire la spec si quelque chose ci-dessous est flou.

## Conventions (from CLAUDE.md)

- Package manager : **pnpm**.
- Tous identifiants / chemins / clés i18n en **anglais**. Le français vit uniquement dans `src/i18n/locales/fr.json` (valeurs).
- Tests : `pnpm test:domain` (vitest), `pnpm test:integration` (jest), ou `pnpm test` pour les deux.
- TS strict, pas de `any`.
- Cents en entiers partout où il y a de l'argent.

## Préalable

Aucun. Ce plan est autonome et peut partir avant ou après les Sections A/C.

## File structure

### Created

- `src/domain/use-cases/anonymize-client.ts`
- `tests/domain/anonymize-client.test.ts`
- `tests/data/client-repository-anonymize.test.ts`
- `src/infra/db/migrations/0005_client_anonymized_at.sql` (généré par drizzle-kit)

### Modified

- `src/domain/models/client.ts` (ajout `anonymizedAt`)
- `src/infra/db/schema.ts` (ajout `anonymizedAt` colonne)
- `src/infra/db/migrations/migrations.js` + `meta/_journal.json` (régénérés)
- `src/infra/cloud/backup-schema.ts` (bump v3 → v4 + helper `migrateV3ToV4`)
- `src/infra/cloud/backups.ts` (chaîne de restore mise à jour)
- `src/data/repositories/client-repository.ts` (ajout `anonymize`, ajout filtre `activeClientsFilter` sur les listings)
- `src/state/queries/clients.ts` (rename `useDeleteClient` → `useAnonymizeClient`, mutation appelle `anonymize`)
- `app/(tabs)/clients/[id].tsx` (callsite renommé, dialog typé, redirection si anonymisé)
- `src/i18n/locales/fr.json` (mise à jour de `clients.delete_confirm_message`, ajout de quelques clés)

### Deleted

Aucun. La méthode `ClientRepository.delete(id)` est conservée pour `wipeLocalDatabase` et tests futurs.

---

## Task 1 — Ajouter `anonymizedAt` au modèle domaine

**Files:**
- Modify: `src/domain/models/client.ts`

- [ ] **Step 1 : Ajouter le champ au schema Zod**

Modifier `src/domain/models/client.ts` :

```ts
import { z } from 'zod';
import { AnimalCountList } from './animal-count';

export const Client = z.object({
  id: z.string(),
  displayName: z.string(),
  phones: z.array(z.string()),
  addressLabel: z.string().nullable(),
  addressCity: z.string().nullable(),
  addressPostcode: z.string().nullable(),
  latitude: z.number().nullable(),
  longitude: z.number().nullable(),
  isWaiting: z.boolean(),
  isBanned: z.boolean(),
  needsDistanceRecompute: z.boolean(),
  lastShearingDate: z.string().nullable(),
  animalCounts: AnimalCountList,
  markerColorHex: z.string().nullable(),
  anonymizedAt: z.string().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export type Client = z.infer<typeof Client>;
```

- [ ] **Step 2 : Typecheck (ça va casser exprès)**

Run : `pnpm typecheck`
Expected : ÉCHEC. Tous les endroits qui construisent un `Client` (ex. `useUpsertClient` dans `src/state/queries/clients.ts`, les fixtures de tests) doivent être complétés.

- [ ] **Step 3 : Compléter les callsites**

Pour chaque erreur typecheck signalée :
- Si c'est un `Client` neuf construit dans le code (ex. `useUpsertClient`) → ajouter `anonymizedAt: null` (un client tout neuf n'est jamais anonymisé).
- Si c'est dans une fixture de test → idem, `anonymizedAt: null`.

Liste minimale attendue (à confirmer par le typecheck) :
- `src/state/queries/clients.ts` ligne ~89 dans `useUpsertClient` → ajouter `anonymizedAt: existing?.anonymizedAt ?? null`.
- Fixtures dans `tests/data/client-repository.test.ts` et autres — chercher avec `grep -n "isBanned: false" tests/`.

- [ ] **Step 4 : Re-typecheck**

Run : `pnpm typecheck`
Expected : OK.

- [ ] **Step 5 : Commit**

```bash
git add src/domain/models/client.ts src/state/queries/clients.ts tests/
git commit -m "feat(rgpd): add anonymizedAt to Client domain model"
```

---

## Task 2 — Ajouter la colonne DB + générer la migration

**Files:**
- Modify: `src/infra/db/schema.ts`
- Create: `src/infra/db/migrations/0005_<auto-named>.sql`
- Modify: `src/infra/db/migrations/migrations.js`, `meta/_journal.json`

- [ ] **Step 1 : Ajouter la colonne dans le schema Drizzle**

Dans `src/infra/db/schema.ts`, dans la définition de `clients`, ajouter le champ avant `createdAt` :

```ts
anonymizedAt: text('anonymized_at'),
```

(Index optionnel : on peut ajouter `anonymizedIdx: index('clients_anonymized_idx').on(t.anonymizedAt)` si on prévoit beaucoup de filtrages — pour le MVP c'est facultatif, on s'en passe.)

- [ ] **Step 2 : Compléter `toRow` et `ClientRow` dans le repository**

Dans `src/data/repositories/client-repository.ts` :

`toRow` (autour de ligne 6-25) → ajouter :
```ts
anonymizedAt: c.anonymizedAt,
```

`interface ClientRow` (autour de ligne 27-44) → ajouter :
```ts
anonymizedAt: string | null;
```

`fromRow` (autour de ligne 46-55) — le spread `...r` couvre déjà le champ, rien à faire si on s'appuie sur lui.

- [ ] **Step 3 : Générer la migration**

Run : `pnpm db:generate`
Expected : nouveau fichier `src/infra/db/migrations/0005_<some-name>.sql` contenant `ALTER TABLE clients ADD anonymized_at text;` (ou équivalent).

Run : `pnpm db:bundle`
Expected : `migrations.js` régénéré avec la nouvelle entrée.

- [ ] **Step 4 : Vérifier la migration manuellement**

Read `src/infra/db/migrations/0005_*.sql` et confirmer qu'il s'agit bien d'un `ALTER TABLE` non destructif.

- [ ] **Step 5 : Typecheck**

Run : `pnpm typecheck`
Expected : OK.

- [ ] **Step 6 : Commit**

```bash
git add src/infra/db/schema.ts src/infra/db/migrations/ src/data/repositories/client-repository.ts
git commit -m "feat(rgpd): add anonymized_at column to clients table"
```

---

## Task 3 — Bump backup schema v3 → v4

**Files:**
- Modify: `src/infra/cloud/backup-schema.ts`
- Modify: `src/infra/cloud/backups.ts`

- [ ] **Step 1 : Ajouter le champ à `ClientRow` (le partagé)**

Dans `src/infra/cloud/backup-schema.ts`, dans la définition `ClientRow` (autour de ligne 11-28), ajouter :

```ts
anonymizedAt: optStr,
```

- [ ] **Step 2 : Renommer le schema v3 et créer v4**

Toujours dans `backup-schema.ts` :

1. Renommer `BackupSnapshotSchema` (ligne 117) en `BackupSnapshotV3Schema` (et `ValidatedBackupSnapshot` en `ValidatedBackupSnapshotV3`).

   ⚠️ Attention : `BackupSnapshotSchema` est exporté et importé par `backups.ts`. Garder l'ancien nom comme **alias** pointant vers v4 pour ne pas casser les autres imports :
   ```ts
   export const BackupSnapshotSchema = BackupSnapshotV4Schema;
   export type ValidatedBackupSnapshot = ValidatedBackupSnapshotV4;
   ```

2. Définir le nouveau schema v4 (la `ClientRow` a déjà la nouvelle colonne via l'étape 1, le reste est identique) :

```ts
const ClientRowV3 = z.object({
  id: z.string(),
  displayName: z.string(),
  phones: z.string(),
  addressLabel: optStr,
  addressCity: optStr,
  addressPostcode: optStr,
  latitude: optReal,
  longitude: optReal,
  isWaiting: z.number().int(),
  isBanned: z.number().int(),
  needsDistanceRecompute: z.number().int(),
  lastShearingDate: optStr,
  animalCounts: z.string(),
  markerColorHex: optStr,
  createdAt: z.string(),
  updatedAt: z.string(),
});

export const BackupSnapshotV3Schema = z.object({
  schemaVersion: z.literal(3),
  createdAt: z.string(),
  tables: z.object({
    clients: z.array(ClientRowV3),
    species: z.array(SpeciesRow),
    animal_categories: z.array(AnimalCategoryRow),
    services: z.array(ServiceRow),
    tours: z.array(TourRow),
    tour_stops: z.array(TourStopRow),
    manual_history_entries: z.array(ManualHistoryEntryRow),
    distance_matrix: z.array(DistanceMatrixRow),
    settings: z.array(SettingsRow),
  }),
});
export type ValidatedBackupSnapshotV3 = z.infer<typeof BackupSnapshotV3Schema>;

export const BackupSnapshotV4Schema = z.object({
  schemaVersion: z.literal(4),
  createdAt: z.string(),
  tables: z.object({
    clients: z.array(ClientRow),  // déjà avec anonymizedAt
    species: z.array(SpeciesRow),
    animal_categories: z.array(AnimalCategoryRow),
    services: z.array(ServiceRow),
    tours: z.array(TourRow),
    tour_stops: z.array(TourStopRow),
    manual_history_entries: z.array(ManualHistoryEntryRow),
    distance_matrix: z.array(DistanceMatrixRow),
    settings: z.array(SettingsRow),
  }),
});
export type ValidatedBackupSnapshotV4 = z.infer<typeof BackupSnapshotV4Schema>;
```

3. Helper de migration :

```ts
export function migrateV3ToV4(v3: ValidatedBackupSnapshotV3): ValidatedBackupSnapshotV4 {
  return {
    schemaVersion: 4,
    createdAt: v3.createdAt,
    tables: {
      ...v3.tables,
      clients: v3.tables.clients.map((c) => ({ ...c, anonymizedAt: null })),
    },
  };
}
```

- [ ] **Step 3 : Mettre à jour le `createBackup` pour produire v4**

Dans `src/infra/cloud/backups.ts` (autour de ligne 61-67), passer `schemaVersion: 4`.

- [ ] **Step 4 : Mettre à jour la chaîne de restore**

Dans `restoreBackup` (autour de ligne 108-130), ajouter v4 → v3 → v2 dans cet ordre (le plus récent en premier) :

```ts
import {
  BackupSnapshotV4Schema,
  BackupSnapshotV3Schema,
  BackupSnapshotV2Schema,
  migrateV2ToV3,
  migrateV3ToV4,
  type ValidatedBackupSnapshotV4,
} from './backup-schema';

// (...)

const v4 = BackupSnapshotV4Schema.safeParse(json);
if (v4.success) {
  await wipeAndRestore(v4.data.tables);
  return;
}
const v3 = BackupSnapshotV3Schema.safeParse(json);
if (v3.success) {
  await wipeAndRestore(migrateV3ToV4(v3.data).tables);
  return;
}
const v2 = BackupSnapshotV2Schema.safeParse(json);
if (v2.success) {
  const v3FromV2 = migrateV2ToV3(v2.data);
  await wipeAndRestore(migrateV3ToV4(v3FromV2).tables);
  return;
}
throw new Error(`Invalid backup format: ${v4.error.issues[0]?.message ?? 'unknown error'}`);
```

(Adapter `BackupSnapshot` typedef si besoin pour qu'il pointe sur v4.)

- [ ] **Step 5 : Typecheck**

Run : `pnpm typecheck`
Expected : OK.

- [ ] **Step 6 : Commit**

```bash
git add src/infra/cloud/backup-schema.ts src/infra/cloud/backups.ts
git commit -m "feat(rgpd): bump backup schema to v4 with anonymizedAt + migration chain"
```

---

## Task 4 — Use case `planAnonymization` (TDD)

**Files:**
- Create: `tests/domain/anonymize-client.test.ts`
- Create: `src/domain/use-cases/anonymize-client.ts`

- [ ] **Step 1 : Écrire les tests d'abord**

Créer `tests/domain/anonymize-client.test.ts` :

```ts
import { describe, it, expect } from 'vitest';
import { planAnonymization, ANONYMIZED_DISPLAY_NAME } from '@/domain/use-cases/anonymize-client';
import type { Client } from '@/domain/models/client';
import type { TourStop } from '@/domain/models/tour-stop';
import type { ManualHistoryEntry } from '@/domain/models/manual-history-entry';
import type { DistanceMatrixEntry } from '@/domain/models/distance-matrix-entry';

const NOW = '2026-05-06T10:00:00.000Z';

const baseClient: Client = {
  id: 'c1',
  displayName: 'Famille Le Goff',
  phones: ['0612345678'],
  addressLabel: '12 rue de la Mer',
  addressCity: 'Brest',
  addressPostcode: '29200',
  latitude: 48.39,
  longitude: -4.49,
  isWaiting: true,
  isBanned: false,
  needsDistanceRecompute: false,
  lastShearingDate: '2025-06-15',
  animalCounts: [{ categoryId: 'cat1', count: 5 }],
  markerColorHex: '#ff0000',
  anonymizedAt: null,
  createdAt: '2025-01-01T00:00:00.000Z',
  updatedAt: '2025-06-15T00:00:00.000Z',
};

describe('planAnonymization', () => {
  it('scrubs client identity, address, geoloc, animals; flips waiting/banned off; preserves lastShearingDate and markerColor', () => {
    const plan = planAnonymization(baseClient, [], [], [], NOW);
    expect(plan.client.updates.displayName).toBe(ANONYMIZED_DISPLAY_NAME);
    expect(plan.client.updates.phones).toEqual([]);
    expect(plan.client.updates.addressLabel).toBeNull();
    expect(plan.client.updates.addressCity).toBeNull();
    expect(plan.client.updates.addressPostcode).toBeNull();
    expect(plan.client.updates.latitude).toBeNull();
    expect(plan.client.updates.longitude).toBeNull();
    expect(plan.client.updates.animalCounts).toEqual([]);
    expect(plan.client.updates.isWaiting).toBe(false);
    expect(plan.client.updates.isBanned).toBe(false);
    expect(plan.client.updates.anonymizedAt).toBe(NOW);
    // preserved
    expect(plan.client.updates.lastShearingDate).toBeUndefined();
    expect(plan.client.updates.markerColorHex).toBeUndefined();
  });

  it('produces empty arrays when no related rows', () => {
    const plan = planAnonymization(baseClient, [], [], [], NOW);
    expect(plan.tourStopUpdates).toEqual([]);
    expect(plan.manualEntryUpdates).toEqual([]);
    expect(plan.distanceMatrixDeletes).toEqual([]);
  });

  it('scrubs clientNameSnapshot and notes on tour stops, preserves money fields', () => {
    const stop = {
      id: 's1',
      tourId: 't1',
      clientId: 'c1',
      clientNameSnapshot: 'Famille Le Goff',
      ordering: 0,
      arrivalMinutes: null,
      departureMinutes: null,
      estimatedMinutes: 30,
      travelFeeCents: 800,
      plannedServices: [],
      actualServices: null,
      notes: 'porte rouge, sonner deux fois',
      completedAt: null,
      payment: { isPaid: false, paidAt: null, paymentMethodId: null, paymentMethodLabelSnapshot: null },
    } as unknown as TourStop;
    const plan = planAnonymization(baseClient, [stop], [], [], NOW);
    expect(plan.tourStopUpdates).toEqual([
      { id: 's1', clientNameSnapshot: ANONYMIZED_DISPLAY_NAME, notes: null },
    ]);
  });

  it('scrubs notes on manual history entries', () => {
    const entry = {
      id: 'm1', clientId: 'c1', date: '2025-06-15', notes: 'venir tôt',
      services: [], travelFeeCents: null,
      payment: { isPaid: false, paidAt: null, paymentMethodId: null, paymentMethodLabelSnapshot: null },
    } as unknown as ManualHistoryEntry;
    const plan = planAnonymization(baseClient, [], [entry], [], NOW);
    expect(plan.manualEntryUpdates).toEqual([{ id: 'm1', notes: null }]);
  });

  it('deletes distance_matrix rows touching the client (either side)', () => {
    const dm: DistanceMatrixEntry[] = [
      { fromId: 'c1', toId: 'base', distanceKm: 5, durationMinutes: 10, fetchedAt: NOW, failed: false },
      { fromId: 'base', toId: 'c1', distanceKm: 5, durationMinutes: 10, fetchedAt: NOW, failed: false },
      { fromId: 'c2', toId: 'c3', distanceKm: 7, durationMinutes: 12, fetchedAt: NOW, failed: false },
    ];
    const plan = planAnonymization(baseClient, [], [], dm, NOW);
    expect(plan.distanceMatrixDeletes).toEqual([
      { fromId: 'c1', toId: 'base' },
      { fromId: 'base', toId: 'c1' },
    ]);
  });

  it('idempotent: returns no-op plan for already-anonymized client', () => {
    const already: Client = { ...baseClient, anonymizedAt: '2026-01-01T00:00:00.000Z' };
    const plan = planAnonymization(already, [], [], [], NOW);
    expect(plan.client.updates).toEqual({});
    expect(plan.tourStopUpdates).toEqual([]);
    expect(plan.manualEntryUpdates).toEqual([]);
    expect(plan.distanceMatrixDeletes).toEqual([]);
  });

  it('only scrubs notes on stops belonging to the client', () => {
    const otherStop = {
      id: 's2', tourId: 't1', clientId: 'OTHER',
      clientNameSnapshot: 'Other', notes: 'keep me',
    } as unknown as TourStop;
    const ourStop = {
      id: 's1', tourId: 't1', clientId: 'c1',
      clientNameSnapshot: 'Famille', notes: 'scrub me',
    } as unknown as TourStop;
    const plan = planAnonymization(baseClient, [otherStop, ourStop], [], [], NOW);
    expect(plan.tourStopUpdates).toEqual([
      { id: 's1', clientNameSnapshot: ANONYMIZED_DISPLAY_NAME, notes: null },
    ]);
  });

  it('returns no-op plan elements when stops/entries/dm are empty arrays', () => {
    const plan = planAnonymization(baseClient, [], [], [], NOW);
    expect(plan.tourStopUpdates.length).toBe(0);
    expect(plan.manualEntryUpdates.length).toBe(0);
    expect(plan.distanceMatrixDeletes.length).toBe(0);
  });
});
```

- [ ] **Step 2 : Lancer les tests, vérifier l'échec**

Run : `pnpm test:domain anonymize-client`
Expected : ÉCHEC, module not found.

- [ ] **Step 3 : Implémenter le use case**

Créer `src/domain/use-cases/anonymize-client.ts`. Le use case prend des **input types minimaux** (juste les champs qu'il lit) plutôt que les modèles complets — ça évite aux callers (tests, repo) de fabriquer des objets `TourStop` complets juste pour appeler la fonction.

```ts
import type { Client } from '@/domain/models/client';

export const ANONYMIZED_DISPLAY_NAME = 'Client supprimé';

export interface AnonymizableStop {
  id: string;
  clientId: string;
}

export interface AnonymizableEntry {
  id: string;
  clientId: string;
}

export interface AnonymizableDmEntry {
  fromId: string;
  toId: string;
}

export interface AnonymizationPlan {
  client: { id: string; updates: Partial<Client> };
  tourStopUpdates: Array<{ id: string; clientNameSnapshot: string; notes: null }>;
  manualEntryUpdates: Array<{ id: string; notes: null }>;
  distanceMatrixDeletes: Array<{ fromId: string; toId: string }>;
}

export function planAnonymization(
  client: Client,
  tourStops: AnonymizableStop[],
  manualEntries: AnonymizableEntry[],
  distanceMatrix: AnonymizableDmEntry[],
  now: string,
): AnonymizationPlan {
  if (client.anonymizedAt != null) {
    return {
      client: { id: client.id, updates: {} },
      tourStopUpdates: [],
      manualEntryUpdates: [],
      distanceMatrixDeletes: [],
    };
  }

  return {
    client: {
      id: client.id,
      updates: {
        displayName: ANONYMIZED_DISPLAY_NAME,
        phones: [],
        addressLabel: null,
        addressCity: null,
        addressPostcode: null,
        latitude: null,
        longitude: null,
        animalCounts: [],
        isWaiting: false,
        isBanned: false,
        needsDistanceRecompute: false,
        anonymizedAt: now,
      },
    },
    tourStopUpdates: tourStops
      .filter((s) => s.clientId === client.id)
      .map((s) => ({ id: s.id, clientNameSnapshot: ANONYMIZED_DISPLAY_NAME, notes: null })),
    manualEntryUpdates: manualEntries
      .filter((e) => e.clientId === client.id)
      .map((e) => ({ id: e.id, notes: null })),
    distanceMatrixDeletes: distanceMatrix
      .filter((d) => d.fromId === client.id || d.toId === client.id)
      .map((d) => ({ fromId: d.fromId, toId: d.toId })),
  };
}
```

Note : avec ces inputs minimaux, les tests Step 1 doivent être ajustés. Remplacer chaque `as unknown as TourStop` / `as unknown as ManualHistoryEntry` par un objet simple :

```ts
// Remplacer dans le test « scrubs clientNameSnapshot... » :
const stop = { id: 's1', clientId: 'c1' };
const plan = planAnonymization(baseClient, [stop], [], [], NOW);

// Remplacer dans le test « scrubs notes on manual history entries » :
const entry = { id: 'm1', clientId: 'c1' };

// Remplacer dans « only scrubs notes on stops belonging to the client » :
const otherStop = { id: 's2', clientId: 'OTHER' };
const ourStop = { id: 's1', clientId: 'c1' };
```

Les imports `TourStop` / `ManualHistoryEntry` / `DistanceMatrixEntry` deviennent inutiles dans le test — les retirer.

- [ ] **Step 4 : Lancer les tests, vérifier le succès**

Run : `pnpm test:domain anonymize-client`
Expected : 8 tests verts.

- [ ] **Step 5 : Commit**

```bash
git add src/domain/use-cases/anonymize-client.ts tests/domain/anonymize-client.test.ts
git commit -m "feat(rgpd): add planAnonymization domain use case"
```

---

## Task 5 — `ClientRepository.anonymize` (TDD)

**Files:**
- Modify: `src/data/repositories/client-repository.ts`
- Create: `tests/data/client-repository-anonymize.test.ts`

- [ ] **Step 1 : Écrire le test d'abord**

Créer `tests/data/client-repository-anonymize.test.ts`. Suivre le pattern existant de `tests/data/client-repository.test.ts` (lire ce fichier en premier pour récupérer le boilerplate de setup DB in-memory).

```ts
import { describe, it, expect, beforeEach } from '@jest/globals';
import { drizzle } from 'drizzle-orm/better-sqlite3';
import Database from 'better-sqlite3';
import { migrate } from 'drizzle-orm/better-sqlite3/migrator';
import path from 'path';
import { eq } from 'drizzle-orm';
import * as schema from '@/infra/db/schema';
import { ClientRepository } from '@/data/repositories/client-repository';
import { ANONYMIZED_DISPLAY_NAME } from '@/domain/use-cases/anonymize-client';

function makeDb() {
  const sqlite = new Database(':memory:');
  const db = drizzle(sqlite, { schema });
  migrate(db, { migrationsFolder: path.resolve(__dirname, '../../src/infra/db/migrations') });
  return db;
}

describe('ClientRepository.anonymize', () => {
  let db: ReturnType<typeof makeDb>;
  let repo: ClientRepository;
  const NOW = '2026-05-06T10:00:00.000Z';

  beforeEach(() => {
    db = makeDb();
    repo = new ClientRepository(db);
  });

  it('scrubs identity columns and stamps anonymizedAt', async () => {
    await repo.upsert({
      id: 'c1',
      displayName: 'Famille Le Goff',
      phones: ['0612345678'],
      addressLabel: '12 rue', addressCity: 'Brest', addressPostcode: '29200',
      latitude: 48.39, longitude: -4.49,
      isWaiting: true, isBanned: false, needsDistanceRecompute: false,
      lastShearingDate: '2025-06-15',
      animalCounts: [{ categoryId: 'cat1', count: 5 }],
      markerColorHex: '#ff0000', anonymizedAt: null,
      createdAt: '2025-01-01T00:00:00.000Z', updatedAt: '2025-01-01T00:00:00.000Z',
    });
    await repo.anonymize('c1', NOW);
    const after = await repo.byId('c1');
    expect(after?.displayName).toBe(ANONYMIZED_DISPLAY_NAME);
    expect(after?.phones).toEqual([]);
    expect(after?.addressLabel).toBeNull();
    expect(after?.latitude).toBeNull();
    expect(after?.animalCounts).toEqual([]);
    expect(after?.isWaiting).toBe(false);
    expect(after?.anonymizedAt).toBe(NOW);
    // preserved
    expect(after?.lastShearingDate).toBe('2025-06-15');
    expect(after?.markerColorHex).toBe('#ff0000');
  });

  it('scrubs clientNameSnapshot and notes on tour_stops belonging to the client, preserves financial fields', async () => {
    await repo.upsert({
      id: 'c1', displayName: 'Famille', phones: [],
      addressLabel: null, addressCity: null, addressPostcode: null,
      latitude: null, longitude: null,
      isWaiting: false, isBanned: false, needsDistanceRecompute: false,
      lastShearingDate: null, animalCounts: [], markerColorHex: null,
      anonymizedAt: null,
      createdAt: NOW, updatedAt: NOW,
    });
    // Insère une tour + un stop directement via la DB pour le test.
    await db.insert(schema.tours).values({
      id: 't1', scheduledDate: '2025-06-15', departureTime: '08:00',
      baseLat: 48.0, baseLng: 2.0, status: 'completed',
      createdAt: NOW, updatedAt: NOW,
    });
    await db.insert(schema.tourStops).values({
      id: 's1', tourId: 't1', clientId: 'c1', clientNameSnapshot: 'Famille',
      ordering: 0, travelFeeCents: 800,
      plannedServices: '[]', actualServices: '[]',
      notes: 'porte rouge', completedAt: NOW, isPaid: 1, paidAt: NOW,
    });

    await repo.anonymize('c1', NOW);
    const stop = (await db.select().from(schema.tourStops).where(eq(schema.tourStops.id, 's1')))[0];
    expect(stop.clientNameSnapshot).toBe(ANONYMIZED_DISPLAY_NAME);
    expect(stop.notes).toBeNull();
    expect(stop.travelFeeCents).toBe(800);  // preserved
    expect(stop.isPaid).toBe(1);             // preserved
  });

  it('hides anonymized clients from listAll and listWaiting', async () => {
    await repo.upsert({
      id: 'c1', displayName: 'A', phones: [], addressLabel: null, addressCity: null, addressPostcode: null,
      latitude: null, longitude: null, isWaiting: true, isBanned: false, needsDistanceRecompute: false,
      lastShearingDate: null, animalCounts: [], markerColorHex: null, anonymizedAt: null,
      createdAt: NOW, updatedAt: NOW,
    });
    await repo.upsert({
      id: 'c2', displayName: 'B', phones: [], addressLabel: null, addressCity: null, addressPostcode: null,
      latitude: null, longitude: null, isWaiting: true, isBanned: false, needsDistanceRecompute: false,
      lastShearingDate: null, animalCounts: [], markerColorHex: null, anonymizedAt: null,
      createdAt: NOW, updatedAt: NOW,
    });
    await repo.anonymize('c1', NOW);
    const all = await repo.listAll();
    expect(all.map((c) => c.id)).toEqual(['c2']);
    const waiting = await repo.listWaiting();
    expect(waiting.map((c) => c.id)).toEqual(['c2']);
  });

  it('byId still returns an anonymized client (used by detail screen for redirect)', async () => {
    await repo.upsert({
      id: 'c1', displayName: 'A', phones: [], addressLabel: null, addressCity: null, addressPostcode: null,
      latitude: null, longitude: null, isWaiting: false, isBanned: false, needsDistanceRecompute: false,
      lastShearingDate: null, animalCounts: [], markerColorHex: null, anonymizedAt: null,
      createdAt: NOW, updatedAt: NOW,
    });
    await repo.anonymize('c1', NOW);
    const after = await repo.byId('c1');
    expect(after).not.toBeNull();
    expect(after?.anonymizedAt).toBe(NOW);
  });
});
```

- [ ] **Step 2 : Lancer le test, vérifier l'échec**

Run : `pnpm test:integration client-repository-anonymize`
Expected : ÉCHEC, `repo.anonymize` n'existe pas (ou les filtres ne sont pas appliqués).

- [ ] **Step 3 : Implémenter `anonymize` + filtres**

Dans `src/data/repositories/client-repository.ts`, ajouter en imports :

```ts
import { isNull } from 'drizzle-orm';
import { distanceMatrix } from '@/infra/db/schema';
import { planAnonymization } from '@/domain/use-cases/anonymize-client';
```

Modifier `listAll` et `listWaiting` pour filtrer les clients anonymisés :

```ts
async listAll(): Promise<Client[]> {
  const rows = await this.db.select().from(clients).where(isNull(clients.anonymizedAt));
  return rows.map((r) => fromRow(r as ClientRow));
}

async listWaiting(): Promise<Client[]> {
  const rows = await this.db
    .select()
    .from(clients)
    .where(and(eq(clients.isWaiting, 1), isNull(clients.anonymizedAt)));
  return rows.map((r) => fromRow(r as ClientRow));
}
```

(Garder `byId` sans filtre — l'écran fiche client a besoin de pouvoir lire un client anonymisé pour ensuite rediriger.)

Ajouter la nouvelle méthode `anonymize` :

```ts
async anonymize(id: string, now: string): Promise<void> {
  // Charger la cible + les rows liées, planifier, puis exécuter en transaction.
  const clientRow = await this.db.select().from(clients).where(eq(clients.id, id));
  if (!clientRow[0]) return;
  const client = fromRow(clientRow[0] as ClientRow);

  const stopRows = await this.db.select().from(tourStops).where(eq(tourStops.clientId, id));
  const entryRows = await this.db.select().from(manualHistoryEntries).where(eq(manualHistoryEntries.clientId, id));
  const dmRows = await this.db.select().from(distanceMatrix);

  const stops = stopRows.map((r) => ({ id: r.id, clientId: r.clientId }));
  const entries = entryRows.map((r) => ({ id: r.id, clientId: r.clientId }));
  const dm = dmRows.map((r) => ({ fromId: r.fromId, toId: r.toId }));

  const plan = planAnonymization(client, stops, entries, dm, now);

  await this.db.transaction(async (tx) => {
    if (Object.keys(plan.client.updates).length > 0) {
      const updates: Record<string, unknown> = {};
      const u = plan.client.updates;
      if (u.displayName !== undefined) updates.displayName = u.displayName;
      if (u.phones !== undefined) updates.phones = JSON.stringify(u.phones);
      if (u.addressLabel !== undefined) updates.addressLabel = u.addressLabel;
      if (u.addressCity !== undefined) updates.addressCity = u.addressCity;
      if (u.addressPostcode !== undefined) updates.addressPostcode = u.addressPostcode;
      if (u.latitude !== undefined) updates.latitude = u.latitude;
      if (u.longitude !== undefined) updates.longitude = u.longitude;
      if (u.animalCounts !== undefined) updates.animalCounts = JSON.stringify(u.animalCounts);
      if (u.isWaiting !== undefined) updates.isWaiting = u.isWaiting ? 1 : 0;
      if (u.isBanned !== undefined) updates.isBanned = u.isBanned ? 1 : 0;
      if (u.needsDistanceRecompute !== undefined) updates.needsDistanceRecompute = u.needsDistanceRecompute ? 1 : 0;
      if (u.anonymizedAt !== undefined) updates.anonymizedAt = u.anonymizedAt;
      updates.updatedAt = now;
      await tx.update(clients).set(updates).where(eq(clients.id, id));
    }

    for (const upd of plan.tourStopUpdates) {
      await tx.update(tourStops)
        .set({ clientNameSnapshot: upd.clientNameSnapshot, notes: upd.notes })
        .where(eq(tourStops.id, upd.id));
    }
    for (const upd of plan.manualEntryUpdates) {
      await tx.update(manualHistoryEntries)
        .set({ notes: upd.notes })
        .where(eq(manualHistoryEntries.id, upd.id));
    }
    for (const del of plan.distanceMatrixDeletes) {
      await tx.delete(distanceMatrix)
        .where(and(eq(distanceMatrix.fromId, del.fromId), eq(distanceMatrix.toId, del.toId)));
    }
  });
}
```

- [ ] **Step 4 : Lancer le test, vérifier le succès**

Run : `pnpm test:integration client-repository-anonymize`
Expected : 4 tests verts.

- [ ] **Step 5 : S'assurer que les autres tests data ne régressent pas**

Run : `pnpm test:integration`
Expected : tout vert. Si certains tests s'appuient sur `listAll` retournant un client anonymisé (peu probable, mais possible), ajuster les fixtures.

- [ ] **Step 6 : Commit**

```bash
git add src/data/repositories/client-repository.ts tests/data/client-repository-anonymize.test.ts
git commit -m "feat(rgpd): add ClientRepository.anonymize and filter anonymized from lists"
```

---

## Task 6 — Renommer `useDeleteClient` → `useAnonymizeClient`

**Files:**
- Modify: `src/state/queries/clients.ts`
- Modify: `app/(tabs)/clients/[id].tsx`

- [ ] **Step 1 : Renommer la mutation et changer la fn**

Dans `src/state/queries/clients.ts`, remplacer `useDeleteClient` :

```ts
export function useAnonymizeClient() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      const now = new Date().toISOString();
      await repo.anonymize(id, now);
    },
    onSuccess: (_, id) => {
      void qc.invalidateQueries({ queryKey: clientsKeys.all });
      void qc.invalidateQueries({ queryKey: ['kpis'] });
      void qc.invalidateQueries({ queryKey: ['clients', 'statusMap'] });
      void qc.invalidateQueries({ queryKey: ['clients', 'outstanding'] });
      qc.removeQueries({ queryKey: clientsKeys.byId(id) });
    },
  });
}
```

- [ ] **Step 2 : Mettre à jour le callsite dans `[id].tsx`**

Dans `app/(tabs)/clients/[id].tsx` :
- Remplacer l'import `useDeleteClient` par `useAnonymizeClient`.
- Remplacer `const deleteMutation = useDeleteClient()` par `const anonymizeMutation = useAnonymizeClient()`.
- Renommer `deleteMutation.mutate` → `anonymizeMutation.mutate` dans `onDelete` (le nom du handler peut rester `onDelete` côté UI puisque l'utilisateur voit « Supprimer »).

- [ ] **Step 3 : Typecheck**

Run : `pnpm typecheck`
Expected : OK.

- [ ] **Step 4 : Commit**

```bash
git add src/state/queries/clients.ts app/(tabs)/clients/[id].tsx
git commit -m "refactor(rgpd): rename useDeleteClient → useAnonymizeClient"
```

---

## Task 7 — Dialog typé + redirect anonymisé

**Files:**
- Modify: `app/(tabs)/clients/[id].tsx`

- [ ] **Step 1 : Ajouter l'import du dialog typé**

Dans `app/(tabs)/clients/[id].tsx`, ajouter :

```tsx
import { ConfirmTypedDialog } from '@/ui/components/confirm-dialog';
```

(Vérifier le chemin réel : `confirm` est déjà importé depuis `@/ui/components/confirm-dialog`, donc `ConfirmTypedDialog` est dans le même module, comme dans `cloud.tsx`.)

- [ ] **Step 2 : Ajouter le state du dialog**

Au début de `ClientDetailScreen`, après les autres `useState` :

```tsx
const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
```

- [ ] **Step 3 : Ajouter la redirection si client anonymisé**

Juste avant le `if (!client) return ...` (autour de ligne 95) :

```tsx
if (client?.anonymizedAt) {
  // Le client a été anonymisé — on quitte avec un toast.
  setTimeout(() => {
    router.back();
  }, 0);
  return <Surface className="flex-1" />;
}
```

(Le `setTimeout(0)` évite le warning React « cannot update during render ». Si le pattern existe ailleurs avec `useEffect`, le préférer pour la propreté — mais ce timer suffit pour le MVP.)

- [ ] **Step 4 : Remplacer le confirm() par le dialog typé**

Remplacer le bloc `onDelete` actuel (autour de ligne 99-118) par :

```tsx
const onDelete = () => {
  setMenuOpen(false);
  setDeleteDialogOpen(true);
};

const handleDeleteConfirmed = () => {
  setDeleteDialogOpen(false);
  anonymizeMutation.mutate(client.id, {
    onSuccess: () => {
      void haptics.success();
      router.back();
    },
    onError: (err) => {
      mutationErrorToast(t('clients.delete_failed_title'), err);
    },
  });
};
```

Et insérer le dialog dans le JSX retourné (juste avant le `</Surface>` racine) :

```tsx
<ConfirmTypedDialog
  visible={deleteDialogOpen}
  title={t('clients.delete_confirm_title')}
  message={t('clients.delete_confirm_message')}
  typedConfirmation={t('clients.delete_typed_word')}
  confirmLabel={t('clients.delete_cta_confirm')}
  cancelLabel={t('common.cancel')}
  onConfirm={handleDeleteConfirmed}
  onCancel={() => setDeleteDialogOpen(false)}
/>
```

- [ ] **Step 5 : Typecheck + lint**

Run : `pnpm typecheck && pnpm lint`
Expected : OK.

- [ ] **Step 6 : Commit**

```bash
git add app/(tabs)/clients/[id].tsx
git commit -m "feat(rgpd): use typed confirm dialog + redirect anonymized clients"
```

---

## Task 8 — Mettre à jour les clés i18n

**Files:**
- Modify: `src/i18n/locales/fr.json`

Le message actuel (« L'historique de tournées du client sera également perdu ») est faux pour l'anonymisation. On le réécrit + on ajoute deux nouvelles clés pour le dialog typé.

- [ ] **Step 1 : Modifier les clés `clients.*`**

Dans `src/i18n/locales/fr.json`, remplacer la valeur de `clients.delete_confirm_message` :

```json
"delete_confirm_message": "Cette action est irréversible. Le nom, les coordonnées, l'adresse et les notes seront effacés immédiatement. L'historique financier (montants, dates, prestations) est conservé conformément à vos obligations comptables.",
```

Ajouter ces deux clés dans le même bloc `clients.*` (à côté de `delete`, `delete_confirm_title`, etc.) :

```json
"delete_typed_word": "SUPPRIMER",
"delete_cta_confirm": "Supprimer définitivement",
```

- [ ] **Step 2 : Vérifier le JSON**

Run : `node -e "JSON.parse(require('fs').readFileSync('src/i18n/locales/fr.json','utf-8'))"`
Expected : aucune sortie (parse OK).

- [ ] **Step 3 : Commit**

```bash
git add src/i18n/locales/fr.json
git commit -m "feat(rgpd): update client deletion i18n for anonymization wording"
```

---

## Task 9 — Smoke test parcours complet

- [ ] **Step 1 : Tests automatisés**

Run : `pnpm test`
Expected : tous verts (vitest + jest).

- [ ] **Step 2 : Typecheck + lint**

Run : `pnpm typecheck && pnpm lint`
Expected : OK.

- [ ] **Step 3 : Test manuel — anonymisation simple**

Sur device :
1. Créer un client de test « Famille Test » avec adresse + 1 phone + animaux + note dans une intervention manuelle.
2. Ouvrir sa fiche → menu kebab → « Supprimer ».
3. Dialog typé apparaît. Taper `SUPPRIMER` → bouton actif.
4. Confirmer → retour automatique à la liste, le client n'apparaît plus.
5. Vérifier dans Réglages → Cloud → « Télécharger mes données » (ou directement en SQL si tu as un outil) que le client est toujours en DB avec `displayName = "Client supprimé"`, `anonymizedAt` rempli, autres champs scrub.

- [ ] **Step 4 : Test manuel — anonymisation avec historique**

1. Sur un client existant qui a déjà des tour_stops complétés (CA encaissé), même flow.
2. Vérifier que :
   - Le client n'apparaît plus dans la liste / map / pickers.
   - L'historique de la tournée concernée (`/(tabs)/tours/[id]`) affiche toujours le stop, mais avec « Client supprimé » au lieu du vrai nom.
   - Les KPI globaux (CA total app) sont inchangés (la compta est préservée).

- [ ] **Step 5 : Test manuel — accès direct par URL**

1. Anonymiser un client.
2. Naviguer manuellement vers `/(tabs)/clients/<son-id>` (via deep-link ou menu kebab d'une vieille tournée si possible).
3. Vérifier le redirect : on retombe sur la liste, sans crash.

- [ ] **Step 6 : Test manuel — backup roundtrip**

1. Avec un compte cloud connecté : créer un client, l'anonymiser, faire un backup manuel.
2. Wipe local (sign-out), re-login, restore le backup.
3. Vérifier : le client reste anonymisé après restore (il n'apparaît pas dans la liste, son `anonymizedAt` est conservé).

---

## Open questions (pour mémoire — pas bloquantes pour ce plan)

- **`map_filters_store` / `client_filters_store` / pickers** : si certains pickers ou filtres font des requêtes directes via Drizzle (court-circuitant `ClientRepository.listAll`), ils ne bénéficieront pas du filtre `anonymizedAt IS NULL`. Vérifier au passage et ajouter le filtre si besoin (ce sera signalé par les tests UI / par l'apparition d'un client anonymisé là où il ne devrait pas).
- **Bug latent FK `tour_stops.clientId notNull`** : ce plan **ne corrige pas** ce bug — il devient juste inatteignable via l'UI puisque la suppression dure n'est plus exposée. La vraie suppression (DELETE) reste utilisable par `wipeLocalDatabase` qui supprime dans le bon ordre (children avant parents).
