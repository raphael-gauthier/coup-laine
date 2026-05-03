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
  status: text('status').notNull(),
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
