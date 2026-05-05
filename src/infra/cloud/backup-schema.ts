import { z } from 'zod';

// Permissive zod schemas mirroring the SQLite column types in `src/infra/db/schema.ts`.
// SQLite stores booleans as 0/1 ints — we keep them as `number` here.
// Optional columns accept null OR undefined (Drizzle returns null, but JSON
// roundtrips can drop the key entirely).
const optStr = z.string().nullable().optional();
const optInt = z.number().int().nullable().optional();
const optReal = z.number().nullable().optional();

const ClientRow = z.object({
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

const SpeciesRow = z.object({
  id: z.string(),
  label: z.string(),
  iconKey: optStr,
  ordering: z.number().int(),
  isCustom: z.number().int(),
  archivedAt: optStr,
});

const AnimalCategoryRow = z.object({
  id: z.string(),
  speciesId: z.string(),
  label: z.string(),
  ordering: z.number().int(),
  isCustom: z.number().int(),
  archivedAt: optStr,
});

const ServiceRow = z.object({
  id: z.string(),
  label: z.string(),
  priceCents: optInt,
  minutes: z.number().int(),
  categoryId: optStr,
  isActive: z.number().int(),
  archivedAt: optStr,
  ordering: z.number().int(),
});

const TourRow = z.object({
  id: z.string(),
  scheduledDate: z.string(),
  departureTime: z.string(),
  baseLat: z.number(),
  baseLng: z.number(),
  status: z.string(),
  totalDistanceKm: optReal,
  totalDriveSeconds: optInt,
  totalMinutes: optInt,
  totalRevenueCents: optInt,
  totalAnimalsCount: optInt,
  totalTravelFeeCents: optInt,
  routeGeometry: optStr,
  notes: optStr,
  completedAt: optStr,
  createdAt: z.string(),
  updatedAt: z.string(),
});

const TourStopRow = z.object({
  id: z.string(),
  tourId: z.string(),
  clientId: z.string(),
  clientNameSnapshot: optStr,
  ordering: z.number().int(),
  arrivalMinutes: optInt,
  departureMinutes: optInt,
  estimatedMinutes: optInt,
  feeShareCents: optInt,
  plannedServices: z.string(),
  actualServices: optStr,
  notes: optStr,
  completedAt: optStr,
});

const ManualHistoryEntryRow = z.object({
  id: z.string(),
  clientId: z.string(),
  date: z.string(),
  notes: optStr,
  services: z.string(),
});

const DistanceMatrixRow = z.object({
  fromId: z.string(),
  toId: z.string(),
  distanceKm: z.number(),
  durationMinutes: z.number().int(),
  fetchedAt: z.string(),
  failed: z.number().int(),
});

const SettingsRow = z.object({
  key: z.string(),
  value: z.string(),
});

export const BackupSnapshotSchema = z.object({
  schemaVersion: z.literal(2),
  createdAt: z.string(),
  tables: z.object({
    clients: z.array(ClientRow),
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

export type ValidatedBackupSnapshot = z.infer<typeof BackupSnapshotSchema>;
