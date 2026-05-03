import { describe, it, expect } from 'vitest';
import { computeMapKpis } from '@/domain/use-cases/compute-map-kpis';
import type { ClientStatus } from '@/domain/use-cases/client-status';

describe('computeMapKpis', () => {
  it('counts clients per status', () => {
    const r = computeMapKpis({
      statusByClientId: new Map<string, ClientStatus>([
        ['c1', 'waiting'],
        ['c2', 'waiting'],
        ['c3', 'scheduled'],
        ['c4', 'done'],
        ['c5', 'banned'],
        ['c6', 'default'],
      ]),
    });
    expect(r).toEqual({
      total: 6,
      default: 1,
      waiting: 2,
      scheduled: 1,
      done: 1,
      noAnimals: 0,
      banned: 1,
    });
  });
});
