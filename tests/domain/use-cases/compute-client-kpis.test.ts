import { describe, it, expect } from 'vitest';
import { computeClientKpis } from '@/domain/use-cases/compute-client-kpis';
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

describe('computeClientKpis', () => {
  it('returns zeros when no interventions', () => {
    expect(
      computeClientKpis({
        tourStops: [],
        manualEntries: [],
        today: '2026-05-03',
      })
    ).toEqual({
      interventionsCount: 0,
      totalRevenueCents: 0,
      firstInterventionDate: null,
      lastInterventionDate: null,
      yearsSinceFirst: 0,
    });
  });

  it('counts and sums services + travel fees across both sources', () => {
    const r = computeClientKpis({
      tourStops: [
        { date: '2026-03-10', services: [ps({ qty: 5, priceCentsSnapshot: 800 })], travelFeeCents: 1500 },
        { date: '2025-04-05', services: [ps({ qty: 3, priceCentsSnapshot: 600 })], travelFeeCents: null },
      ],
      manualEntries: [
        { date: '2024-06-15', services: [ps({ qty: 2, priceCentsSnapshot: 500 })], travelFeeCents: 700 },
      ],
      today: '2026-05-03',
    });
    expect(r.interventionsCount).toBe(3);
    // services: 5*800 + 3*600 + 2*500 = 6800 ; fees: 1500 + 0 + 700 = 2200 ; total: 9000
    expect(r.totalRevenueCents).toBe(9000);
    expect(r.firstInterventionDate).toBe('2024-06-15');
    expect(r.lastInterventionDate).toBe('2026-03-10');
    expect(r.yearsSinceFirst).toBe(1);
  });
});
