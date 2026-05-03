import { describe, it, expect } from 'vitest';
import { aggregatePrestations } from '@/domain/use-cases/aggregate-prestations';
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

describe('aggregatePrestations', () => {
  it('returns empty for no input', () => {
    expect(aggregatePrestations([])).toEqual([]);
  });

  it('groups by prestationId and sums qty + revenue + minutes', () => {
    const r = aggregatePrestations([
      [ps({ prestationId: 'shearing', qty: 5, priceCentsSnapshot: 600, minutesSnapshot: 20, nameSnapshot: 'Tonte' })],
      [ps({ prestationId: 'shearing', qty: 3, priceCentsSnapshot: 600, minutesSnapshot: 20, nameSnapshot: 'Tonte' }), ps({ prestationId: 'parage', qty: 2, priceCentsSnapshot: 300, minutesSnapshot: 10, nameSnapshot: 'Parage' })],
    ]);
    expect(r).toEqual([
      { prestationId: 'shearing', name: 'Tonte', totalQty: 8, totalRevenueCents: 4800, totalMinutes: 160 },
      { prestationId: 'parage', name: 'Parage', totalQty: 2, totalRevenueCents: 600, totalMinutes: 20 },
    ]);
  });

  it('preserves insertion order across stops', () => {
    const r = aggregatePrestations([
      [ps({ prestationId: 'a', qty: 1, nameSnapshot: 'A' })],
      [ps({ prestationId: 'b', qty: 2, nameSnapshot: 'B' })],
    ]);
    expect(r.map((x) => x.prestationId)).toEqual(['a', 'b']);
  });
});
