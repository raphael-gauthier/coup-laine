import { describe, it, expect } from 'vitest';
import { resolveBaseDistance } from '@/domain/use-cases/resolve-base-distance';

const base = { lat: 48.0, lon: 2.0 };
const client = { lat: 48.1, lon: 2.1 }; // ~13.4 km haversine

describe('resolveBaseDistance', () => {
  it('uses cached routing distance when present and not failed', () => {
    const r = resolveBaseDistance({
      base,
      client,
      lookup: () => ({ distanceKm: 18.5, failed: false }),
    });
    expect(r).toBeCloseTo(18.5, 5);
  });

  it('falls back to haversine when cache miss', () => {
    const r = resolveBaseDistance({
      base,
      client,
      lookup: () => null,
    });
    expect(r).toBeGreaterThan(13);
    expect(r).toBeLessThan(14);
  });

  it('falls back to haversine when cache entry is failed', () => {
    const r = resolveBaseDistance({
      base,
      client,
      lookup: () => ({ distanceKm: 0, failed: true }),
    });
    expect(r).toBeGreaterThan(13);
    expect(r).toBeLessThan(14);
  });

  it('returns 0 when client coords missing', () => {
    expect(
      resolveBaseDistance({ base, client: null, lookup: () => null })
    ).toBe(0);
  });
});
