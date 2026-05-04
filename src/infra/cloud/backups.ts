import { supabase } from '@/infra/services/supabase';
import { db } from '@/infra/db/client';
import * as schema from '@/infra/db/schema';

const BUCKET = 'backups';

interface BackupSnapshot {
  schemaVersion: 2;
  createdAt: string;
  tables: {
    clients: unknown[];
    species: unknown[];
    animal_categories: unknown[];
    services: unknown[];
    tours: unknown[];
    tour_stops: unknown[];
    manual_history_entries: unknown[];
    distance_matrix: unknown[];
    settings: unknown[];
  };
}

export interface BackupFile {
  name: string;
  createdAt: string;
  size: number;
}

async function userId(): Promise<string> {
  const { data } = await supabase.auth.getSession();
  const id = data.session?.user.id;
  if (!id) throw new Error('Not authenticated');
  return id;
}

async function dumpAllTables(): Promise<BackupSnapshot['tables']> {
  return {
    clients: await db.select().from(schema.clients),
    species: await db.select().from(schema.species),
    animal_categories: await db.select().from(schema.animalCategories),
    services: await db.select().from(schema.services),
    tours: await db.select().from(schema.tours),
    tour_stops: await db.select().from(schema.tourStops),
    manual_history_entries: await db.select().from(schema.manualHistoryEntries),
    distance_matrix: await db.select().from(schema.distanceMatrix),
    settings: await db.select().from(schema.settings),
  };
}

async function wipeAndRestore(tables: BackupSnapshot['tables']): Promise<void> {
  await db.delete(schema.distanceMatrix);
  await db.delete(schema.manualHistoryEntries);
  await db.delete(schema.tourStops);
  await db.delete(schema.tours);
  await db.delete(schema.animalCategories);
  await db.delete(schema.species);
  await db.delete(schema.services);
  await db.delete(schema.clients);
  await db.delete(schema.settings);

  for (const row of tables.species) await db.insert(schema.species).values(row as typeof schema.species.$inferInsert);
  for (const row of tables.animal_categories) await db.insert(schema.animalCategories).values(row as typeof schema.animalCategories.$inferInsert);
  for (const row of tables.services) await db.insert(schema.services).values(row as typeof schema.services.$inferInsert);
  for (const row of tables.clients) await db.insert(schema.clients).values(row as typeof schema.clients.$inferInsert);
  for (const row of tables.tours) await db.insert(schema.tours).values(row as typeof schema.tours.$inferInsert);
  for (const row of tables.tour_stops) await db.insert(schema.tourStops).values(row as typeof schema.tourStops.$inferInsert);
  for (const row of tables.manual_history_entries) await db.insert(schema.manualHistoryEntries).values(row as typeof schema.manualHistoryEntries.$inferInsert);
  for (const row of tables.distance_matrix) await db.insert(schema.distanceMatrix).values(row as typeof schema.distanceMatrix.$inferInsert);
  for (const row of tables.settings) await db.insert(schema.settings).values(row as typeof schema.settings.$inferInsert);
}

export async function createBackup(): Promise<string> {
  const uid = await userId();
  const snapshot: BackupSnapshot = {
    schemaVersion: 2,
    createdAt: new Date().toISOString(),
    tables: await dumpAllTables(),
  };
  const filename = `${snapshot.createdAt.replace(/[:.]/g, '-')}.json`;
  const path = `${uid}/${filename}`;
  const body = JSON.stringify(snapshot);

  const { error } = await supabase.storage.from(BUCKET).upload(path, body, {
    contentType: 'application/json',
    upsert: false,
  });
  if (error) throw error;
  return path;
}

export async function listBackups(): Promise<BackupFile[]> {
  const uid = await userId();
  const { data, error } = await supabase.storage.from(BUCKET).list(uid, {
    sortBy: { column: 'created_at', order: 'desc' },
  });
  if (error) throw error;
  return (data ?? []).map((f) => ({
    name: f.name,
    createdAt: f.created_at ?? f.updated_at ?? '',
    size: (f.metadata?.size as number | undefined) ?? 0,
  }));
}

export async function restoreBackup(name: string): Promise<void> {
  const uid = await userId();
  const path = `${uid}/${name}`;
  const { data, error } = await supabase.storage.from(BUCKET).download(path);
  if (error) throw error;
  const text = await data.text();
  const snapshot = JSON.parse(text) as BackupSnapshot;
  if (snapshot.schemaVersion !== 2) {
    throw new Error(`Unknown schema (v${snapshot.schemaVersion})`);
  }
  await wipeAndRestore(snapshot.tables);
}

export async function deleteBackup(name: string): Promise<void> {
  const uid = await userId();
  await supabase.storage.from(BUCKET).remove([`${uid}/${name}`]);
}
