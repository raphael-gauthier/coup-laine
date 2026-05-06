import { eq } from 'drizzle-orm';
import { createTestDb } from './_helpers/test-db';
import * as schema from '@/infra/db/schema';
import { ClientRepository } from '@/data/repositories/client-repository';
import { ANONYMIZED_DISPLAY_NAME } from '@/domain/use-cases/anonymize-client';

const NOW = '2026-05-06T10:00:00.000Z';

function newClient(id: string, overrides: Partial<{ displayName: string; isWaiting: boolean }> = {}) {
  return {
    id,
    displayName: overrides.displayName ?? `Client ${id}`,
    phones: ['0612345678'],
    addressLabel: '12 rue',
    addressCity: 'Brest',
    addressPostcode: '29200',
    latitude: 48.39,
    longitude: -4.49,
    isWaiting: overrides.isWaiting ?? true,
    isBanned: false,
    needsDistanceRecompute: false,
    lastShearingDate: '2025-06-15',
    animalCounts: [{ categoryId: 'cat1', count: 5 }],
    markerColorHex: '#ff0000',
    anonymizedAt: null,
    createdAt: NOW,
    updatedAt: NOW,
  };
}

describe('ClientRepository.anonymize', () => {
  it('scrubs identity columns and stamps anonymizedAt', async () => {
    const { db, close } = createTestDb();
    try {
      const repo = new ClientRepository(db);
      await repo.upsert(newClient('c1'));
      await repo.anonymize('c1', NOW);
      const after = await repo.byId('c1');
      expect(after?.displayName).toBe(ANONYMIZED_DISPLAY_NAME);
      expect(after?.phones).toEqual([]);
      expect(after?.addressLabel).toBeNull();
      expect(after?.addressCity).toBeNull();
      expect(after?.addressPostcode).toBeNull();
      expect(after?.latitude).toBeNull();
      expect(after?.longitude).toBeNull();
      expect(after?.animalCounts).toEqual([]);
      expect(after?.isWaiting).toBe(false);
      expect(after?.anonymizedAt).toBe(NOW);
      // preserved
      expect(after?.lastShearingDate).toBe('2025-06-15');
      expect(after?.markerColorHex).toBe('#ff0000');
    } finally { close(); }
  });

  it('scrubs clientNameSnapshot and notes on tour_stops belonging to the client; preserves money/payment fields', async () => {
    const { db, close } = createTestDb();
    try {
      const repo = new ClientRepository(db);
      await repo.upsert(newClient('c1'));
      // Insert a tour + a stop directly via Drizzle.
      await db.insert(schema.tours).values({
        id: 't1', scheduledDate: '2025-06-15', departureTime: '08:00',
        baseLat: 48.0, baseLng: 2.0, status: 'completed',
        createdAt: NOW, updatedAt: NOW,
      });
      await db.insert(schema.tourStops).values({
        id: 's1', tourId: 't1', clientId: 'c1', clientNameSnapshot: 'Famille',
        ordering: 0, travelFeeCents: 800,
        plannedServices: '[]', actualServices: '[]',
        notes: 'porte rouge', completedAt: NOW, isPaid: 1, paidAt: NOW,
      });

      await repo.anonymize('c1', NOW);
      const stops = await db.select().from(schema.tourStops).where(eq(schema.tourStops.id, 's1'));
      const stop = stops[0];
      expect(stop?.clientNameSnapshot).toBe(ANONYMIZED_DISPLAY_NAME);
      expect(stop?.notes).toBeNull();
      expect(stop?.travelFeeCents).toBe(800);
      expect(stop?.isPaid).toBe(1);
      expect(stop?.paidAt).toBe(NOW);
    } finally { close(); }
  });

  it('hides anonymized clients from listAll and listWaiting; byId still returns them', async () => {
    const { db, close } = createTestDb();
    try {
      const repo = new ClientRepository(db);
      await repo.upsert(newClient('c1', { displayName: 'A', isWaiting: true }));
      await repo.upsert(newClient('c2', { displayName: 'B', isWaiting: true }));
      await repo.anonymize('c1', NOW);

      const all = await repo.listAll();
      expect(all.map((c) => c.id)).toEqual(['c2']);

      const waiting = await repo.listWaiting();
      expect(waiting.map((c) => c.id)).toEqual(['c2']);

      // byId still returns the anonymized client (used by detail screen for redirect).
      const c1 = await repo.byId('c1');
      expect(c1).not.toBeNull();
      expect(c1?.anonymizedAt).toBe(NOW);
    } finally { close(); }
  });

  it('idempotent: anonymizing twice keeps the original anonymizedAt timestamp', async () => {
    const { db, close } = createTestDb();
    try {
      const repo = new ClientRepository(db);
      await repo.upsert(newClient('c1'));
      const FIRST = '2026-05-06T10:00:00.000Z';
      const SECOND = '2026-06-01T10:00:00.000Z';
      await repo.anonymize('c1', FIRST);
      await repo.anonymize('c1', SECOND);
      const after = await repo.byId('c1');
      expect(after?.anonymizedAt).toBe(FIRST);  // not overwritten
    } finally { close(); }
  });
});
