import { createTestDb } from './_helpers/test-db';
import { ClientRepository } from '@/data/repositories/client-repository';
import { ManualHistoryRepository } from '@/data/repositories/manual-history-repository';

const NOW = '2026-05-03T12:00:00.000Z';

const sampleClient = {
  id: 'c1', displayName: 'X',
  firstName: null, lastName: null, phones: [], email: null,
  addressLabel: null, addressCity: null, addressPostcode: null,
  latitude: null, longitude: null, isWaiting: false, notes: null,
  lastShearingDate: null, animalCounts: [],
  createdAt: NOW, updatedAt: NOW,
};

describe('ManualHistoryRepository', () => {
  it('lists entries by client, ordered by date desc', async () => {
    const { db, close } = createTestDb();
    const cRepo = new ClientRepository(db);
    const repo = new ManualHistoryRepository(db);
    await cRepo.upsert(sampleClient);
    await repo.upsert({ id: 'h1', clientId: 'c1', date: '2025-06-01', notes: null, prestations: [] });
    await repo.upsert({ id: 'h2', clientId: 'c1', date: '2026-01-15', notes: null, prestations: [] });
    const entries = await repo.listByClient('c1');
    expect(entries.map((e) => e.id)).toEqual(['h2', 'h1']);
    close();
  });
});
