// src/data/seeds/species-seeds.ts
import { sql } from 'drizzle-orm';
import { species, animalCategories } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';

const STANDARD_SPECIES = [
  {
    id: 'sheep',
    label: 'Mouton',
    color: '#A1602F',
    ordering: 0,
    isCustom: 0,
    categories: [
      { id: 'sheep-adult', label: 'Brebis adulte', averageMinutesPerUnit: 20, ordering: 0 },
      { id: 'sheep-lamb', label: 'Agneau', averageMinutesPerUnit: 15, ordering: 1 },
    ],
  },
  {
    id: 'goat',
    label: 'Chèvre',
    color: '#5C7548',
    ordering: 1,
    isCustom: 0,
    categories: [
      { id: 'goat-adult', label: 'Chèvre adulte', averageMinutesPerUnit: 18, ordering: 0 },
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
      color: s.color,
      ordering: s.ordering,
      isCustom: s.isCustom,
    });
    for (const c of s.categories) {
      await db.insert(animalCategories).values({
        id: c.id,
        speciesId: s.id,
        label: c.label,
        averageMinutesPerUnit: c.averageMinutesPerUnit,
        ordering: c.ordering,
        isCustom: 0,
      });
    }
  }
}
