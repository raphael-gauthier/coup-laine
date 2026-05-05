import { desc, eq } from 'drizzle-orm';
import { manualHistoryEntries } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { ManualHistoryEntry } from '@/domain/models/manual-history-entry';
import { Payment } from '@/domain/models/payment';

interface ManualHistoryRow {
  id: string;
  clientId: string;
  date: string;
  notes: string | null;
  services: string;
  paymentMethodId: string | null;
  paymentMethodLabelSnapshot: string | null;
  isPaid: number;
  paidAt: string | null;
}

function toRow(e: ManualHistoryEntry) {
  return {
    id: e.id,
    clientId: e.clientId,
    date: e.date,
    notes: e.notes,
    services: JSON.stringify(e.services),
    paymentMethodId: e.payment.methodId,
    paymentMethodLabelSnapshot: e.payment.methodLabelSnapshot,
    isPaid: e.payment.isPaid ? 1 : 0,
    paidAt: e.payment.paidAt,
  };
}

function fromRow(r: ManualHistoryRow): ManualHistoryEntry {
  return ManualHistoryEntry.parse({
    id: r.id,
    clientId: r.clientId,
    date: r.date,
    notes: r.notes,
    services: JSON.parse(r.services),
    payment: {
      methodId: r.paymentMethodId,
      methodLabelSnapshot: r.paymentMethodLabelSnapshot,
      isPaid: r.isPaid === 1,
      paidAt: r.paidAt,
    },
  });
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

  async markEntryPayment(entryId: string, payment: Payment): Promise<void> {
    await this.db.update(manualHistoryEntries).set({
      paymentMethodId: payment.methodId,
      paymentMethodLabelSnapshot: payment.methodLabelSnapshot,
      isPaid: payment.isPaid ? 1 : 0,
      paidAt: payment.paidAt,
    }).where(eq(manualHistoryEntries.id, entryId));
  }

  async delete(id: string): Promise<void> {
    await this.db.delete(manualHistoryEntries).where(eq(manualHistoryEntries.id, id));
  }
}
