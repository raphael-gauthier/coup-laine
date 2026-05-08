import { describe, it, expect } from 'vitest';
import { computeMapKpis } from '@/domain/use-cases/compute-map-kpis';
import type { Status } from '@/domain/models/status';

const sys = (key: Status['systemKey'], label: string): Status => ({
  id: `sys-${key}`,
  kind: 'system',
  systemKey: key,
  label,
  colorLight: '#000000',
  colorDark: '#FFFFFF',
  sortOrder: 10,
  createdAt: '2026-05-08T00:00:00Z',
});

describe('computeMapKpis', () => {
  it('counts clients per status', () => {
    const waiting = sys('waiting', 'En attente');
    const scheduled = sys('scheduled', 'Programmé');
    const done = sys('done', 'Fait');
    const banned = sys('banned', 'Banni');
    const def = sys('default', 'Défaut');
    const r = computeMapKpis({
      statusByClientId: new Map<string, Status>([
        ['c1', waiting],
        ['c2', waiting],
        ['c3', scheduled],
        ['c4', done],
        ['c5', banned],
        ['c6', def],
      ]),
    });
    expect(r.get('sys-waiting')).toBe(2);
    expect(r.get('sys-scheduled')).toBe(1);
    expect(r.get('sys-done')).toBe(1);
    expect(r.get('sys-banned')).toBe(1);
    expect(r.get('sys-default')).toBe(1);
    expect(r.get('sys-noAnimals')).toBeUndefined();
  });
});
