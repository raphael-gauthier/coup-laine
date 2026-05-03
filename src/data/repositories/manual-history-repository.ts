import { desc, eq } from 'drizzle-orm';
import { manualHistoryEntries } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { ManualHistoryEntry } from '@/domain/models/manual-history-entry';

interface ManualHistoryRow {
  id: string;
  clientId: string;
  date: string;
  notes: string | null;
  prestations: string;
}

function toRow(e: ManualHistoryEntry) {
  return { ...e, prestations: JSON.stringify(e.prestations) };
}
function fromRow(r: ManualHistoryRow): ManualHistoryEntry {
  return ManualHistoryEntry.parse({ ...r, prestations: JSON.parse(r.prestations) });
}

export class ManualHistoryRepository {
  constructor(private readonly db: Db) {}

  async listByClient(clientId: string): Promise<ManualHistoryEntry[]> {
    const rows = await this.db
      .select()
      .from(manualHistoryEntries)
      .where(eq(manualHistoryEntries.clientId, clientId))
      .orderBy(desc(manualHistoryEntries.date));
    return rows.map((r) => fromRow(r as ManualHistoryRow));
  }
  async upsert(e: ManualHistoryEntry): Promise<void> {
    const row = toRow(e);
    await this.db
      .insert(manualHistoryEntries)
      .values(row)
      .onConflictDoUpdate({ target: manualHistoryEntries.id, set: row });
  }
  async delete(id: string): Promise<void> {
    await this.db.delete(manualHistoryEntries).where(eq(manualHistoryEntries.id, id));
  }
}
