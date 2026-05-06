import { describe, it, expect } from 'vitest';
import { computeTourPaymentKpis } from '@/domain/use-cases/compute-tour-payment-kpis';
import { EMPTY_PAYMENT } from '@/domain/models/payment';
import type { TourStop } from '@/domain/models/tour-stop';

const svc = (qty: number, priceCents: number) => ({
  serviceId: 'a', qty, nameSnapshot: 'A',
  priceCentsSnapshot: priceCents, minutesSnapshot: 0,
  categoryIdSnapshot: null, categoryNameSnapshot: null, speciesNameSnapshot: null,
});

const stop = (overrides: Partial<TourStop> = {}): TourStop => ({
  id: 's', tourId: 't', clientId: 'c', clientNameSnapshot: null,
  ordering: 0, arrivalMinutes: null, departureMinutes: null,
  estimatedMinutes: null, travelFeeCents: null,
  plannedServices: [], actualServices: [],
  notes: null, completedAt: '2026-05-01T12:00:00Z',
  payment: EMPTY_PAYMENT, ...overrides,
});

describe('computeTourPaymentKpis', () => {
  it('splits collected vs outstanding across stops', () => {
    const r = computeTourPaymentKpis({
      stops: [
        stop({ id: 'a', actualServices: [svc(1, 1000)],
               payment: { ...EMPTY_PAYMENT, isPaid: true, paidAt: 'x' } }),
        stop({ id: 'b', actualServices: [svc(2, 500)] }),
      ],
    });
    expect(r.collectedCents).toBe(1000);
    expect(r.outstandingCents).toBe(1000);
  });

  it('returns zero when no stops are completed', () => {
    expect(computeTourPaymentKpis({ stops: [] }))
      .toEqual({ collectedCents: 0, outstandingCents: 0 });
  });
});
