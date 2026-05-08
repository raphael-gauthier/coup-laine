import { createTestDb } from './_helpers/test-db';
import { ClientRepository } from '@/data/repositories/client-repository';
import { TourRepository } from '@/data/repositories/tour-repository';
import { EMPTY_PAYMENT } from '@/domain/models/payment';
import type { Tour } from '@/domain/models/tour';
import type { TourStop } from '@/domain/models/tour-stop';

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
  anonymizedAt: null,
  createdAt: NOW,
  updatedAt: NOW,
});

const sampleTour = {
  id: 't1',
  scheduledDate: '2026-05-10',
  departureTime: '08:00',
  title: null,
  baseLat: 48.0,
  baseLng: -3.0,
  status: 'planned' as const,
  totalDistanceKm: null,
  totalDriveSeconds: null,
  totalMinutes: null,
  totalRevenueCents: null,
  totalAnimalsCount: null,
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
    travelFeeCents: null,
    plannedServices: [], actualServices: null,
    notes: null, completedAt: null,
    payment: EMPTY_PAYMENT,
  },
  {
    id: 's2', tourId: 't1', clientId: 'c2',
    clientNameSnapshot: null, ordering: 1,
    arrivalMinutes: null, departureMinutes: null, estimatedMinutes: null,
    travelFeeCents: null,
    plannedServices: [], actualServices: null,
    notes: null, completedAt: null,
    payment: EMPTY_PAYMENT,
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

  it('persists and retrieves a draft tour with null date/time and a title', async () => {
    const { db, close } = createTestDb();
    const tRepo = new TourRepository(db);
    const cRepo = new ClientRepository(db);
    await cRepo.upsert(sampleClient('c1'));

    const draft = {
      id: 'draft1',
      scheduledDate: null,
      departureTime: null,
      title: 'Mardi nord',
      baseLat: 48.0,
      baseLng: -3.0,
      status: 'draft' as const,
      totalDistanceKm: null,
      totalDriveSeconds: null,
      totalMinutes: null,
      totalRevenueCents: null,
      totalAnimalsCount: null,
      routeGeometry: null,
      notes: null,
      completedAt: null,
      createdAt: NOW,
      updatedAt: NOW,
    };

    await tRepo.upsertTour(draft, []);
    const fetched = await tRepo.byId('draft1');

    expect(fetched).not.toBeNull();
    expect(fetched!.tour.status).toBe('draft');
    expect(fetched!.tour.title).toBe('Mardi nord');
    expect(fetched!.tour.scheduledDate).toBeNull();
    expect(fetched!.tour.departureTime).toBeNull();
    close();
  });
});

const baseTour: Omit<Tour, 'id'> = {
  scheduledDate: '2026-05-01',
  departureTime: '08:00',
  title: null,
  baseLat: 0, baseLng: 0,
  status: 'planned',
  totalDistanceKm: null, totalDriveSeconds: null, totalMinutes: null,
  totalRevenueCents: null, totalAnimalsCount: null,
  routeGeometry: null, notes: null, completedAt: null,
  createdAt: 'x', updatedAt: 'x',
};

function makeStop(overrides: Partial<TourStop> = {}): TourStop {
  return {
    id: 's1', tourId: 't1', clientId: 'c1', clientNameSnapshot: null,
    ordering: 0, arrivalMinutes: null, departureMinutes: null,
    estimatedMinutes: null, travelFeeCents: null,
    plannedServices: [], actualServices: null,
    notes: null, completedAt: null,
    payment: EMPTY_PAYMENT,
    ...overrides,
  };
}

async function seedClient(db: any, id = 'c1') {
  const repo = new ClientRepository(db);
  await repo.upsert({
    id, displayName: 'Test', phones: [],
    addressLabel: null, addressCity: null, addressPostcode: null,
    latitude: null, longitude: null,
    isWaiting: false, isBanned: false, needsDistanceRecompute: false,
    lastShearingDate: null, animalCounts: [], markerColorHex: null,
    anonymizedAt: null, createdAt: 'x', updatedAt: 'x',
  });
}

describe('TourRepository payment round-trip', () => {
  it('persists and reads back the payment field on a stop', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new TourRepository(db);
    const tour = { id: 't1', ...baseTour };
    const stop = makeStop({
      payment: {
        methodId: 'pm-cash',
        methodLabelSnapshot: 'Espèces',
        isPaid: true,
        paidAt: '2026-05-01T12:00:00Z',
      },
    });
    await repo.upsertTour(tour, [stop]);
    const got = await repo.byId('t1');
    expect(got!.stops[0]!.payment.isPaid).toBe(true);
    expect(got!.stops[0]!.payment.methodLabelSnapshot).toBe('Espèces');
    close();
  });

  it('markStopPayment updates only the payment columns', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new TourRepository(db);
    await repo.upsertTour({ id: 't1', ...baseTour }, [makeStop()]);
    await repo.markStopPayment('s1', {
      methodId: 'pm-check',
      methodLabelSnapshot: 'Chèque',
      isPaid: true,
      paidAt: '2026-05-02T09:00:00Z',
    });
    const got = await repo.byId('t1');
    expect(got!.stops[0]!.payment.methodId).toBe('pm-check');
    expect(got!.stops[0]!.payment.isPaid).toBe(true);
    close();
  });

  it('completeWithBilan writes per-stop payments alongside actuals', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new TourRepository(db);
    await repo.upsertTour({ id: 't1', ...baseTour }, [makeStop()]);
    const payments = new Map([['s1', {
      methodId: 'pm-cash', methodLabelSnapshot: 'Espèces',
      isPaid: true, paidAt: '2026-05-01T12:00:00Z',
    }]]);
    await repo.completeWithBilan(
      't1',
      new Map([['s1', []]]),
      new Map([['s1', null]]),
      payments,
      new Map<string, number>(),
      '2026-05-01T12:00:00Z'
    );
    const got = await repo.byId('t1');
    expect(got!.stops[0]!.payment.isPaid).toBe(true);
    expect(got!.tour.status).toBe('completed');
    close();
  });
});
