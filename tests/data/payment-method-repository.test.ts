import { createTestDb } from './_helpers/test-db';
import { PaymentMethodRepository } from '@/data/repositories/payment-method-repository';
import { clients, tours, tourStops } from '@/infra/db/schema';

describe('PaymentMethodRepository', () => {
  it('listAll returns the four seeded methods sorted by ordering', async () => {
    const { db, close } = createTestDb();
    const repo = new PaymentMethodRepository(db);
    const all = await repo.listAll();
    expect(all.map((m) => m.id)).toEqual(['pm-cash', 'pm-check', 'pm-transfer', 'pm-card']);
    close();
  });

  it('round-trips a custom method', async () => {
    const { db, close } = createTestDb();
    const repo = new PaymentMethodRepository(db);
    await repo.upsert({
      id: 'pm-custom',
      label: 'Crypto',
      isActive: true,
      archivedAt: null,
      ordering: 99,
    });
    const fetched = await repo.byId('pm-custom');
    expect(fetched?.label).toBe('Crypto');
    close();
  });

  it('listActive filters out archived methods', async () => {
    const { db, close } = createTestDb();
    const repo = new PaymentMethodRepository(db);
    await repo.setArchived('pm-card', '2026-05-05T00:00:00Z');
    const archived = await repo.byId('pm-card');
    await repo.upsert({ ...archived!, isActive: false });
    const active = await repo.listActive();
    expect(active.map((m) => m.id)).not.toContain('pm-card');
    close();
  });

  it('setArchived stamps archivedAt', async () => {
    const { db, close } = createTestDb();
    const repo = new PaymentMethodRepository(db);
    await repo.setArchived('pm-cash', '2026-05-05T10:00:00Z');
    const m = await repo.byId('pm-cash');
    expect(m?.archivedAt).toBe('2026-05-05T10:00:00Z');
    close();
  });

  it('delete throws when the method is referenced by a tour stop', async () => {
    const { db, close } = createTestDb();
    const repo = new PaymentMethodRepository(db);

    // Use drizzle direct inserts (option 1) to set up a referenced row
    // without relying on tour-repository (which becomes payment-aware in Task 4).
    await db.insert(clients).values({
      id: 'c1',
      displayName: 'C',
      phones: '[]',
      animalCounts: '[]',
      createdAt: 'x',
      updatedAt: 'x',
    });
    await db.insert(tours).values({
      id: 't1',
      scheduledDate: '2026-05-01',
      departureTime: '08:00',
      baseLat: 0,
      baseLng: 0,
      status: 'completed',
      createdAt: 'x',
      updatedAt: 'x',
    });
    await db.insert(tourStops).values({
      id: 's1',
      tourId: 't1',
      clientId: 'c1',
      ordering: 0,
      paymentMethodId: 'pm-cash',
      isPaid: 1,
      plannedServices: '[]',
    });

    await expect(repo.delete('pm-cash')).rejects.toThrow(/référenc/i);
    close();
  });

  it('delete succeeds when the method is unreferenced', async () => {
    const { db, close } = createTestDb();
    const repo = new PaymentMethodRepository(db);
    await repo.upsert({ id: 'pm-orphan', label: 'X', isActive: true, archivedAt: null, ordering: 100 });
    await expect(repo.delete('pm-orphan')).resolves.toBeUndefined();
    expect(await repo.byId('pm-orphan')).toBeNull();
    close();
  });
});
