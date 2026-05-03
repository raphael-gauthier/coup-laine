import { describe, it, expect } from 'vitest';
import { estimateTourDuration } from '@/domain/use-cases/tour-duration-estimator';

const categoriesByMinutes = new Map<string, number>([
  ['sheep-adult', 20],
  ['sheep-lamb', 15],
]);

describe('estimateTourDuration', () => {
  it('returns 0 for an empty tour', () => {
    expect(estimateTourDuration({
      stops: [],
      travelMinutesBetween: () => 0,
      categoryMinutes: categoriesByMinutes,
    })).toBe(0);
  });

  it('sums shearing minutes for one stop', () => {
    expect(estimateTourDuration({
      stops: [{ clientId: 'c1', animalCounts: [{ categoryId: 'sheep-adult', count: 3 }] }],
      travelMinutesBetween: () => 0,
      categoryMinutes: categoriesByMinutes,
    })).toBe(60);
  });

  it('mixes categories', () => {
    expect(estimateTourDuration({
      stops: [{
        clientId: 'c1',
        animalCounts: [
          { categoryId: 'sheep-adult', count: 2 },
          { categoryId: 'sheep-lamb', count: 4 },
        ],
      }],
      travelMinutesBetween: () => 0,
      categoryMinutes: categoriesByMinutes,
    })).toBe(100);
  });

  it('adds travel time between stops (base → s1 → s2)', () => {
    const travel = (from: string, to: string) =>
      ({ 'BASE-c1': 10, 'c1-c2': 15 } as const)[`${from}-${to}` as 'BASE-c1' | 'c1-c2'] ?? 0;
    expect(estimateTourDuration({
      stops: [
        { clientId: 'c1', animalCounts: [{ categoryId: 'sheep-adult', count: 1 }] },
        { clientId: 'c2', animalCounts: [{ categoryId: 'sheep-adult', count: 2 }] },
      ],
      travelMinutesBetween: travel,
      categoryMinutes: categoriesByMinutes,
    })).toBe(20 + 40 + 10 + 15);
  });

  it('ignores unknown categoryIds', () => {
    expect(estimateTourDuration({
      stops: [{ clientId: 'c1', animalCounts: [{ categoryId: 'unknown', count: 5 }] }],
      travelMinutesBetween: () => 0,
      categoryMinutes: categoriesByMinutes,
    })).toBe(0);
  });
});
