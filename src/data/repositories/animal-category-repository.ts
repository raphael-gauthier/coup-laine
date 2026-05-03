import { asc, eq } from 'drizzle-orm';
import { animalCategories } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { AnimalCategory } from '@/domain/models/animal-category';

interface AnimalCategoryRow {
  id: string;
  speciesId: string;
  label: string;
  ordering: number;
  isCustom: number;
  archivedAt: string | null;
}

function toRow(c: AnimalCategory) { return { ...c, isCustom: c.isCustom ? 1 : 0 }; }
function fromRow(r: AnimalCategoryRow): AnimalCategory {
  return AnimalCategory.parse({ ...r, isCustom: r.isCustom === 1 });
}

export class AnimalCategoryRepository {
  constructor(private readonly db: Db) {}

  async byId(id: string): Promise<AnimalCategory | null> {
    const rows = await this.db.select().from(animalCategories).where(eq(animalCategories.id, id));
    return rows[0] ? fromRow(rows[0] as AnimalCategoryRow) : null;
  }
  async listAll(): Promise<AnimalCategory[]> {
    const rows = await this.db.select().from(animalCategories).orderBy(asc(animalCategories.ordering));
    return rows.map((r) => fromRow(r as AnimalCategoryRow));
  }
  async listBySpecies(speciesId: string): Promise<AnimalCategory[]> {
    const rows = await this.db
      .select()
      .from(animalCategories)
      .where(eq(animalCategories.speciesId, speciesId))
      .orderBy(asc(animalCategories.ordering));
    return rows.map((r) => fromRow(r as AnimalCategoryRow));
  }
  async upsert(c: AnimalCategory): Promise<void> {
    const row = toRow(c);
    await this.db
      .insert(animalCategories)
      .values(row)
      .onConflictDoUpdate({ target: animalCategories.id, set: row });
  }
  async delete(id: string): Promise<void> {
    await this.db.delete(animalCategories).where(eq(animalCategories.id, id));
  }
}
