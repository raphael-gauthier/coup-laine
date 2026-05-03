import { describe, it, expect } from 'vitest';
import { optimizeTourOrder } from '@/domain/use-cases/tour-order-optimizer';

describe('optimizeTourOrder', () => {
  it('returns input order for zero or one stops', () => {
    expect(optimizeTourOrder({ stopIds: [], distanceKm: () => 0 })).toEqual([]);
    expect(optimizeTourOrder({ stopIds: ['a'], distanceKm: () => 0 })).toEqual(['a']);
  });

  it('picks nearest neighbour from base (3 collinear stops)', () => {
    const distances = new Map<string, number>([
      ['BASE-a', 5], ['BASE-b', 10], ['BASE-c', 15],
      ['a-b', 5], ['a-c', 10], ['b-c', 5],
      ['a-BASE', 5], ['b-BASE', 10], ['c-BASE', 15],
      ['b-a', 5], ['c-a', 10], ['c-b', 5],
    ]);
    const dist = (from: string, to: string) => distances.get(`${from}-${to}`) ?? 0;

    const r = optimizeTourOrder({ stopIds: ['c', 'a', 'b'], distanceKm: dist });
    expect(r).toEqual(['a', 'b', 'c']);
  });

  it('improves a sub-optimal nearest-neighbour result via 2-opt', () => {
    const sym = (a: string, b: string, v: number) =>
      [`${a}-${b}`, `${b}-${a}`].map((k) => [k, v] as const);
    const distances = new Map<string, number>([
      ...sym('BASE', 'a', 1),
      ...sym('BASE', 'b', 100),
      ...sym('BASE', 'c', 2),
      ...sym('a', 'b', 50),
      ...sym('a', 'c', 60),
      ...sym('b', 'c', 1),
    ]);
    const dist = (from: string, to: string) => distances.get(`${from}-${to}`) ?? 0;

    const r = optimizeTourOrder({ stopIds: ['a', 'b', 'c'], distanceKm: dist });
    expect(r).toEqual(['a', 'b', 'c']);
  });
});
