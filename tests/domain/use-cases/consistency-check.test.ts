import { describe, it, expect } from 'vitest';
import { findClientsNeedingRecompute } from '@/domain/use-cases/consistency-check';

describe('findClientsNeedingRecompute', () => {
  it('returns clients with no BASE→client matrix entry', () => {
    const r = findClientsNeedingRecompute({
      clients: [
        { id: 'c1', latitude: 48, longitude: -3 },
        { id: 'c2', latitude: 48.1, longitude: -3.1 },
      ],
      matrixPairs: new Set(['BASE-c1', 'c1-BASE']), // c2 missing
    });
    expect(r).toEqual(['c2']);
  });

  it('skips clients without coordinates', () => {
    const r = findClientsNeedingRecompute({
      clients: [{ id: 'c1', latitude: null, longitude: null }],
      matrixPairs: new Set(),
    });
    expect(r).toEqual([]);
  });

  it('returns empty when all clients have matrix rows', () => {
    const r = findClientsNeedingRecompute({
      clients: [{ id: 'c1', latitude: 48, longitude: -3 }],
      matrixPairs: new Set(['BASE-c1', 'c1-BASE']),
    });
    expect(r).toEqual([]);
  });
});
