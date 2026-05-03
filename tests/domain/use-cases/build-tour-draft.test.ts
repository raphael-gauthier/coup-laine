import { describe, it, expect } from 'vitest';
import { buildTourDraft } from '@/domain/use-cases/build-tour-draft';

describe('buildTourDraft', () => {
  it('creates a tour with given client ids in given order, status=planned', () => {
    const r = buildTourDraft({
      scheduledDate: '2026-05-10',
      departureTime: '08:00',
      base: { lat: 48.0, lon: -3.0 },
      clientIds: ['c1', 'c2', 'c3'],
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
    for (const s of r.stops) {
      expect(s.tourId).toBe(r.tour.id);
      expect(s.plannedPrestations).toEqual([]);
    }
  });
});
