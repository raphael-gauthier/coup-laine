import { describe, it, expect } from 'vitest';
import { Coordinates } from '@/domain/models/coordinates';

describe('Coordinates', () => {
  it('parses valid coordinates', () => {
    const c = Coordinates.parse({ lat: 48.0, lon: -3.0 });
    expect(c.lat).toBe(48.0);
    expect(c.lon).toBe(-3.0);
  });

  it('rejects out-of-range latitude', () => {
    expect(() => Coordinates.parse({ lat: 91, lon: 0 })).toThrow();
    expect(() => Coordinates.parse({ lat: -91, lon: 0 })).toThrow();
  });

  it('rejects out-of-range longitude', () => {
    expect(() => Coordinates.parse({ lat: 0, lon: 181 })).toThrow();
    expect(() => Coordinates.parse({ lat: 0, lon: -181 })).toThrow();
  });
});
