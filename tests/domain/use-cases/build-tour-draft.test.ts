import { describe, it, expect } from 'vitest';
import { buildTourDraft } from '@/domain/use-cases/build-tour-draft';
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

describe('buildTourDraft', () => {
  it('creates a tour with given stops in given order, status=planned', () => {
    const r = buildTourDraft({
      scheduledDate: '2026-05-10',
      departureTime: '08:00',
      base: { lat: 48.0, lon: -3.0 },
      stops: [
        { clientId: 'c1', clientNameSnapshot: 'Alice', plannedPrestations: [], notes: null },
        { clientId: 'c2', clientNameSnapshot: 'Bob', plannedPrestations: [], notes: null },
        { clientId: 'c3', clientNameSnapshot: null, plannedPrestations: [], notes: null },
      ],
      now: '2026-05-03T12:00:00Z',
      newId: () => 'fixed-id',
    });
    expect(r.tour.status).toBe('planned');
    expect(r.tour.scheduledDate).toBe('2026-05-10');
    expect(r.tour.departureTime).toBe('08:00');
    expect(r.tour.baseLat).toBe(48.0);
    expect(r.tour.baseLng).toBe(-3.0);
    expect(r.stops.map((s) => s.clientId)).toEqual(['c1', 'c2', 'c3']);
    expect(r.stops.map((s) => s.ordering)).toEqual([0, 1, 2]);
    expect(r.stops[0]?.clientNameSnapshot).toBe('Alice');
    for (const s of r.stops) {
      expect(s.tourId).toBe(r.tour.id);
      expect(s.plannedPrestations).toEqual([]);
    }
  });

  it('passes through plannedPrestations snapshots', () => {
    const prestation = ps({ prestationId: 'shearing', qty: 5, nameSnapshot: 'Tonte', minutesSnapshot: 20 });
    const r = buildTourDraft({
      scheduledDate: '2026-05-10',
      departureTime: '08:00',
      base: { lat: 48.0, lon: -3.0 },
      stops: [
        { clientId: 'c1', clientNameSnapshot: 'Alice', plannedPrestations: [prestation], notes: null },
      ],
      now: '2026-05-03T12:00:00Z',
      newId: () => 'id',
    });
    expect(r.stops[0]?.plannedPrestations).toEqual([prestation]);
  });
});
