import { createTestDb } from './_helpers/test-db';
import { PrestationRepository } from '@/data/repositories/prestation-repository';

describe('PrestationRepository', () => {
  it('round-trips a prestation', async () => {
    const { db, close } = createTestDb();
    const repo = new PrestationRepository(db);
    await repo.upsert({ id: 'shearing', label: 'Tonte', price: null, isActive: true, ordering: 0 });
    const all = await repo.listAll();
    expect(all).toContainEqual({ id: 'shearing', label: 'Tonte', price: null, isActive: true, ordering: 0 });
    close();
  });

  it('listActive filters out inactive', async () => {
    const { db, close } = createTestDb();
    const repo = new PrestationRepository(db);
    await repo.upsert({ id: 'a', label: 'A', price: null, isActive: true, ordering: 0 });
    await repo.upsert({ id: 'b', label: 'B', price: null, isActive: false, ordering: 1 });
    const active = await repo.listActive();
    expect(active.map((p) => p.id)).toEqual(['a']);
    close();
  });
});
