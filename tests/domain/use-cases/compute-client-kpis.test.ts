import { describe, it, expect } from 'vitest';
import { computeClientKpis } from '@/domain/use-cases/compute-client-kpis';
import type { TourStopPrestation } from '@/domain/models/tour-stop-prestation';

const ps = (over: Partial<TourStopPrestation>): TourStopPrestation => ({
  prestationId: 'p',
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

  it('counts and sums across both sources', () => {
    const r = computeClientKpis({
      tourStops: [
        { date: '2026-03-10', prestations: [ps({ qty: 5, priceCentsSnapshot: 800 })] },
        { date: '2025-04-05', prestations: [ps({ qty: 3, priceCentsSnapshot: 600 })] },
      ],
      manualEntries: [
        { date: '2024-06-15', prestations: [ps({ qty: 2, priceCentsSnapshot: 500 })] },
      ],
      today: '2026-05-03',
    });
    expect(r.interventionsCount).toBe(3);
    expect(r.totalRevenueCents).toBe(5 * 800 + 3 * 600 + 2 * 500); // 4000 + 1800 + 1000 = 6800
    expect(r.firstInterventionDate).toBe('2024-06-15');
    expect(r.lastInterventionDate).toBe('2026-03-10');
    expect(r.yearsSinceFirst).toBe(1); // 2026-2024 = 2 years calendar but 1 full year diff (less than 2 elapsed by date)
  });
});
