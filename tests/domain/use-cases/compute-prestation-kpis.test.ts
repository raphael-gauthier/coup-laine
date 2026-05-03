import { describe, it, expect } from 'vitest';
import { computePrestationKpis } from '@/domain/use-cases/compute-prestation-kpis';
import type { Prestation } from '@/domain/models/prestation';
import type { TourStopPrestation } from '@/domain/models/tour-stop-prestation';

const p = (over: Partial<Prestation>): Prestation => ({
  id: 'p', label: 'X', priceCents: null, minutes: 0, categoryId: null,
  isActive: true, archivedAt: null, ordering: 0,
  ...over,
});
const ps = (over: Partial<TourStopPrestation>): TourStopPrestation => ({
  prestationId: 'p', qty: 1,
  nameSnapshot: 'X', priceCentsSnapshot: 0, minutesSnapshot: 0,
  categoryIdSnapshot: null, categoryNameSnapshot: null, speciesNameSnapshot: null,
  ...over,
});

describe('computePrestationKpis', () => {
  it('counts active vs archived', () => {
    const r = computePrestationKpis({
      prestations: [
        p({ id: 'a', archivedAt: null }),
        p({ id: 'b', archivedAt: null }),
        p({ id: 'c', archivedAt: '2026-01-01' }),
      ],
      thisMonthInterventions: [],
      today: '2026-05-03',
    });
    expect(r.activeCount).toBe(2);
    expect(r.archivedCount).toBe(1);
  });

  it('sums month-to-date revenue from interventions in this calendar month', () => {
    const r = computePrestationKpis({
      prestations: [],
      thisMonthInterventions: [
        { date: '2026-05-02', prestations: [ps({ qty: 5, priceCentsSnapshot: 800 })] },
        { date: '2026-04-30', prestations: [ps({ qty: 3, priceCentsSnapshot: 800 })] }, // last month, ignored
      ],
      today: '2026-05-03',
    });
    expect(r.monthRevenueCents).toBe(5 * 800);
  });
});
