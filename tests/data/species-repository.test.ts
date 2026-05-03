import { createTestDb } from './_helpers/test-db';
import { SpeciesRepository } from '@/data/repositories/species-repository';

const sheep = {
  id: 'sheep',
  label: 'Mouton',
  iconKey: 'mouton',
  ordering: 0,
  isCustom: false,
  archivedAt: null,
};

describe('SpeciesRepository', () => {
  it('round-trips a species', async () => {
    const { db, close } = createTestDb();
    const repo = new SpeciesRepository(db);
    await repo.upsert(sheep);
    const all = await repo.listAll();
    expect(all).toContainEqual(sheep);
    close();
  });

  it('byId returns null when missing', async () => {
    const { db, close } = createTestDb();
    const repo = new SpeciesRepository(db);
    expect(await repo.byId('missing')).toBeNull();
    close();
  });

  it('listActive excludes archived species', async () => {
    const { db, close } = createTestDb();
    const repo = new SpeciesRepository(db);
    await repo.upsert(sheep);
    await repo.upsert({ ...sheep, id: 'goat', label: 'Chèvre', archivedAt: '2026-05-01T00:00:00Z' });
    const active = await repo.listActive();
    expect(active.map((s) => s.id)).toEqual(['sheep']);
    close();
  });
});
