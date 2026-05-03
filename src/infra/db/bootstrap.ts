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
