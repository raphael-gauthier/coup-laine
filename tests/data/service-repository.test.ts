import { createTestDb } from './_helpers/test-db';
import { SpeciesRepository } from '@/data/repositories/species-repository';
import { AnimalCategoryRepository } from '@/data/repositories/animal-category-repository';
import { ServiceRepository } from '@/data/repositories/service-repository';

const base = {
  priceCents: null,
  minutes: 20,
  categoryId: null,
  isActive: true,
  archivedAt: null,
};

describe('ServiceRepository', () => {
  it('round-trips a service', async () => {
    const { db, close } = createTestDb();
    const repo = new ServiceRepository(db);
    const p = { id: 'shearing', label: 'Tonte', ordering: 0, ...base };
    await repo.upsert(p);
    const all = await repo.listAll();
    expect(all).toContainEqual(p);
    close();
  });

  it('listActive filters out inactive', async () => {
    const { db, close } = createTestDb();
    const repo = new ServiceRepository(db);
    await repo.upsert({ id: 'a', label: 'A', ordering: 0, ...base });
    await repo.upsert({ id: 'b', label: 'B', ordering: 1, ...base, isActive: false });
    const active = await repo.listActive();
    expect(active.map((p) => p.id)).toEqual(['a']);
    close();
  });

  it('listByCategoryId filters and listLibre returns category-less services', async () => {
    const { db, close } = createTestDb();
    const sRepo = new SpeciesRepository(db);
    const cRepo = new AnimalCategoryRepository(db);
    const repo = new ServiceRepository(db);
    await sRepo.upsert({ id: 'sheep', label: 'Mouton', iconKey: null, ordering: 0, isCustom: false, archivedAt: null });
    await cRepo.upsert({ id: 'sheep-adult', speciesId: 'sheep', label: 'Adulte', ordering: 0, isCustom: false, archivedAt: null });
    await repo.upsert({ id: 'a', label: 'Tonte adulte', ordering: 0, ...base, categoryId: 'sheep-adult' });
    await repo.upsert({ id: 'b', label: 'Parage', ordering: 1, ...base });

    expect((await repo.listByCategoryId('sheep-adult')).map((p) => p.id)).toEqual(['a']);
    expect((await repo.listLibre()).map((p) => p.id)).toEqual(['b']);
    close();
  });

  it('setArchived stamps archivedAt', async () => {
    const { db, close } = createTestDb();
    const repo = new ServiceRepository(db);
    await repo.upsert({ id: 'a', label: 'A', ordering: 0, ...base });
    await repo.setArchived('a', '2026-05-01T00:00:00Z');
    expect((await repo.byId('a'))!.archivedAt).toBe('2026-05-01T00:00:00Z');
    close();
  });
});
