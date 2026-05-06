import { describe, it, expect } from 'vitest';
import { computeClientTravelFee } from '@/domain/use-cases/compute-client-travel-fee';

describe('computeClientTravelFee', () => {
  it('charges 1 bracket minimum even at 0 km', () => {
    expect(computeClientTravelFee({ distanceKm: 0, bracketKm: 10, feePerBracket: 8 })).toBe(0);
  });

  it('charges 1 bracket below the bracket size', () => {
    expect(computeClientTravelFee({ distanceKm: 4, bracketKm: 10, feePerBracket: 8 })).toBe(800);
  });

  it('rounds up to the next bracket (ceil)', () => {
    expect(computeClientTravelFee({ distanceKm: 23, bracketKm: 10, feePerBracket: 8 })).toBe(2400);
    expect(computeClientTravelFee({ distanceKm: 25, bracketKm: 10, feePerBracket: 8 })).toBe(2400);
    expect(computeClientTravelFee({ distanceKm: 30.01, bracketKm: 10, feePerBracket: 8 })).toBe(3200);
  });

  it('returns integer cents from float fee', () => {
    // 2 brackets × 7.5 € = 15 € = 1500 cents
    expect(computeClientTravelFee({ distanceKm: 15, bracketKm: 10, feePerBracket: 7.5 })).toBe(1500);
  });

  it('returns 0 when distance is exactly 0 (no brackets)', () => {
    expect(computeClientTravelFee({ distanceKm: 0, bracketKm: 10, feePerBracket: 8 })).toBe(0);
  });
});
