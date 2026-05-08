import { asc, eq } from 'drizzle-orm';
import { statuses, clients } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { Status, type SystemStatusKey } from '@/domain/models/status';
import { newId } from '@/lib/id';

interface StatusRow {
  id: string;
  kind: string;
  systemKey: string | null;
  label: string;
  colorLight: string;
  colorDark: string;
  sortOrder: number;
  createdAt: string;
}

function fromRow(r: StatusRow): Status {
  return Status.parse(r);
}

export class StatusRepository {
  constructor(private readonly db: Db) {}

  async list(): Promise<Status[]> {
    const rows = await this.db.select().from(statuses).orderBy(asc(statuses.sortOrder));
    return rows.map((r) => fromRow(r as StatusRow));
  }

  async byId(id: string): Promise<Status | null> {
    const rows = await this.db.select().from(statuses).where(eq(statuses.id, id));
    return rows[0] ? fromRow(rows[0] as StatusRow) : null;
  }

  async bySystemKey(key: SystemStatusKey): Promise<Status> {
    const rows = await this.db.select().from(statuses).where(eq(statuses.systemKey, key));
    if (!rows[0]) throw new Error(`System status row missing for key: ${key}`);
    return fromRow(rows[0] as StatusRow);
  }

  async createManual(input: {
    label: string;
    colorLight: string;
    colorDark: string;
  }): Promise<Status> {
    const all = await this.db.select({ s: statuses.sortOrder }).from(statuses);
    const maxOrder = all.reduce((acc, r) => Math.max(acc, r.s), 0);
    const row = {
      id: newId(),
      kind: 'manual' as const,
      systemKey: null,
      label: input.label,
      colorLight: input.colorLight,
      colorDark: input.colorDark,
      sortOrder: maxOrder + 10,
      createdAt: new Date().toISOString(),
    };
    await this.db.insert(statuses).values(row);
    return Status.parse(row);
  }

  async update(
    id: string,
    patch: { label?: string; colorLight?: string; colorDark?: string; sortOrder?: number }
  ): Promise<Status> {
    await this.db.update(statuses).set(patch).where(eq(statuses.id, id));
    const after = await this.byId(id);
    if (!after) throw new Error(`Status disappeared after update: ${id}`);
    return after;
  }

  async deleteManual(id: string): Promise<void> {
    const row = await this.byId(id);
    if (!row) return;
    if (row.kind !== 'manual') {
      throw new Error(`Cannot delete a system status: ${id}`);
    }
    await this.db.delete(statuses).where(eq(statuses.id, id));
  }

  async countClientsUsing(id: string): Promise<number> {
    const rows = await this.db
      .select({ id: clients.id })
      .from(clients)
      .where(eq(clients.manualStatusId, id));
    return rows.length;
  }
}
