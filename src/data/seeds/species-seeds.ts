// src/data/seeds/species-seeds.ts
import { sql } from 'drizzle-orm';
import { species, animalCategories } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';

const STANDARD_SPECIES = [
  {
    id: 'sheep',
    label: 'Mouton',
    iconKey: 'mouton',
    ordering: 0,
    isCustom: 0,
    categories: [
      { id: 'sheep-adult', label: 'Brebis adulte', ordering: 0 },
      { id: 'sheep-lamb', label: 'Agneau', ordering: 1 },
    ],
  },
  {
    id: 'goat',
    label: 'Chèvre',
    iconKey: 'caprin',
    ordering: 1,
    isCustom: 0,
    categories: [
      { id: 'goat-adult', label: 'Chèvre adulte', ordering: 0 },
    ],
  },
];

export async function seedSpeciesIfEmpty(db: Db) {
  const result = await db.select({ count: sql<number>`count(*)` }).from(species);
  const count = result[0]?.count ?? 0;
  if (count > 0) return;

  for (const s of STANDARD_SPECIES) {
    await db.insert(species).values({
      id: s.id,
      label: s.label,
      iconKey: s.iconKey,
      ordering: s.ordering,
      isCustom: s.isCustom,
      archivedAt: null,
    });
    for (const c of s.categories) {
      await db.insert(animalCategories).values({
        id: c.id,
        speciesId: s.id,
        label: c.label,
        ordering: c.ordering,
        isCustom: 0,
        archivedAt: null,
      });
    }
  }
}
