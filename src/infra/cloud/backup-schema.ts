import { z } from 'zod';

// Permissive zod schemas mirroring the SQLite column types in `src/infra/db/schema.ts`.
// SQLite stores booleans as 0/1 ints — we keep them as `number` here.
// Optional columns accept null OR undefined (Drizzle returns null, but JSON
// roundtrips can drop the key entirely).
const optStr = z.string().nullable().optional();
const optInt = z.number().int().nullable().optional();
const optReal = z.number().nullable().optional();

// v4 (current) client row — includes anonymizedAt.
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
  anonymizedAt: optStr,
  createdAt: z.string(),
  updatedAt: z.string(),
});

// v3 client row — no anonymizedAt, needed to parse old backups.
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
  scheduledDate: optStr,
  departureTime: optStr,
  title: optStr,
  baseLat: z.number(),
  baseLng: z.number(),
  status: z.string(),
  totalDistanceKm: optReal,
  totalDriveSeconds: optInt,
  totalMinutes: optInt,
  totalRevenueCents: optInt,
  totalAnimalsCount: optInt,
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
  travelFeeCents: optInt,
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
  travelFeeCents: optInt,
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

export type ValidatedBackupSnapshotV4 = z.infer<typeof BackupSnapshotV4Schema>;

// =============================================================
// v5 schema: adds statuses table, manualStatusId on clients.
// =============================================================

const StatusRow = z.object({
  id: z.string(),
  kind: z.string(),
  systemKey: optStr,
  label: z.string(),
  colorLight: z.string(),
  colorDark: z.string(),
  sortOrder: z.number().int(),
  createdAt: z.string(),
});

const ClientRowV5 = ClientRow.extend({
  manualStatusId: optStr,
});

export const BackupSnapshotV5Schema = z.object({
  schemaVersion: z.literal(5),
  createdAt: z.string(),
  tables: z.object({
    clients: z.array(ClientRowV5),
    species: z.array(SpeciesRow),
    animal_categories: z.array(AnimalCategoryRow),
    services: z.array(ServiceRow),
    tours: z.array(TourRow),
    tour_stops: z.array(TourStopRow),
    manual_history_entries: z.array(ManualHistoryEntryRow),
    distance_matrix: z.array(DistanceMatrixRow),
    settings: z.array(SettingsRow),
    statuses: z.array(StatusRow),
  }),
});

export type ValidatedBackupSnapshotV5 = z.infer<typeof BackupSnapshotV5Schema>;

const SYSTEM_STATUS_SEEDS_V5 = [
  { id: 'sys_default',   kind: 'system', systemKey: 'default',   label: 'Par défaut',        colorLight: '#94A3B8', colorDark: '#64748B', sortOrder: 10 },
  { id: 'sys_waiting',   kind: 'system', systemKey: 'waiting',   label: 'En attente de RDV', colorLight: '#C88226', colorDark: '#DC9E4E', sortOrder: 20 },
  { id: 'sys_scheduled', kind: 'system', systemKey: 'scheduled', label: 'Planifié',          colorLight: '#A1602F', colorDark: '#C68A58', sortOrder: 30 },
  { id: 'sys_done',      kind: 'system', systemKey: 'done',      label: 'Réalisé',           colorLight: '#5C7548', colorDark: '#98B282', sortOrder: 40 },
  { id: 'sys_noAnimals', kind: 'system', systemKey: 'noAnimals', label: 'Sans animaux',      colorLight: '#EAE0D3', colorDark: '#302820', sortOrder: 50 },
  { id: 'sys_banned',    kind: 'system', systemKey: 'banned',    label: 'Banni',             colorLight: '#B23832', colorDark: '#DC605A', sortOrder: 60 },
];

const LEGACY_COLOR_KEY_BY_SYSTEM_KEY: Record<string, string> = {
  default:   'marker_default_color',
  waiting:   'marker_waiting_color',
  scheduled: 'marker_scheduled_color',
  done:      'marker_done_color',
  noAnimals: 'marker_no_animals_color',
  banned:    'marker_banned_color',
};

