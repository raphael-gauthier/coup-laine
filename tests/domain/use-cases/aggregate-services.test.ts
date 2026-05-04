import { describe, it, expect } from 'vitest';
import { aggregateServices } from '@/domain/use-cases/aggregate-services';
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

describe('aggregateServices', () => {
  it('returns empty for no input', () => {
    expect(aggregateServices([])).toEqual([]);
  });

  it('groups by serviceId and sums qty + revenue + minutes', () => {
    const r = aggregateServices([
      [ps({ serviceId: 'shearing', qty: 5, priceCentsSnapshot: 600, minutesSnapshot: 20, nameSnapshot: 'Tonte' })],
      [ps({ serviceId: 'shearing', qty: 3, priceCentsSnapshot: 600, minutesSnapshot: 20, nameSnapshot: 'Tonte' }), ps({ serviceId: 'parage', qty: 2, priceCentsSnapshot: 300, minutesSnapshot: 10, nameSnapshot: 'Parage' })],
    ]);
    expect(r).toEqual([
      { serviceId: 'shearing', name: 'Tonte', totalQty: 8, totalRevenueCents: 4800, totalMinutes: 160 },
      { serviceId: 'parage', name: 'Parage', totalQty: 2, totalRevenueCents: 600, totalMinutes: 20 },
    ]);
  });

  it('preserves insertion order across stops', () => {
    const r = aggregateServices([
      [ps({ serviceId: 'a', qty: 1, nameSnapshot: 'A' })],
      [ps({ serviceId: 'b', qty: 2, nameSnapshot: 'B' })],
    ]);
    expect(r.map((x) => x.serviceId)).toEqual(['a', 'b']);
  });
});
