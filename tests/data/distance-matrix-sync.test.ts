import { createTestDb } from './_helpers/test-db';
import { ClientRepository } from '@/data/repositories/client-repository';
import { SettingsRepository } from '@/data/repositories/settings-repository';
import { DistanceMatrixSync } from '@/data/distance-matrix-sync';

jest.mock('@/infra/config/env', () => ({
  env: {
    supabaseUrl: 'https://test.supabase.co',
    supabaseAnonKey: 'anon-key',
    maptilerApiKey: 'maptiler-key',
    orsBaseUrl: 'https://test.supabase.co/functions/v1/ors-proxy',
  },
}));

jest.mock('@/infra/services/supabase', () => ({
  supabase: {
    auth: {
      getSession: () => Promise.resolve({ data: { session: { access_token: 'token' } } }),
    },
  },
}));

const NOW = '2026-05-03T12:00:00.000Z';

const sample = (over: Partial<Record<string, unknown>> = {}) => ({
  id: 'c1',
  displayName: 'Test',
  phones: [],
  addressLabel: '1 rue X',
  addressCity: null,
  addressPostcode: null,
  latitude: 48,
  longitude: -3,
  isWaiting: false,
  isBanned: false,
  needsDistanceRecompute: false,
  lastShearingDate: null,
  animalCounts: [],
  markerColorHex: null,
  anonymizedAt: null,
  createdAt: NOW,
  updatedAt: NOW,
  ...over,
});

describe('DistanceMatrixSync', () => {
  beforeEach(() => {
    jest.spyOn(global, 'fetch').mockImplementation(
      async () =>
        new Response(
          JSON.stringify({
            distances: [
              [0, 12000],
              [12500, 0],
            ],
            durations: [
              [0, 900],
              [950, 0],
            ],
          }),
          { status: 200 }
        )
    );
  });
  afterEach(() => jest.restoreAllMocks());

  it('recomputeForClient writes BASE↔client pair and clears the flag', async () => {
    const { db, close } = createTestDb();
    const clients = new ClientRepository(db);
    const settings = new SettingsRepository(db);
    await settings.set('base_lat', '48.0');
    await settings.set('base_lng', '-3.0');
    await clients.upsert(sample({ needsDistanceRecompute: true }) as Parameters<typeof clients.upsert>[0]);
    const sync = new DistanceMatrixSync(db);

    const result = await sync.recomputeForClient('c1');
    expect(result.ok).toBe(true);

    const after = await clients.byId('c1');
    expect(after?.needsDistanceRecompute).toBe(false);
    close();
  });

  it('recomputeForClient on ORS failure: marks failed + keeps pending', async () => {
    jest.spyOn(global, 'fetch').mockImplementation(async () => new Response('boom', { status: 500 }));
    const { db, close } = createTestDb();
    const clients = new ClientRepository(db);
    const settings = new SettingsRepository(db);
    await settings.set('base_lat', '48.0');
    await settings.set('base_lng', '-3.0');
    await clients.upsert(sample({ needsDistanceRecompute: false }) as Parameters<typeof clients.upsert>[0]);
    const sync = new DistanceMatrixSync(db);

    const result = await sync.recomputeForClient('c1');
    expect(result.ok).toBe(false);

    const after = await clients.byId('c1');
    expect(after?.needsDistanceRecompute).toBe(true);
    close();
  });

  it('markAllPending flips the flag for every geocoded client', async () => {
    const { db, close } = createTestDb();
    const clients = new ClientRepository(db);
    await clients.upsert(sample({ id: 'c1' }) as Parameters<typeof clients.upsert>[0]);
    await clients.upsert(sample({ id: 'c2', latitude: null, longitude: null }) as Parameters<typeof clients.upsert>[0]);
    const sync = new DistanceMatrixSync(db);

    const count = await sync.markAllPending();
    expect(count).toBe(1);

    expect((await clients.byId('c1'))?.needsDistanceRecompute).toBe(true);
    expect((await clients.byId('c2'))?.needsDistanceRecompute).toBe(false);
    close();
  });
});
