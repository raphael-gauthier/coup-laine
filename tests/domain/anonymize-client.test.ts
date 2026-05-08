import { describe, it, expect } from 'vitest';
import { planAnonymization, ANONYMIZED_DISPLAY_NAME } from '@/domain/use-cases/anonymize-client';
import type { Client } from '@/domain/models/client';

const NOW = '2026-05-06T10:00:00.000Z';

const baseClient: Client = {
  id: 'c1',
  displayName: 'Famille Le Goff',
  phones: ['0612345678'],
  addressLabel: '12 rue de la Mer',
  addressCity: 'Brest',
  addressPostcode: '29200',
  latitude: 48.39,
  longitude: -4.49,
  isWaiting: true,
  isBanned: false,
  needsDistanceRecompute: false,
  lastShearingDate: '2025-06-15',
  animalCounts: [{ categoryId: 'cat1', count: 5 }],
  markerColorHex: '#ff0000',
  anonymizedAt: null,
  manualStatusId: null,
  createdAt: '2025-01-01T00:00:00.000Z',
  updatedAt: '2025-06-15T00:00:00.000Z',
};

describe('planAnonymization', () => {
  it('scrubs identity, address, geoloc, animals; flips waiting/banned off; preserves lastShearingDate and markerColor', () => {
    const plan = planAnonymization(baseClient, [], [], [], NOW);
    expect(plan.client.updates.displayName).toBe(ANONYMIZED_DISPLAY_NAME);
    expect(plan.client.updates.phones).toEqual([]);
    expect(plan.client.updates.addressLabel).toBeNull();
    expect(plan.client.updates.addressCity).toBeNull();
    expect(plan.client.updates.addressPostcode).toBeNull();
    expect(plan.client.updates.latitude).toBeNull();
    expect(plan.client.updates.longitude).toBeNull();
    expect(plan.client.updates.animalCounts).toEqual([]);
    expect(plan.client.updates.isWaiting).toBe(false);
    expect(plan.client.updates.isBanned).toBe(false);
    expect(plan.client.updates.anonymizedAt).toBe(NOW);
    // preserved (no key in updates)
    expect(plan.client.updates.lastShearingDate).toBeUndefined();
    expect(plan.client.updates.markerColorHex).toBeUndefined();
  });

  it('produces empty arrays when no related rows', () => {
    const plan = planAnonymization(baseClient, [], [], [], NOW);
    expect(plan.tourStopUpdates).toEqual([]);
    expect(plan.manualEntryUpdates).toEqual([]);
    expect(plan.distanceMatrixDeletes).toEqual([]);
  });

  it('scrubs clientNameSnapshot and notes on tour stops belonging to the client', () => {
    const stop = { id: 's1', clientId: 'c1' };
    const plan = planAnonymization(baseClient, [stop], [], [], NOW);
    expect(plan.tourStopUpdates).toEqual([
      { id: 's1', clientNameSnapshot: ANONYMIZED_DISPLAY_NAME, notes: null },
    ]);
  });

  it('scrubs notes on manual history entries', () => {
    const entry = { id: 'm1', clientId: 'c1' };
    const plan = planAnonymization(baseClient, [], [entry], [], NOW);
    expect(plan.manualEntryUpdates).toEqual([{ id: 'm1', notes: null }]);
  });

  it('deletes distance_matrix rows touching the client (either side)', () => {
    const dm = [
      { fromId: 'c1', toId: 'base' },
      { fromId: 'base', toId: 'c1' },
      { fromId: 'c2', toId: 'c3' },
    ];
    const plan = planAnonymization(baseClient, [], [], dm, NOW);
    expect(plan.distanceMatrixDeletes).toEqual([
      { fromId: 'c1', toId: 'base' },
      { fromId: 'base', toId: 'c1' },
    ]);
  });

  it('idempotent: returns no-op plan for already-anonymized client', () => {
    const already: Client = { ...baseClient, anonymizedAt: '2026-01-01T00:00:00.000Z' };
    const plan = planAnonymization(already, [], [], [], NOW);
    expect(plan.client.updates).toEqual({});
    expect(plan.tourStopUpdates).toEqual([]);
    expect(plan.manualEntryUpdates).toEqual([]);
    expect(plan.distanceMatrixDeletes).toEqual([]);
  });

  it('only scrubs notes on stops belonging to the client', () => {
    const otherStop = { id: 's2', clientId: 'OTHER' };
    const ourStop = { id: 's1', clientId: 'c1' };
    const plan = planAnonymization(baseClient, [otherStop, ourStop], [], [], NOW);
    expect(plan.tourStopUpdates).toEqual([
      { id: 's1', clientNameSnapshot: ANONYMIZED_DISPLAY_NAME, notes: null },
    ]);
  });
});
