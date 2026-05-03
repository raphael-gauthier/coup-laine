import { createTestDb } from './_helpers/test-db';
import { SpeciesRepository } from '@/data/repositories/species-repository';
import { AnimalCategoryRepository } from '@/data/repositories/animal-category-repository';

describe('AnimalCategoryRepository', () => {
  it('lists categories by species', async () => {
    const { db, close } = createTestDb();
    const sRepo = new SpeciesRepository(db);
    const cRepo = new AnimalCategoryRepository(db);
    await sRepo.upsert({
      id: 'sheep',
      label: 'Mouton',
      iconKey: null,
      ordering: 0,
      isCustom: false,
      archivedAt: null,
    });
    await cRepo.upsert({
      id: 'sheep-adult',
      speciesId: 'sheep',
      label: 'Brebis adulte',
      ordering: 0,
      isCustom: false,
      archivedAt: null,
    });
    const cats = await cRepo.listBySpecies('sheep');
    expect(cats).toHaveLength(1);
    expect(cats[0]!.id).toBe('sheep-adult');
    close();
  });
});
