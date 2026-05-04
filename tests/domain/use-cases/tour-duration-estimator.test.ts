import { describe, it, expect } from 'vitest';
import { estimateTourDuration } from '@/domain/use-cases/tour-duration-estimator';
import type { TourStopService } from '@/domain/models/tour-stop-service';

const ps = (over: Partial<TourStopService>): TourStopService => ({
  serviceId: 'p',
  qty: 1,
  nameSnapshot: 'X',
  priceCentsSnapshot: 0,
  minutesSnapshot: 0,
  categoryIdSnapshot: null,
  categoryNameSnapshot: null,
  speciesNameSnapshot: null,
  ...over,
});

describe('estimateTourDuration', () => {
  it('returns 0 for an empty tour', () => {
    expect(estimateTourDuration({
      stops: [],
      travelMinutesBetween: () => 0,
    })).toBe(0);
  });

  it('sums service minutes for one stop', () => {
    expect(estimateTourDuration({
      stops: [{ clientId: 'c1', plannedServices: [ps({ qty: 3, minutesSnapshot: 20 })] }],
      travelMinutesBetween: () => 0,
    })).toBe(60);
  });

  it('mixes multiple services', () => {
    expect(estimateTourDuration({
      stops: [{
        clientId: 'c1',
        plannedServices: [
          ps({ qty: 2, minutesSnapshot: 20 }),
          ps({ qty: 4, minutesSnapshot: 15 }),
        ],
      }],
      travelMinutesBetween: () => 0,
    })).toBe(100);
  });

  it('adds travel time between stops (base → s1 → s2)', () => {
    const travel = (from: string, to: string) =>
      ({ 'BASE-c1': 10, 'c1-c2': 15 } as const)[`${from}-${to}` as 'BASE-c1' | 'c1-c2'] ?? 0;
    expect(estimateTourDuration({
      stops: [
        { clientId: 'c1', plannedServices: [ps({ qty: 1, minutesSnapshot: 20 })] },
        { clientId: 'c2', plannedServices: [ps({ qty: 2, minutesSnapshot: 20 })] },
      ],
      travelMinutesBetween: travel,
    })).toBe(20 + 40 + 10 + 15);
  });

  it('returns travel-only time when no services', () => {
    expect(estimateTourDuration({
      stops: [{ clientId: 'c1', plannedServices: [] }],
      travelMinutesBetween: () => 10,
    })).toBe(10);
  });
});
