import { describe, it, expect } from 'vitest';
import { buildOptimizedTourProposal } from '@/domain/use-cases/build-optimized-tour-proposal';

describe('buildOptimizedTourProposal', () => {
  it('orders stops via optimizer and returns a planned tour', () => {
    const distances: Record<string, number> = {
      'BASE-a': 1, 'a-BASE': 1,
      'BASE-b': 100, 'b-BASE': 100,
      'BASE-c': 2, 'c-BASE': 2,
      'a-b': 50, 'b-a': 50,
      'a-c': 60, 'c-a': 60,
      'b-c': 1, 'c-b': 1,
    };
    let n = 0;
    const r = buildOptimizedTourProposal({
      scheduledDate: '2026-05-10',
      departureTime: '08:00',
      base: { lat: 48.0, lon: -3.0 },
      stops: [
        { clientId: 'a', clientNameSnapshot: 'Alice', plannedServices: [], notes: null },
        { clientId: 'b', clientNameSnapshot: 'Bob', plannedServices: [], notes: null },
        { clientId: 'c', clientNameSnapshot: 'Charlie', plannedServices: [], notes: null },
      ],
      distanceKm: (f, t) => distances[`${f}-${t}`] ?? 0,
      now: '2026-05-03T12:00:00Z',
      newId: () => `id-${n++}`,
    });
    expect(r.stops.map((s) => s.clientId)).toEqual(['a', 'b', 'c']);
    expect(r.tour.status).toBe('planned');
    expect(r.stops[0]?.clientNameSnapshot).toBe('Alice');
  });

  it('passes through plannedServices for each stop', () => {
    let n = 0;
    const r = buildOptimizedTourProposal({
      scheduledDate: '2026-05-10',
      departureTime: '08:00',
      base: { lat: 48.0, lon: -3.0 },
      stops: [
        {
          clientId: 'x',
          clientNameSnapshot: 'Xavier',
          plannedServices: [{
            serviceId: 'shearing',
            qty: 3,
            nameSnapshot: 'Tonte',
            priceCentsSnapshot: 600,
            minutesSnapshot: 20,
            categoryIdSnapshot: null,
            categoryNameSnapshot: null,
            speciesNameSnapshot: null,
          }],
          notes: null,
        },
      ],
      distanceKm: () => 0,
      now: '2026-05-03T12:00:00Z',
      newId: () => `id-${n++}`,
    });
    expect(r.stops[0]?.plannedServices).toHaveLength(1);
    expect(r.stops[0]?.plannedServices[0]?.serviceId).toBe('shearing');
  });
});
