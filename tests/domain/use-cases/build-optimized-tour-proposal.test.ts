import { describe, it, expect } from 'vitest';
import { buildOptimizedTourProposal } from '@/domain/use-cases/build-optimized-tour-proposal';

describe('buildOptimizedTourProposal', () => {
  it('orders stops via optimizer and returns a draft tour', () => {
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
      clientIds: ['a', 'b', 'c'],
      distanceKm: (f, t) => distances[`${f}-${t}`] ?? 0,
      now: '2026-05-03T12:00:00Z',
      newId: () => `id-${n++}`,
    });
    expect(r.stops.map((s) => s.clientId)).toEqual(['a', 'b', 'c']);
    expect(r.tour.status).toBe('draft');
  });
});
