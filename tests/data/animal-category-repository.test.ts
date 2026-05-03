import { createTestDb } from './_helpers/test-db';
import { SpeciesRepository } from '@/data/repositories/species-repository';
import { AnimalCategoryRepository } from '@/data/repositories/animal-category-repository';

describe('AnimalCategoryRepository', () => {
  it('lists categories by species', async () => {
    const { db, close } = createTestDb();
    const sRepo = new SpeciesRepository(db);
    const cRepo = new AnimalCategoryRepository(db);
    await sRepo.upsert({ id: 'sheep', label: 'Mouton', color: null, ordering: 0, isCustom: false });
    await cRepo.upsert({
      id: 'sheep-adult', speciesId: 'sheep', label: 'Brebis adulte',
      averageMinutesPerUnit: 20, ordering: 0, isCustom: false,
    });
    const cats = await cRepo.listBySpecies('sheep');
    expect(cats).toHaveLength(1);
    expect(cats[0]!.id).toBe('sheep-adult');
    close();
  });
});
