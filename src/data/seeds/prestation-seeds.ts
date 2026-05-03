// src/data/seeds/prestation-seeds.ts
import { sql } from 'drizzle-orm';
import { prestations } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';

const STANDARD_PRESTATIONS = [
  { id: 'shearing-sheep-adult', label: 'Tonte brebis adulte', priceCents: null, minutes: 20, categoryId: 'sheep-adult', isActive: 1, archivedAt: null, ordering: 0 },
  { id: 'shearing-sheep-lamb', label: 'Tonte agneau', priceCents: null, minutes: 15, categoryId: 'sheep-lamb', isActive: 1, archivedAt: null, ordering: 1 },
  { id: 'shearing-goat-adult', label: 'Tonte chèvre', priceCents: null, minutes: 18, categoryId: 'goat-adult', isActive: 1, archivedAt: null, ordering: 2 },
  { id: 'hoof-trimming', label: 'Parage', priceCents: null, minutes: 10, categoryId: null, isActive: 1, archivedAt: null, ordering: 3 },
];

export async function seedPrestationsIfEmpty(db: Db) {
  const result = await db.select({ count: sql<number>`count(*)` }).from(prestations);
  const count = result[0]?.count ?? 0;
  if (count > 0) return;

  for (const p of STANDARD_PRESTATIONS) {
    await db.insert(prestations).values(p);
  }
}
