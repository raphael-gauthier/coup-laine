// src/data/seeds/prestation-seeds.ts
import { sql } from 'drizzle-orm';
import { prestations } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';

const STANDARD_PRESTATIONS = [
  { id: 'shearing', label: 'Tonte', price: null, isActive: 1, ordering: 0 },
  { id: 'hoof-trimming', label: 'Parage', price: null, isActive: 1, ordering: 1 },
];

export async function seedPrestationsIfEmpty(db: Db) {
  const result = await db.select({ count: sql<number>`count(*)` }).from(prestations);
  const count = result[0]?.count ?? 0;
  if (count > 0) return;

  for (const p of STANDARD_PRESTATIONS) {
    await db.insert(prestations).values(p);
  }
}
