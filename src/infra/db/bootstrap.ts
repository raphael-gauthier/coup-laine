// src/infra/db/bootstrap.ts
import { migrate } from 'drizzle-orm/expo-sqlite/migrator';
import { db } from './client';
import migrations from './migrations/migrations';
import { paymentMethods } from './schema';
import { SettingsRepository } from '@/data/repositories/settings-repository';
import { isThemeMode, useThemeStore } from '@/state/stores/theme-store';
import { ClientRepository } from '@/data/repositories/client-repository';
import { DistanceMatrixRepository } from '@/data/repositories/distance-matrix-repository';
import { findClientsNeedingRecompute } from '@/domain/use-cases/consistency-check';

let initialized = false;

const MARKER_DEFAULTS: Record<string, string> = {
  marker_default_color: '#5C4E40',
  marker_waiting_color: '#C88226',
  marker_scheduled_color: '#A1602F',
  marker_done_color: '#5C7548',
  marker_no_animals_color: '#DCD0C0',
  marker_banned_color: '#B23832',
};

function defaultSeasonStart(): string {
  // French shearing season starts May 1st of the most recent year not in the future.
  const now = new Date();
  const year = now.getMonth() >= 4 ? now.getFullYear() : now.getFullYear() - 1;
  return `${year}-05-01`;
}

const PAYMENT_METHODS_SEED: { id: string; label: string; ordering: number }[] = [
  { id: 'pm-cash', label: 'Espèces', ordering: 1 },
  { id: 'pm-check', label: 'Chèque', ordering: 2 },
  { id: 'pm-transfer', label: 'Virement', ordering: 3 },
  { id: 'pm-card', label: 'Carte bancaire', ordering: 4 },
  { id: 'pm-wero', label: 'Wero', ordering: 5 },
];

async function seedPaymentMethods() {
  for (const pm of PAYMENT_METHODS_SEED) {
    await db
      .insert(paymentMethods)
      .values({ ...pm, isActive: 1, archivedAt: null })
      .onConflictDoNothing({ target: paymentMethods.id });
  }
}

async function seedSettingsDefaults(repo: SettingsRepository) {
  const setIfMissing = async (key: string, value: string) => {
    if ((await repo.get(key)) === null) await repo.set(key, value);
  };
  await setIfMissing('default_radius_km', '15');
  await setIfMissing('tour_bracket_km', '10');
  await setIfMissing('tour_fee_eur_per_bracket', '8');
  await setIfMissing('season_started_at', defaultSeasonStart());
  for (const [k, v] of Object.entries(MARKER_DEFAULTS)) {
    await setIfMissing(k, v);
  }
}

export async function bootstrapDatabase() {
  if (initialized) return;
  await migrate(db, migrations);

  const settingsRepo = new SettingsRepository(db);
  await seedSettingsDefaults(settingsRepo);
  await seedPaymentMethods();

  const persistedMode = await settingsRepo.get('theme_mode');
  if (persistedMode && isThemeMode(persistedMode)) {
    useThemeStore.getState().setMode(persistedMode);
  }

  const clientRepo = new ClientRepository(db);
  const matrixRepo = new DistanceMatrixRepository(db);

  const allClients = await clientRepo.listAll();
  const allMatrix = await matrixRepo.listAll();
  const matrixPairs = new Set(allMatrix.map((e) => `${e.fromId}-${e.toId}`));

  const staleIds = findClientsNeedingRecompute({
    clients: allClients.map((c) => ({
      id: c.id,
      latitude: c.latitude,
      longitude: c.longitude,
    })),
    matrixPairs,
  });

  const now = new Date().toISOString();
  for (const id of staleIds) {
    await clientRepo.setRecomputePending(id, true, now);
  }

  initialized = true;
}
