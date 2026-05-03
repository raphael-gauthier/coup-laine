import { describe, it, expect } from 'vitest';
import { splitTravelCost } from '@/domain/use-cases/cost-split-calculator';

describe('splitTravelCost', () => {
  it('returns empty for no stops', () => {
    expect(splitTravelCost({
      totalDistanceKm: 25,
      stopCount: 0,
      pricePerBracket: 8,
      bracketSizeKm: 10,
    })).toEqual({ totalEuros: 24, perStop: [] });
  });

  it('full fee on single stop', () => {
    expect(splitTravelCost({
      totalDistanceKm: 25,
      stopCount: 1,
      pricePerBracket: 8,
      bracketSizeKm: 10,
    })).toEqual({ totalEuros: 24, perStop: [24] });
  });

  it('splits evenly when divisible', () => {
    expect(splitTravelCost({
      totalDistanceKm: 20,
      stopCount: 2,
      pricePerBracket: 8,
      bracketSizeKm: 10,
    })).toEqual({ totalEuros: 16, perStop: [8, 8] });
  });

  it('handles non-divisible totals (sum equals total)', () => {
    const r = splitTravelCost({
      totalDistanceKm: 25,
      stopCount: 3,
      pricePerBracket: 8,
      bracketSizeKm: 10,
    });
    expect(r.totalEuros).toBe(24);
    expect(r.perStop.reduce((a, b) => a + b, 0)).toBe(24);
    expect(r.perStop.length).toBe(3);
  });

  it('rounds to whole euros and adjusts to make the sum exact', () => {
    const r = splitTravelCost({
      totalDistanceKm: 25,
      stopCount: 5,
      pricePerBracket: 8,
      bracketSizeKm: 10,
    });
    expect(r.totalEuros).toBe(24);
    expect(r.perStop.reduce((a, b) => a + b, 0)).toBe(24);
    expect(r.perStop.length).toBe(5);
    for (const v of r.perStop) {
      expect(v === 4 || v === 5).toBe(true);
    }
  });
});
