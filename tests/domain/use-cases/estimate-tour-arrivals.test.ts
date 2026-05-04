import { describe, it, expect } from 'vitest';
import { estimateTourArrivals } from '@/domain/use-cases/estimate-tour-arrivals';
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

describe('estimateTourArrivals', () => {
  it('returns empty for no stops', () => {
    expect(estimateTourArrivals({
      departureTime: '08:00',
      stops: [],
      travelMinutesBetween: () => 0,
    })).toEqual([]);
  });

  it('first stop arrival = departure + travel from BASE', () => {
    const r = estimateTourArrivals({
      departureTime: '08:00',
      stops: [{ clientId: 'c1', plannedServices: [ps({ qty: 3, minutesSnapshot: 20 })] }],
      travelMinutesBetween: (from, to) => (from === 'BASE' && to === 'c1' ? 15 : 0),
    });
    expect(r[0]?.arrivalTime).toBe('08:15');
    expect(r[0]?.estimatedMinutes).toBe(60);
    expect(r[0]?.arrivalMinutes).toBe(8 * 60 + 15);
  });

  it('chains arrivals across stops', () => {
    const r = estimateTourArrivals({
      departureTime: '08:00',
      stops: [
        { clientId: 'c1', plannedServices: [ps({ qty: 1, minutesSnapshot: 20 })] },
        { clientId: 'c2', plannedServices: [ps({ qty: 2, minutesSnapshot: 20 })] },
      ],
      travelMinutesBetween: (from, to) => {
        const k = `${from}-${to}`;
        if (k === 'BASE-c1') return 10;
        if (k === 'c1-c2') return 25;
        return 0;
      },
    });
    expect(r[0]?.arrivalTime).toBe('08:10');
    expect(r[1]?.arrivalTime).toBe('08:55');
  });

  it('wraps past midnight', () => {
    const r = estimateTourArrivals({
      departureTime: '23:30',
      stops: [{ clientId: 'c1', plannedServices: [] }],
      travelMinutesBetween: () => 45,
    });
    expect(r[0]?.arrivalTime).toBe('00:15');
  });
});
