import { asc, eq } from 'drizzle-orm';
import { prestations } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { Prestation } from '@/domain/models/prestation';

interface PrestationRow {
  id: string;
  label: string;
  price: number | null;
  isActive: number;
  ordering: number;
}

function toRow(p: Prestation) { return { ...p, isActive: p.isActive ? 1 : 0 }; }
function fromRow(r: PrestationRow): Prestation {
  return Prestation.parse({ ...r, isActive: r.isActive === 1 });
}

export class PrestationRepository {
  constructor(private readonly db: Db) {}

  async listAll(): Promise<Prestation[]> {
    const rows = await this.db.select().from(prestations).orderBy(asc(prestations.ordering));
    return rows.map((r) => fromRow(r as PrestationRow));
  }
  async listActive(): Promise<Prestation[]> {
    const rows = await this.db
      .select()
      .from(prestations)
      .where(eq(prestations.isActive, 1))
      .orderBy(asc(prestations.ordering));
    return rows.map((r) => fromRow(r as PrestationRow));
  }
  async upsert(p: Prestation): Promise<void> {
    const row = toRow(p);
    await this.db.insert(prestations).values(row).onConflictDoUpdate({ target: prestations.id, set: row });
  }
  async delete(id: string): Promise<void> {
    await this.db.delete(prestations).where(eq(prestations.id, id));
  }
}
