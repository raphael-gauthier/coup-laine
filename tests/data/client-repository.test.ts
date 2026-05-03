import { createTestDb } from './_helpers/test-db';
import { ClientRepository } from '@/data/repositories/client-repository';

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