export function migrateV4ToV5(v4: ValidatedBackupSnapshotV4): ValidatedBackupSnapshotV5 {
  const settingsByKey = new Map(v4.tables.settings.map((s) => [s.key, s.value]));
  const seededStatuses = SYSTEM_STATUS_SEEDS_V5.map((seed) => {
    const legacyKey = LEGACY_COLOR_KEY_BY_SYSTEM_KEY[seed.systemKey];
    const override = legacyKey ? settingsByKey.get(legacyKey) : undefined;
    return override
      ? { ...seed, colorLight: override, colorDark: override, createdAt: v4.createdAt }
      : { ...seed, createdAt: v4.createdAt };
  });
  const remainingSettings = v4.tables.settings.filter((s) => !Object.values(LEGACY_COLOR_KEY_BY_SYSTEM_KEY).includes(s.key));
  return {
    schemaVersion: 5,
    createdAt: v4.createdAt,
    tables: {
      ...v4.tables,
      clients: v4.tables.clients.map((c) => ({ ...c, manualStatusId: null })),
      settings: remainingSettings,
      statuses: seededStatuses,
    },
  };
}

// =============================================================
// v6 schema: adds tutorial_progress table.
// =============================================================

const TutorialProgressRow = z.object({
  key: z.string(),
  seenAt: z.string(),
});

export const BackupSnapshotV6Schema = z.object({
  schemaVersion: z.literal(6),
  createdAt: z.string(),
  tables: z.object({
    clients: z.array(ClientRowV5),
    species: z.array(SpeciesRow),
    animal_categories: z.array(AnimalCategoryRow),
    services: z.array(ServiceRow),
    tours: z.array(TourRow),
    tour_stops: z.array(TourStopRow),
    manual_history_entries: z.array(ManualHistoryEntryRow),
    distance_matrix: z.array(DistanceMatrixRow),
    settings: z.array(SettingsRow),
    statuses: z.array(StatusRow),
    tutorial_progress: z.array(TutorialProgressRow),
  }),
});

export type ValidatedBackupSnapshotV6 = z.infer<typeof BackupSnapshotV6Schema>;

export function migrateV5ToV6(v5: ValidatedBackupSnapshotV5): ValidatedBackupSnapshotV6 {
  return {
    schemaVersion: 6,
    createdAt: v5.createdAt,
    tables: {
      ...v5.tables,
      tutorial_progress: [],
    },
  };
}

// Backward-compatible aliases — other files importing these continue to work.
export const BackupSnapshotSchema = BackupSnapshotV6Schema;
export type ValidatedBackupSnapshot = ValidatedBackupSnapshotV6;

// =============================================================
// v2 (pre-travel-fees-rework) backup schema, kept for migration.
// =============================================================

const TourRowV2 = z.object({
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

const TourStopRowV2 = z.object({
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

const ManualHistoryEntryRowV2 = z.object({
  id: z.string(),
  clientId: z.string(),
  date: z.string(),
  notes: optStr,
  services: z.string(),
});

export const BackupSnapshotV2Schema = z.object({
  schemaVersion: z.literal(2),
  createdAt: z.string(),
  tables: z.object({
    clients: z.array(ClientRowV3),
    species: z.array(SpeciesRow),
    animal_categories: z.array(AnimalCategoryRow),
    services: z.array(ServiceRow),
    tours: z.array(TourRowV2),
    tour_stops: z.array(TourStopRowV2),
    manual_history_entries: z.array(ManualHistoryEntryRowV2),
    distance_matrix: z.array(DistanceMatrixRow),
    settings: z.array(SettingsRow),
  }),
});

export type ValidatedBackupSnapshotV2 = z.infer<typeof BackupSnapshotV2Schema>;

export function migrateV2ToV3(v2: ValidatedBackupSnapshotV2): ValidatedBackupSnapshotV3 {
  return {
    schemaVersion: 3,
    createdAt: v2.createdAt,
    tables: {
      ...v2.tables,
      tours: v2.tables.tours.map(({ totalTravelFeeCents: _drop, ...rest }) => rest),
      tour_stops: v2.tables.tour_stops.map(({ feeShareCents, ...rest }) => ({
        ...rest,
        travelFeeCents: feeShareCents ?? null,
      })),
      manual_history_entries: v2.tables.manual_history_entries.map((e) => ({
        ...e,
        travelFeeCents: null,
      })),
    },
  };
}

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
