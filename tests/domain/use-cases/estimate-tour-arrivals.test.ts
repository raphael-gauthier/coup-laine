import { describe, it, expect } from 'vitest';
import { estimateTourArrivals } from '@/domain/use-cases/estimate-tour-arrivals';

const cats = new Map<string, number>([['sheep-adult', 20]]);

describe('estimateTourArrivals', () => {
  it('returns empty for no stops', () => {
    expect(estimateTourArrivals({
      departureTime: '08:00',
      stops: [],
      travelMinutesBetween: () => 0,
      categoryMinutes: cats,
    })).toEqual([]);
  });

  it('first stop arrival = departure + travel from BASE', () => {
    const r = estimateTourArrivals({
      departureTime: '08:00',
      stops: [{ clientId: 'c1', animalCounts: [{ categoryId: 'sheep-adult', count: 3 }] }],
      travelMinutesBetween: (from, to) => (from === 'BASE' && to === 'c1' ? 15 : 0),
      categoryMinutes: cats,
    });
    expect(r[0]?.arrivalTime).toBe('08:15');
    expect(r[0]?.estimatedMinutes).toBe(60);
  });

  it('chains arrivals across stops', () => {
    const r = estimateTourArrivals({
      departureTime: '08:00',
      stops: [
        { clientId: 'c1', animalCounts: [{ categoryId: 'sheep-adult', count: 1 }] },
        { clientId: 'c2', animalCounts: [{ categoryId: 'sheep-adult', count: 2 }] },
      ],
      travelMinutesBetween: (from, to) => {
        const k = `${from}-${to}`;
        if (k === 'BASE-c1') return 10;
        if (k === 'c1-c2') return 25;
        return 0;
      },
      categoryMinutes: cats,
    });
    expect(r[0]?.arrivalTime).toBe('08:10');
    expect(r[1]?.arrivalTime).toBe('08:55');
  });

  it('wraps past midnight', () => {
    const r = estimateTourArrivals({
      departureTime: '23:30',
      stops: [{ clientId: 'c1', animalCounts: [] }],
      travelMinutesBetween: () => 45,
      categoryMinutes: cats,
    });
    expect(r[0]?.arrivalTime).toBe('00:15');
  });
});
