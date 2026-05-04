import { createTestDb } from './_helpers/test-db';
import { ClientRepository } from '@/data/repositories/client-repository';
import { TourRepository } from '@/data/repositories/tour-repository';

const NOW = '2026-05-03T12:00:00.000Z';

const sampleClient = (id: string) => ({
  id,
  displayName: id,
  phones: [],
  addressLabel: null,
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
  createdAt: NOW,
  updatedAt: NOW,
});

const sampleTour = {
  id: 't1',
  scheduledDate: '2026-05-10',
  departureTime: '08:00',
  baseLat: 48.0,
  baseLng: -3.0,
  status: 'planned' as const,
  totalDistanceKm: null,
  totalDriveSeconds: null,
  totalMinutes: null,
  totalRevenueCents: null,
  totalAnimalsCount: null,
  totalTravelFeeCents: null,
  routeGeometry: null,
  notes: null,
  completedAt: null,
  createdAt: NOW,
  updatedAt: NOW,
};

const sampleStops = [
  {
    id: 's1', tourId: 't1', clientId: 'c1',
    clientNameSnapshot: null, ordering: 0,
    arrivalMinutes: null, departureMinutes: null, estimatedMinutes: null,
    feeShareCents: null,
    plannedServices: [], actualServices: null,
    notes: null, completedAt: null,
  },
  {
    id: 's2', tourId: 't1', clientId: 'c2',
    clientNameSnapshot: null, ordering: 1,
    arrivalMinutes: null, departureMinutes: null, estimatedMinutes: null,
    feeShareCents: null,
    plannedServices: [], actualServices: null,
    notes: null, completedAt: null,
  },
];

describe('TourRepository', () => {
  it('round-trips a tour with stops', async () => {
    const { db, close } = createTestDb();
    const cRepo = new ClientRepository(db);
    const tRepo = new TourRepository(db);
    await cRepo.upsert(sampleClient('c1'));
    await cRepo.upsert(sampleClient('c2'));
    await tRepo.upsertTour(sampleTour, sampleStops);
    const r = await tRepo.byId('t1');
    expect(r?.tour.id).toBe('t1');
    expect(r?.stops.map((s) => s.id)).toEqual(['s1', 's2']);
    close();
  });

  it('replaces stops on upsert (no duplicates)', async () => {
    const { db, close } = createTestDb();
    const cRepo = new ClientRepository(db);
    const tRepo = new TourRepository(db);
    await cRepo.upsert(sampleClient('c1'));
    await cRepo.upsert(sampleClient('c2'));
    await tRepo.upsertTour(sampleTour, sampleStops);
    await tRepo.upsertTour(sampleTour, [sampleStops[0]!]);
    const r = await tRepo.byId('t1');
    expect(r?.stops.map((s) => s.id)).toEqual(['s1']);
    close();
  });

  it('listByStatus filters', async () => {
    const { db, close } = createTestDb();
    const cRepo = new ClientRepository(db);
    const tRepo = new TourRepository(db);
    await cRepo.upsert(sampleClient('c1'));
    await tRepo.upsertTour(sampleTour, [sampleStops[0]!]);
    await tRepo.upsertTour({ ...sampleTour, id: 't2', status: 'completed' as const }, []);
    expect((await tRepo.listByStatus('planned')).map((x) => x.tour.id)).toEqual(['t1']);
    expect((await tRepo.listByStatus('completed')).map((x) => x.tour.id)).toEqual(['t2']);
    close();
  });

  it('markStopCompleted sets completedAt', async () => {
    const { db, close } = createTestDb();
    const cRepo = new ClientRepository(db);
    const tRepo = new TourRepository(db);
    await cRepo.upsert(sampleClient('c1'));
    await cRepo.upsert(sampleClient('c2'));
    await tRepo.upsertTour(sampleTour, sampleStops);
    await tRepo.markStopCompleted('s1', NOW);
    const r = await tRepo.byId('t1');
    expect(r?.stops.find((s) => s.id === 's1')?.completedAt).toBe(NOW);
    close();
  });
});
