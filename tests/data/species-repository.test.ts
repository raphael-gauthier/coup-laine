import { createTestDb } from './_helpers/test-db';
import { SpeciesRepository } from '@/data/repositories/species-repository';

const sheep = { id: 'sheep', label: 'Mouton', color: '#A1602F', ordering: 0, isCustom: false };

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
});
