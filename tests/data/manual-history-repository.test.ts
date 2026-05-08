import { createTestDb } from './_helpers/test-db';
import { ClientRepository } from '@/data/repositories/client-repository';
import { ManualHistoryRepository } from '@/data/repositories/manual-history-repository';
import { EMPTY_PAYMENT } from '@/domain/models/payment';

const NOW = '2026-05-03T12:00:00.000Z';

const sampleClient = {
  id: 'c1', displayName: 'X',
  phones: [],
  addressLabel: null, addressCity: null, addressPostcode: null,
  latitude: null, longitude: null,
  isWaiting: false, isBanned: false, needsDistanceRecompute: false,
  lastShearingDate: null, animalCounts: [], markerColorHex: null,
  anonymizedAt: null, manualStatusId: null, createdAt: NOW, updatedAt: NOW,
};

async function seedClient(db: any, id = 'c1') {
  await new ClientRepository(db).upsert({
    id, displayName: 'Test', phones: [],
    addressLabel: null, addressCity: null, addressPostcode: null,
    latitude: null, longitude: null,
    isWaiting: false, isBanned: false, needsDistanceRecompute: false,
    lastShearingDate: null, animalCounts: [], markerColorHex: null,
    anonymizedAt: null, manualStatusId: null, createdAt: 'x', updatedAt: 'x',
  });
}

describe('ManualHistoryRepository', () => {
  it('lists entries by client, ordered by date desc', async () => {
    const { db, close } = createTestDb();
    const cRepo = new ClientRepository(db);
    const repo = new ManualHistoryRepository(db);
    await cRepo.upsert(sampleClient);
    await repo.upsert({ id: 'h1', clientId: 'c1', date: '2025-06-01', notes: null, services: [], travelFeeCents: null, payment: EMPTY_PAYMENT });
    await repo.upsert({ id: 'h2', clientId: 'c1', date: '2026-01-15', notes: null, services: [], travelFeeCents: null, payment: EMPTY_PAYMENT });
    const entries = await repo.listByClient('c1');
    expect(entries.map((e) => e.id)).toEqual(['h2', 'h1']);
    close();
  });
});

describe('ManualHistoryRepository payment round-trip', () => {
  it('persists and reads back the payment field', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new ManualHistoryRepository(db);
    await repo.upsert({
      id: 'e1', clientId: 'c1', date: '2026-04-15',
      notes: null, services: [], travelFeeCents: null,
      payment: {
        methodId: 'pm-check', methodLabelSnapshot: 'Chèque',
        isPaid: true, paidAt: '2026-04-15T10:00:00Z',
      },
    });
    const all = await repo.listByClient('c1');
    const entry = all[0]!;
    expect(entry.payment.methodId).toBe('pm-check');
    expect(entry.payment.isPaid).toBe(true);
    close();
  });

  it('markEntryPayment updates only the payment columns', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new ManualHistoryRepository(db);
    await repo.upsert({
      id: 'e1', clientId: 'c1', date: '2026-04-15',
      notes: 'note', services: [], travelFeeCents: null, payment: EMPTY_PAYMENT,
    });
    await repo.markEntryPayment('e1', {
      methodId: 'pm-cash', methodLabelSnapshot: 'Espèces',
      isPaid: true, paidAt: '2026-05-01T00:00:00Z',
    });
    const all = await repo.listByClient('c1');
    const updated = all[0]!;
    expect(updated.notes).toBe('note');
    expect(updated.payment.isPaid).toBe(true);
    expect(updated.payment.methodId).toBe('pm-cash');
    close();
  });
});

describe('ManualHistoryRepository travel fee round-trip', () => {
  it('persists and reads back travelFeeCents', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new ManualHistoryRepository(db);
    await repo.upsert({
      id: 'e1', clientId: 'c1', date: '2026-04-15',
      notes: null, services: [], travelFeeCents: 1500,
      payment: EMPTY_PAYMENT,
    });
    const all = await repo.listByClient('c1');
    expect(all[0]!.travelFeeCents).toBe(1500);
    close();
  });

  it('persists null travelFeeCents', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new ManualHistoryRepository(db);
    await repo.upsert({
      id: 'e2', clientId: 'c1', date: '2026-04-16',
      notes: null, services: [], travelFeeCents: null,
      payment: EMPTY_PAYMENT,
    });
    const all = await repo.listByClient('c1');
    expect(all[0]!.travelFeeCents).toBeNull();
    close();
  });
});
