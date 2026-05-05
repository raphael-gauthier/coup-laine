import { describe, it, expect } from 'vitest';
import { computeCommuneAnchor } from '@/domain/use-cases/compute-commune-anchor';

describe('computeCommuneAnchor', () => {
  it('returns the barycentre of all clients in the commune (any status)', () => {
    const r = computeCommuneAnchor('Quimper', [
      { addressCity: 'Quimper', latitude: 48.0, longitude: -4.0 },
      { addressCity: 'Quimper', latitude: 48.2, longitude: -4.2 },
      { addressCity: 'Brest', latitude: 48.4, longitude: -4.5 },
    ]);
    expect(r).toEqual({ lat: 48.1, lon: -4.1 });
  });

  it('skips clients without coordinates', () => {
    const r = computeCommuneAnchor('Quimper', [
      { addressCity: 'Quimper', latitude: null, longitude: -4.0 },
      { addressCity: 'Quimper', latitude: 48.0, longitude: null },
      { addressCity: 'Quimper', latitude: 48.0, longitude: -4.0 },
    ]);
    expect(r).toEqual({ lat: 48.0, lon: -4.0 });
  });

  it('returns null when no client in the commune has coordinates', () => {
    const r = computeCommuneAnchor('Quimper', [
      { addressCity: 'Quimper', latitude: null, longitude: null },
      { addressCity: 'Brest', latitude: 48.0, longitude: -4.0 },
    ]);
    expect(r).toBeNull();
  });
});
