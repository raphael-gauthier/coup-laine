import { asc, eq, isNull, isNotNull } from 'drizzle-orm';
import { species } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { Species } from '@/domain/models/species';

interface SpeciesRow {
  id: string;
  label: string;
  iconKey: string | null;
  ordering: number;
  isCustom: number;
  archivedAt: string | null;
}

function toRow(s: Species) {
  return { ...s, isCustom: s.isCustom ? 1 : 0 };
}
function fromRow(r: SpeciesRow): Species {
  return Species.parse({ ...r, isCustom: r.isCustom === 1 });
}

export class SpeciesRepository {
  constructor(private readonly db: Db) {}

  async byId(id: string): Promise<Species | null> {
    const rows = await this.db.select().from(species).where(eq(species.id, id));
    return rows[0] ? fromRow(rows[0] as SpeciesRow) : null;
  }
  async listAll(): Promise<Species[]> {
    const rows = await this.db.select().from(species).orderBy(asc(species.ordering));
    return rows.map((r) => fromRow(r as SpeciesRow));
  }
  async listActive(): Promise<Species[]> {
    const rows = await this.db
      .select()
      .from(species)
      .where(isNull(species.archivedAt))
      .orderBy(asc(species.ordering));
    return rows.map((r) => fromRow(r as SpeciesRow));
  }
  async listArchived(): Promise<Species[]> {
    const rows = await this.db
      .select()
      .from(species)
      .where(isNotNull(species.archivedAt))
      .orderBy(asc(species.ordering));
    return rows.map((r) => fromRow(r as SpeciesRow));
  }
  async upsert(s: Species): Promise<void> {
    const row = toRow(s);
    await this.db.insert(species).values(row).onConflictDoUpdate({ target: species.id, set: row });
  }
  async delete(id: string): Promise<void> {
    await this.db.delete(species).where(eq(species.id, id));
  }
}
