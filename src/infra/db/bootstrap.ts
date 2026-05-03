// src/infra/db/bootstrap.ts
import { migrate } from 'drizzle-orm/expo-sqlite/migrator';
import { db } from './client';
import migrations from './migrations/migrations';
import { seedSpeciesIfEmpty } from '@/data/seeds/species-seeds';
import { seedPrestationsIfEmpty } from '@/data/seeds/prestation-seeds';
import { SettingsRepository } from '@/data/repositories/settings-repository';
import { isThemeMode, useThemeStore } from '@/state/stores/theme-store';

let initialized = false;

export async function bootstrapDatabase() {
  if (initialized) return;
  await migrate(db, migrations);
  await seedSpeciesIfEmpty(db);
  await seedPrestationsIfEmpty(db);

  const settingsRepo = new SettingsRepository(db);
  const persistedMode = await settingsRepo.get('theme_mode');
  if (persistedMode && isThemeMode(persistedMode)) {
    useThemeStore.getState().setMode(persistedMode);
  }

  initialized = true;
}
