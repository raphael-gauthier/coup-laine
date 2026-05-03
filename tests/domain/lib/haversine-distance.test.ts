import { describe, it, expect } from 'vitest';
import { haversineDistanceKm } from '@/lib/haversine-distance';

describe('haversineDistanceKm', () => {
  it('returns 0 for identical points', () => {
    expect(haversineDistanceKm({ lat: 48, lon: -3 }, { lat: 48, lon: -3 })).toBe(0);
  });

  it('returns ~111 km for 1° of latitude', () => {
    const d = haversineDistanceKm({ lat: 48, lon: -3 }, { lat: 49, lon: -3 });
    expect(d).toBeGreaterThan(110);
    expect(d).toBeLessThan(112);
  });

  it('returns symmetric values', () => {
    const a = { lat: 48.1, lon: -3.5 };
    const b = { lat: 48.6, lon: -2.9 };
    expect(haversineDistanceKm(a, b)).toBeCloseTo(haversineDistanceKm(b, a), 6);
  });
});
