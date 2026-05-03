import { describe, it, expect } from 'vitest';
import { splitTravelCost } from '@/domain/use-cases/cost-split-calculator';

describe('splitTravelCost (farthest-stop + inter-stop split)', () => {
  it('returns empty for no stops', () => {
    expect(
      splitTravelCost({
        baseToStopDistancesKm: [],
        interStopDistancesKm: [],
        pricePerBracket: 8,
        bracketSizeKm: 10,
      })
    ).toEqual({ totalEuros: 0, perStop: [], farthestEuros: 0, interEuros: 0 });
  });

  it('single stop: only farthest fee, no inter-stop fee', () => {
    expect(
      splitTravelCost({
        baseToStopDistancesKm: [25],
        interStopDistancesKm: [],
        pricePerBracket: 8,
        bracketSizeKm: 10,
      })
    ).toEqual({ totalEuros: 24, perStop: [24], farthestEuros: 24, interEuros: 0 });
  });

  it('three stops: farthest 25km (3 brackets) + inter 12km (2 brackets) → total 40 €, split 14/13/13', () => {
    const r = splitTravelCost({
      baseToStopDistancesKm: [10, 25, 15],
      interStopDistancesKm: [7, 5],
      pricePerBracket: 8,
      bracketSizeKm: 10,
    });
    expect(r.farthestEuros).toBe(24); // ceil(25/10) × 8
    expect(r.interEuros).toBe(16);    // ceil(12/10) × 8
    expect(r.totalEuros).toBe(40);
    expect(r.perStop.reduce((a, b) => a + b, 0)).toBe(40);
    expect(r.perStop.length).toBe(3);
    // First stop gets +1 to absorb remainder of 40/3 = 13.33
    expect(r.perStop).toEqual([14, 13, 13]);
  });
});
