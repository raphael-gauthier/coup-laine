import { describe, it, expect } from 'vitest';
import { findClientsNearAnchors } from '@/domain/use-cases/find-clients-near-anchors';

const anchorA = { id: 'a', lat: 48.0, lon: -3.0 };
const anchorB = { id: 'b', lat: 48.5, lon: -3.0 };

describe('findClientsNearAnchors', () => {
  it('includes clients close to any anchor', () => {
    const c1 = { id: 'c1', lat: 48.05, lon: -3.0 };
    const c2 = { id: 'c2', lat: 48.45, lon: -3.0 };
    const c3 = { id: 'c3', lat: 49.0, lon: -3.0 };

    const r = findClientsNearAnchors({
      anchors: [anchorA, anchorB],
      radiusKm: 10,
      clients: [c1, c2, c3],
    });
    expect(r.map((c) => c.id).sort()).toEqual(['c1', 'c2']);
  });

  it('excludes anchor IDs themselves', () => {
    const r = findClientsNearAnchors({
      anchors: [anchorA, anchorB],
      radiusKm: 100,
      clients: [anchorA, anchorB, { id: 'c1', lat: 48.05, lon: -3.0 }],
    });
    expect(r.map((c) => c.id)).toEqual(['c1']);
  });

  it('sorts by minimum distance to any anchor', () => {
    const c1 = { id: 'c1', lat: 48.4, lon: -3.0 };
    const c2 = { id: 'c2', lat: 48.06, lon: -3.0 };

    const r = findClientsNearAnchors({
      anchors: [anchorA, anchorB],
      radiusKm: 50,
      clients: [c1, c2],
    });
    expect(r.map((c) => c.id)).toEqual(['c2', 'c1']);
  });

  it('uses caller-supplied distanceKm when provided', () => {
    const c1 = { id: 'c1', lat: 48.05, lon: -3.0 };
    const r = findClientsNearAnchors({
      anchors: [anchorA],
      radiusKm: 10,
      clients: [c1],
      distanceKm: (_anchor, _client) => 5,
    });
    expect(r.length).toBe(1);
    expect(r[0]?.isEstimate).toBe(false);
  });

  it('falls back to haversine when distanceKm returns null', () => {
    const c1 = { id: 'c1', lat: 48.05, lon: -3.0 };
    const r = findClientsNearAnchors({
      anchors: [anchorA],
      radiusKm: 50,
      clients: [c1],
      distanceKm: () => null,
    });
    expect(r.length).toBe(1);
    expect(r[0]?.isEstimate).toBe(true);
  });
});
