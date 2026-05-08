import { createTestDb } from './_helpers/test-db';
import { ClientRepository } from '@/data/repositories/client-repository';
import { StatusRepository } from '@/data/repositories/status-repository';
import { Client } from '@/domain/models/client';

const newClient = (id: string) =>
  Client.parse({
    id,
    displayName: id,
    phones: [],
    addressLabel: null,
    addressCity: null,
    addressPostcode: null,
    latitude: null,
    longitude: null,
    isWaiting: false,
    isBanned: false,
    needsDistanceRecompute: false,
    lastShearingDate: null,
    animalCounts: [],
    markerColorHex: null,
    anonymizedAt: null,
    manualStatusId: null,
    createdAt: '2026-05-08T00:00:00Z',
    updatedAt: '2026-05-08T00:00:00Z',
  });

describe('ClientRepository × manual status', () => {
  it('setManualStatus sets and clears', async () => {
    const { db, close } = createTestDb();
    const clients = new ClientRepository(db);
    const statuses = new StatusRepository(db);
    try {
      await clients.upsert(newClient('c1'));
      const m = await statuses.createManual({
        label: 'X',
        colorLight: '#000000',
        colorDark: '#FFFFFF',
      });
      await clients.setManualStatus('c1', m.id, '2026-05-08T01:00:00Z');
      let c = await clients.byId('c1');
      expect(c?.manualStatusId).toBe(m.id);
      await clients.setManualStatus('c1', null, '2026-05-08T02:00:00Z');
      c = await clients.byId('c1');
      expect(c?.manualStatusId).toBeNull();
    } finally {
      close();
    }
  });

  it('FK ON DELETE SET NULL clears manualStatusId when status deleted', async () => {
    const { db, close } = createTestDb();
    const clients = new ClientRepository(db);
    const statuses = new StatusRepository(db);
    try {
      await clients.upsert(newClient('c2'));
      const m = await statuses.createManual({
        label: 'Y',
        colorLight: '#000000',
        colorDark: '#FFFFFF',
      });
      await clients.setManualStatus('c2', m.id, '2026-05-08T01:00:00Z');
      await statuses.deleteManual(m.id);
      const c = await clients.byId('c2');
      expect(c?.manualStatusId).toBeNull();
    } finally {
      close();
    }
  });
});
