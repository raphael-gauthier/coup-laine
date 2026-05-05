import { db } from './client';
import * as schema from './schema';

/**
 * Drops all rows from every local table inside a single transaction.
 * Used on sign-out to prevent the next account holder on this device from
 * seeing the previous user's data.
 */
export async function wipeLocalDatabase(): Promise<void> {
  await db.transaction(async (tx) => {
    await tx.delete(schema.distanceMatrix);
    await tx.delete(schema.manualHistoryEntries);
    await tx.delete(schema.tourStops);
    await tx.delete(schema.tours);
    await tx.delete(schema.animalCategories);
    await tx.delete(schema.species);
    await tx.delete(schema.services);
    await tx.delete(schema.paymentMethods);
    await tx.delete(schema.clients);
    await tx.delete(schema.settings);
  });
}
