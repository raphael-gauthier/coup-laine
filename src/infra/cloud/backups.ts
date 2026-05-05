import { supabase } from '@/infra/services/supabase';
import { db } from '@/infra/db/client';
import * as schema from '@/infra/db/schema';
import { BackupSnapshotSchema, type ValidatedBackupSnapshot } from './backup-schema';

const BUCKET = 'backups';

type BackupSnapshot = ValidatedBackupSnapshot;

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
  await db.transaction(async (tx) => {
    await tx.delete(schema.distanceMatrix);
    await tx.delete(schema.manualHistoryEntries);
    await tx.delete(schema.tourStops);
    await tx.delete(schema.tours);
    await tx.delete(schema.animalCategories);
    await tx.delete(schema.species);
    await tx.delete(schema.services);
    await tx.delete(schema.clients);
    await tx.delete(schema.settings);

    for (const row of tables.species) await tx.insert(schema.species).values(row as typeof schema.species.$inferInsert);
    for (const row of tables.animal_categories) await tx.insert(schema.animalCategories).values(row as typeof schema.animalCategories.$inferInsert);
    for (const row of tables.services) await tx.insert(schema.services).values(row as typeof schema.services.$inferInsert);
    for (const row of tables.clients) await tx.insert(schema.clients).values(row as typeof schema.clients.$inferInsert);
    for (const row of tables.tours) await tx.insert(schema.tours).values(row as typeof schema.tours.$inferInsert);
    for (const row of tables.tour_stops) await tx.insert(schema.tourStops).values(row as typeof schema.tourStops.$inferInsert);
    for (const row of tables.manual_history_entries) await tx.insert(schema.manualHistoryEntries).values(row as typeof schema.manualHistoryEntries.$inferInsert);
    for (const row of tables.distance_matrix) await tx.insert(schema.distanceMatrix).values(row as typeof schema.distanceMatrix.$inferInsert);
    for (const row of tables.settings) await tx.insert(schema.settings).values(row as typeof schema.settings.$inferInsert);
  });
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

  // Keep only the most recent HISTORY_WINDOW backups (mirrors Flutter behaviour).
  // Best-effort: a failure here doesn't invalidate the backup we just uploaded.
  try {
    const all = await listBackups();
    const stale = all.slice(HISTORY_WINDOW).map((f) => `${uid}/${f.name}`);
    if (stale.length > 0) {
      await supabase.storage.from(BUCKET).remove(stale);
    }
  } catch {
    /* ignore */
  }

  return path;
}

const HISTORY_WINDOW = 3;

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
  const parsed = BackupSnapshotSchema.safeParse(JSON.parse(text));
  if (!parsed.success) {
    throw new Error(`Invalid backup format: ${parsed.error.issues[0]?.message ?? 'unknown error'}`);
  }
  await wipeAndRestore(parsed.data.tables);
}

export async function deleteBackup(name: string): Promise<void> {
  const uid = await userId();
  await supabase.storage.from(BUCKET).remove([`${uid}/${name}`]);
}
