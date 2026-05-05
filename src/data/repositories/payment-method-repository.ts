import { asc, eq } from 'drizzle-orm';
import { paymentMethods, tourStops, manualHistoryEntries } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { PaymentMethod } from '@/domain/models/payment-method';

interface PaymentMethodRow {
  id: string;
  label: string;
  isActive: number;
  archivedAt: string | null;
  ordering: number;
}

function toRow(m: PaymentMethod) {
  return { ...m, isActive: m.isActive ? 1 : 0 };
}
function fromRow(r: PaymentMethodRow): PaymentMethod {
  return PaymentMethod.parse({ ...r, isActive: r.isActive === 1 });
}

export class PaymentMethodRepository {
  constructor(private readonly db: Db) {}

  async byId(id: string): Promise<PaymentMethod | null> {
    const rows = await this.db.select().from(paymentMethods).where(eq(paymentMethods.id, id));
    return rows[0] ? fromRow(rows[0] as PaymentMethodRow) : null;
  }

  async listAll(): Promise<PaymentMethod[]> {
    const rows = await this.db.select().from(paymentMethods).orderBy(asc(paymentMethods.ordering));
    return rows.map((r) => fromRow(r as PaymentMethodRow));
  }

  async listActive(): Promise<PaymentMethod[]> {
    const rows = await this.db
      .select()
      .from(paymentMethods)
      .where(eq(paymentMethods.isActive, 1))
      .orderBy(asc(paymentMethods.ordering));
    return rows.map((r) => fromRow(r as PaymentMethodRow));
  }

  async upsert(m: PaymentMethod): Promise<void> {
    const row = toRow(m);
    await this.db
      .insert(paymentMethods)
      .values(row)
      .onConflictDoUpdate({ target: paymentMethods.id, set: row });
  }

  async setArchived(id: string, archivedAt: string | null): Promise<void> {
    await this.db.update(paymentMethods).set({ archivedAt }).where(eq(paymentMethods.id, id));
  }

  async delete(id: string): Promise<void> {
    const stopRefs = await this.db
      .select({ id: tourStops.id })
      .from(tourStops)
      .where(eq(tourStops.paymentMethodId, id))
      .limit(1);
    const entryRefs = await this.db
      .select({ id: manualHistoryEntries.id })
      .from(manualHistoryEntries)
      .where(eq(manualHistoryEntries.paymentMethodId, id))
      .limit(1);
    if (stopRefs.length > 0 || entryRefs.length > 0) {
      throw new Error('Méthode de paiement référencée par un paiement existant.');
    }
    await this.db.delete(paymentMethods).where(eq(paymentMethods.id, id));
  }
}
