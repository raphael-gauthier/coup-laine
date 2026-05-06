import { describe, it, expect } from 'vitest';
import { computeClientOutstanding } from '@/domain/use-cases/compute-client-outstanding';
import { EMPTY_PAYMENT } from '@/domain/models/payment';
import type { TourStop } from '@/domain/models/tour-stop';
import type { ManualHistoryEntry } from '@/domain/models/manual-history-entry';

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

const entry = (overrides: Partial<ManualHistoryEntry> = {}): ManualHistoryEntry => ({
  id: 'e', clientId: 'c', date: '2026-04-15',
  notes: null, services: [], travelFeeCents: null, payment: EMPTY_PAYMENT, ...overrides,
});

describe('computeClientOutstanding', () => {
  it('sums services + travel fees across unpaid completed stops', () => {
    const r = computeClientOutstanding({
      completedStops: [
        { ...stop({ actualServices: [svc(2, 1500)] }), travelFeeCents: 1000 }, // 30€ + 10€
        { ...stop({ id: 's2', actualServices: [svc(1, 1000)],
                    payment: { ...EMPTY_PAYMENT, isPaid: true, paidAt: 'x' } }), travelFeeCents: 500 },
      ],
      manualEntries: [],
    });
    expect(r.unpaidCents).toBe(4000);
    expect(r.unpaidCount).toBe(1);
  });

  it('treats null travelFeeCents as 0', () => {
    const r = computeClientOutstanding({
      completedStops: [{ ...stop({ actualServices: [svc(2, 1500)] }), travelFeeCents: null }],
      manualEntries: [],
    });
    expect(r.unpaidCents).toBe(3000);
  });

  it('uses plannedServices when actualServices is null', () => {
    const r = computeClientOutstanding({
      completedStops: [{ ...stop({ plannedServices: [svc(1, 2000)], actualServices: null }), travelFeeCents: null }],
      manualEntries: [],
    });
    expect(r.unpaidCents).toBe(2000);
  });

  it('includes unpaid manual entries with travel fees', () => {
    const r = computeClientOutstanding({
      completedStops: [],
      manualEntries: [{ ...entry({ services: [svc(1, 4000)] }), travelFeeCents: 1500 }],
    });
    expect(r.unpaidCents).toBe(5500);
    expect(r.unpaidCount).toBe(1);
  });

  it('ignores zero-quantity service lines', () => {
    const r = computeClientOutstanding({
      completedStops: [{ ...stop({ actualServices: [svc(0, 1000), svc(2, 500)] }), travelFeeCents: null }],
      manualEntries: [],
    });
    expect(r.unpaidCents).toBe(1000);
  });

  it('returns zero when nothing is outstanding', () => {
    expect(
      computeClientOutstanding({ completedStops: [], manualEntries: [] })
    ).toEqual({ unpaidCents: 0, unpaidCount: 0 });
  });
});
