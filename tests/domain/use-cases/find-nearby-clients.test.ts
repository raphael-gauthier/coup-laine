import { describe, it, expect } from 'vitest';
import { findNearbyClients } from '@/domain/use-cases/find-nearby-clients';

const pivot = { id: 'p', lat: 48.0, lon: -3.0 };
const within10km = { id: 'c1', lat: 48.05, lon: -3.0 };
const within20km = { id: 'c2', lat: 48.15, lon: -3.0 };
const within40km = { id: 'c3', lat: 48.3, lon: -3.0 };
const noCoords = { id: 'c4', lat: null, lon: null };

describe('findNearbyClients', () => {
  it('returns only clients within the radius (excluding the pivot)', () => {
    const r = findNearbyClients({
      pivot,
      radiusKm: 20,
      clients: [pivot, within10km, within20km, within40km, noCoords],
    });
    expect(r.map((c) => c.id)).toEqual(['c1', 'c2']);
  });

  it('sorts by distance ascending', () => {
    const r = findNearbyClients({
      pivot,
      radiusKm: 50,
      clients: [within40km, within10km, within20km],
    });
    expect(r.map((c) => c.id)).toEqual(['c1', 'c2', 'c3']);
  });

  it('skips clients without coordinates', () => {
    const r = findNearbyClients({ pivot, radiusKm: 50, clients: [noCoords] });
    expect(r).toEqual([]);
  });

  it('throws for non-positive radius', () => {
    expect(() => findNearbyClients({ pivot, radiusKm: 0, clients: [] })).toThrow();
  });

  it('uses caller-supplied distanceKm when provided', () => {
    const r = findNearbyClients({
      pivot,
      radiusKm: 20,
      clients: [within10km, within40km],
      distanceKm: (_from, to) => (to === 'c1' ? 5 : 50),
    });
    expect(r.map((c) => c.id)).toEqual(['c1']);
    expect(r[0]?.isEstimate).toBe(false);
  });

  it('falls back to haversine when distanceKm returns null', () => {
    const r = findNearbyClients({
      pivot,
      radiusKm: 50,
      clients: [within10km],
      distanceKm: () => null,
    });
    expect(r.length).toBe(1);
    expect(r[0]?.isEstimate).toBe(true);
  });

  it('marks haversine results as isEstimate=true when no distanceKm provided', () => {
    const r = findNearbyClients({
      pivot,
      radiusKm: 50,
      clients: [within10km],
    });
    expect(r[0]?.isEstimate).toBe(true);
  });
});
