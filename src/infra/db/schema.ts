// src/infra/db/schema.ts
import { sqliteTable, text, integer, real, primaryKey, index } from 'drizzle-orm/sqlite-core';

export const clients = sqliteTable(
  'clients',
  {
    id: text('id').primaryKey(),
    displayName: text('display_name').notNull(),
    phones: text('phones').notNull().default('[]'),
    addressLabel: text('address_label'),
    addressCity: text('address_city'),
    addressPostcode: text('address_postcode'),
    latitude: real('latitude'),
    longitude: real('longitude'),
    isWaiting: integer('is_waiting').notNull().default(0),
    isBanned: integer('is_banned').notNull().default(0),
    needsDistanceRecompute: integer('needs_distance_recompute').notNull().default(0),
    lastShearingDate: text('last_shearing_date'),
    animalCounts: text('animal_counts').notNull().default('[]'),
    markerColorHex: text('marker_color_hex'),
    createdAt: text('created_at').notNull(),
    updatedAt: text('updated_at').notNull(),
  },
  (t) => ({
    waitingIdx: index('clients_is_waiting_idx').on(t.isWaiting),
    bannedIdx: index('clients_is_banned_idx').on(t.isBanned),
    recomputeIdx: index('clients_needs_recompute_idx').on(t.needsDistanceRecompute),
    lastShearingIdx: index('clients_last_shearing_idx').on(t.lastShearingDate),
  })
);

export const species = sqliteTable('species', {
  id: text('id').primaryKey(),
  label: text('label').notNull(),
  iconKey: text('icon_key'),
  ordering: integer('ordering').notNull(),
  isCustom: integer('is_custom').notNull().default(0),
  archivedAt: text('archived_at'),
});

export const animalCategories = sqliteTable(
  'animal_categories',
  {
    id: text('id').primaryKey(),
    speciesId: text('species_id').notNull().references(() => species.id),
    label: text('label').notNull(),
    ordering: integer('ordering').notNull(),
    isCustom: integer('is_custom').notNull().default(0),
    archivedAt: text('archived_at'),
  },
  (t) => ({
    speciesIdx: index('animal_categories_species_idx').on(t.speciesId),
  })
);

export const services = sqliteTable('services', {
  id: text('id').primaryKey(),
  label: text('label').notNull(),
  priceCents: integer('price_cents'),
  minutes: integer('minutes').notNull().default(0),
  categoryId: text('category_id').references(() => animalCategories.id),
  isActive: integer('is_active').notNull().default(1),
  archivedAt: text('archived_at'),
  ordering: integer('ordering').notNull(),
});

export const paymentMethods = sqliteTable('payment_methods', {
  id: text('id').primaryKey(),
  label: text('label').notNull(),
  isActive: integer('is_active').notNull().default(1),
  archivedAt: text('archived_at'),
  ordering: integer('ordering').notNull(),
});

export const tours = sqliteTable('tours', {
  id: text('id').primaryKey(),
  scheduledDate: text('scheduled_date').notNull(),
  departureTime: text('departure_time').notNull(),
  baseLat: real('base_lat').notNull(),
  baseLng: real('base_lng').notNull(),
  status: text('status').notNull(),
  totalDistanceKm: real('total_distance_km'),
  totalDriveSeconds: integer('total_drive_seconds'),
  totalMinutes: integer('total_minutes'),
  totalRevenueCents: integer('total_revenue_cents'),
  totalAnimalsCount: integer('total_animals_count'),
  totalTravelFeeCents: integer('total_travel_fee_cents'),
  routeGeometry: text('route_geometry'),
  notes: text('notes'),
  completedAt: text('completed_at'),
  createdAt: text('created_at').notNull(),
  updatedAt: text('updated_at').notNull(),
});

export const tourStops = sqliteTable(
  'tour_stops',
  {
    id: text('id').primaryKey(),
    tourId: text('tour_id').notNull().references(() => tours.id, { onDelete: 'cascade' }),
    clientId: text('client_id').notNull().references(() => clients.id),
    clientNameSnapshot: text('client_name_snapshot'),
    ordering: integer('ordering').notNull(),
    arrivalMinutes: integer('arrival_minutes'),
    departureMinutes: integer('departure_minutes'),
    estimatedMinutes: integer('estimated_minutes'),
    feeShareCents: integer('fee_share_cents'),
    plannedServices: text('planned_services').notNull().default('[]'),
    actualServices: text('actual_services'),
    notes: text('notes'),
    completedAt: text('completed_at'),
    paymentMethodId: text('payment_method_id').references(() => paymentMethods.id),
    paymentMethodLabelSnapshot: text('payment_method_label_snapshot'),
    isPaid: integer('is_paid').notNull().default(0),
    paidAt: text('paid_at'),
  },
  (t) => ({
    tourIdx: index('tour_stops_tour_idx').on(t.tourId),
    clientIdx: index('tour_stops_client_idx').on(t.clientId),
    isPaidIdx: index('tour_stops_is_paid_idx').on(t.isPaid),
  })
);

export const manualHistoryEntries = sqliteTable(
  'manual_history_entries',
  {
    id: text('id').primaryKey(),
    clientId: text('client_id').notNull().references(() => clients.id, { onDelete: 'cascade' }),
    date: text('date').notNull(),
    notes: text('notes'),
    services: text('services').notNull().default('[]'),
    paymentMethodId: text('payment_method_id').references(() => paymentMethods.id),
    paymentMethodLabelSnapshot: text('payment_method_label_snapshot'),
    isPaid: integer('is_paid').notNull().default(0),
    paidAt: text('paid_at'),
  },
  (t) => ({
    clientIdx: index('manual_history_client_idx').on(t.clientId),
    isPaidIdx: index('manual_history_is_paid_idx').on(t.isPaid),
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
    failed: integer('failed').notNull().default(0),
  },
  (t) => ({
    pk: primaryKey({ columns: [t.fromId, t.toId] }),
  })
);

export const settings = sqliteTable('settings', {
  key: text('key').primaryKey(),
  value: text('value').notNull(),
});
