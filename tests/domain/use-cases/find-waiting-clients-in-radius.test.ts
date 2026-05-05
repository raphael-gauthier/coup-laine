import { describe, it, expect } from 'vitest';
import { findWaitingClientsInRadius } from '@/domain/use-cases/find-waiting-clients-in-radius';

const ANCHOR = { lat: 48.0, lon: -4.0 };

describe('findWaitingClientsInRadius', () => {
  it('returns clients within radius sorted by distance ascending', () => {
    const r = findWaitingClientsInRadius(
      ANCHOR,
      [
        { id: 'far', latitude: 48.5, longitude: -4.0 },
        { id: 'close', latitude: 48.01, longitude: -4.0 },
        { id: 'mid', latitude: 48.1, longitude: -4.0 },
      ],
      60,
    );
    expect(r.map((c) => c.id)).toEqual(['close', 'mid', 'far']);
    expect(r[0]!.distanceKm).toBeLessThan(r[1]!.distanceKm);
  });

  it('excludes clients beyond radiusKm', () => {
    const r = findWaitingClientsInRadius(
      ANCHOR,
      [
        { id: 'inside', latitude: 48.05, longitude: -4.0 },
        { id: 'outside', latitude: 49.0, longitude: -4.0 },
      ],
      20,
    );
    expect(r.map((c) => c.id)).toEqual(['inside']);
  });

  it('skips clients without coordinates', () => {
    const r = findWaitingClientsInRadius(
      ANCHOR,
      [
        { id: 'no-lat', latitude: null, longitude: -4.0 },
        { id: 'no-lon', latitude: 48.0, longitude: null },
        { id: 'ok', latitude: 48.0, longitude: -4.0 },
      ],
      50,
    );
    expect(r.map((c) => c.id)).toEqual(['ok']);
  });
});
