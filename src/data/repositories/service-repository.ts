import { asc, eq, isNull } from 'drizzle-orm';
import { services } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { Service } from '@/domain/models/service';

interface ServiceRow {
  id: string;
  label: string;
  priceCents: number | null;
  minutes: number;
  categoryId: string | null;
  isActive: number;
  archivedAt: string | null;
  ordering: number;
}

function toRow(p: Service) { return { ...p, isActive: p.isActive ? 1 : 0 }; }
function fromRow(r: ServiceRow): Service {
  return Service.parse({ ...r, isActive: r.isActive === 1 });
}

export class ServiceRepository {
  constructor(private readonly db: Db) {}

  async byId(id: string): Promise<Service | null> {
    const rows = await this.db.select().from(services).where(eq(services.id, id));
    return rows[0] ? fromRow(rows[0] as ServiceRow) : null;
  }
  async listAll(): Promise<Service[]> {
    const rows = await this.db.select().from(services).orderBy(asc(services.ordering));
    return rows.map((r) => fromRow(r as ServiceRow));
  }
  async listActive(): Promise<Service[]> {
    const rows = await this.db
      .select()
      .from(services)
      .where(eq(services.isActive, 1))
      .orderBy(asc(services.ordering));
    return rows.map((r) => fromRow(r as ServiceRow));
  }
  async listByCategoryId(categoryId: string | null): Promise<Service[]> {
    const rows = await this.db
      .select()
      .from(services)
      .where(categoryId === null ? isNull(services.categoryId) : eq(services.categoryId, categoryId))
      .orderBy(asc(services.ordering));
    return rows.map((r) => fromRow(r as ServiceRow));
  }
  async listLibre(): Promise<Service[]> {
    return this.listByCategoryId(null);
  }
  async upsert(p: Service): Promise<void> {
    const row = toRow(p);
    await this.db.insert(services).values(row).onConflictDoUpdate({ target: services.id, set: row });
  }
  async setArchived(id: string, archivedAt: string | null): Promise<void> {
    await this.db.update(services).set({ archivedAt }).where(eq(services.id, id));
  }
  async delete(id: string): Promise<void> {
    await this.db.delete(services).where(eq(services.id, id));
  }
}
