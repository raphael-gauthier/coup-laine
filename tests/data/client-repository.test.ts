import { createTestDb } from './_helpers/test-db';
import { ClientRepository } from '@/data/repositories/client-repository';
import { TourRepository } from '@/data/repositories/tour-repository';
import { ManualHistoryRepository } from '@/data/repositories/manual-history-repository';
import { EMPTY_PAYMENT } from '@/domain/models/payment';

const NOW = '2026-05-03T12:00:00.000Z';

const sample = {
  id: 'c1',
  displayName: 'Jean Dupont',
  phones: ['0612345678'],
  addressLabel: '1 rue du Test, 29000 Quimper',
  addressCity: 'Quimper',
  addressPostcode: '29000',
  latitude: 48.0,
  longitude: -4.1,
  isWaiting: true,
  isBanned: false,
  needsDistanceRecompute: false,
  lastShearingDate: null,
  animalCounts: [{ categoryId: 'sheep-adult', count: 12 }],
  markerColorHex: null,
  createdAt: NOW,
  updatedAt: NOW,
};

describe('ClientRepository', () => {
  it('inserts and reads back a client (round-trip JSON fields)', async () => {
    const { db, close } = createTestDb();
    const repo = new ClientRepository(db);
    await repo.upsert(sample);
    const fetched = await repo.byId('c1');
    expect(fetched).toEqual(sample);
    close();
  });

  it('listAll returns all clients', async () => {
    const { db, close } = createTestDb();
    const repo = new ClientRepository(db);
    await repo.upsert(sample);
    await repo.upsert({ ...sample, id: 'c2', displayName: 'Marie' });
    const all = await repo.listAll();
    expect(all).toHaveLength(2);
    close();
  });

  it('listWaiting filters by isWaiting=true', async () => {
    const { db, close } = createTestDb();
    const repo = new ClientRepository(db);
    await repo.upsert(sample);
    await repo.upsert({ ...sample, id: 'c2', displayName: 'Marie', isWaiting: false });
    const waiting = await repo.listWaiting();
    expect(waiting.map((c) => c.id)).toEqual(['c1']);
    close();
  });

  it('setWaiting toggles the flag', async () => {
    const { db, close } = createTestDb();
    const repo = new ClientRepository(db);
    await repo.upsert({ ...sample, isWaiting: false });
    await repo.setWaiting('c1', true, NOW);
    expect((await repo.byId('c1'))!.isWaiting).toBe(true);
    close();
  });

  it('setBanned toggles the flag', async () => {
    const { db, close } = createTestDb();
    const repo = new ClientRepository(db);
    await repo.upsert(sample);
    await repo.setBanned('c1', true, NOW);
    expect((await repo.byId('c1'))!.isBanned).toBe(true);
    close();
  });

  it('setRecomputePending and listWithRecomputePending round-trip', async () => {
    const { db, close } = createTestDb();
    const repo = new ClientRepository(db);
    await repo.upsert(sample);
    await repo.upsert({ ...sample, id: 'c2', displayName: 'Marie' });
    await repo.setRecomputePending('c2', true, NOW);
    const pending = await repo.listWithRecomputePending();
    expect(pending.map((c) => c.id)).toEqual(['c2']);
    close();
  });

  it('delete removes a client', async () => {
    const { db, close } = createTestDb();
    const repo = new ClientRepository(db);
    await repo.upsert(sample);
    await repo.delete('c1');
    expect(await repo.byId('c1')).toBeNull();
    close();
  });
});

describe('ClientRepository.listClientIdsWithOutstanding', () => {
  it('returns clients with unpaid completed stops or unpaid manual entries', async () => {
    const { db, close } = createTestDb();
    const clientRepo = new ClientRepository(db);
    const tourRepo = new TourRepository(db);
    const manualRepo = new ManualHistoryRepository(db);

    for (const id of ['c1', 'c2', 'c3']) {
      await clientRepo.upsert({
        id, displayName: id, phones: [],
        addressLabel: null, addressCity: null, addressPostcode: null,
        latitude: null, longitude: null,
        isWaiting: false, isBanned: false, needsDistanceRecompute: false,
        lastShearingDate: null, animalCounts: [], markerColorHex: null,
        createdAt: 'x', updatedAt: 'x',
      });
    }

    // c1: completed unpaid stop -> outstanding
    await tourRepo.upsertTour(
      { id: 't1', scheduledDate: '2026-05-01', departureTime: '08:00',
        baseLat: 0, baseLng: 0, status: 'completed',
        totalDistanceKm: null, totalDriveSeconds: null, totalMinutes: null,
        totalRevenueCents: null, totalAnimalsCount: null, totalTravelFeeCents: null,
        routeGeometry: null, notes: null, completedAt: '2026-05-01T12:00:00Z',
        createdAt: 'x', updatedAt: 'x' },
      [{ id: 's1', tourId: 't1', clientId: 'c1', clientNameSnapshot: null,
         ordering: 0, arrivalMinutes: null, departureMinutes: null,
         estimatedMinutes: null, feeShareCents: null,
         plannedServices: [], actualServices: [],
         notes: null, completedAt: '2026-05-01T12:00:00Z',
         payment: EMPTY_PAYMENT }]
    );

    // c2: unpaid manual entry -> outstanding
    await manualRepo.upsert({
      id: 'e1', clientId: 'c2', date: '2026-04-01',
      notes: null, services: [], payment: EMPTY_PAYMENT,
    });

    // c3: planned tour stop unpaid -> NOT outstanding (not completed)
    await tourRepo.upsertTour(
      { id: 't2', scheduledDate: '2026-06-01', departureTime: '08:00',
        baseLat: 0, baseLng: 0, status: 'planned',
        totalDistanceKm: null, totalDriveSeconds: null, totalMinutes: null,
        totalRevenueCents: null, totalAnimalsCount: null, totalTravelFeeCents: null,
        routeGeometry: null, notes: null, completedAt: null,
        createdAt: 'x', updatedAt: 'x' },
      [{ id: 's2', tourId: 't2', clientId: 'c3', clientNameSnapshot: null,
         ordering: 0, arrivalMinutes: null, departureMinutes: null,
         estimatedMinutes: null, feeShareCents: null,
         plannedServices: [], actualServices: null,
         notes: null, completedAt: null,
         payment: EMPTY_PAYMENT }]
    );

    const ids = await clientRepo.listClientIdsWithOutstanding();
    expect(Array.from(ids).sort()).toEqual(['c1', 'c2']);
    close();
  });
});
