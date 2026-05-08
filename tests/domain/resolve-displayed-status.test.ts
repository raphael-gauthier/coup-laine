import { describe, it, expect } from 'vitest';
import { resolveDisplayedStatus } from '@/domain/use-cases/resolve-displayed-status';
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
const manual = (id: string, label: string): Status => ({
  id,
  kind: 'manual',
  systemKey: null,
  label,
  colorLight: '#111111',
  colorDark: '#222222',
  sortOrder: 100,
  createdAt: '2026-05-08T00:00:00Z',
});

describe('resolveDisplayedStatus', () => {
  const waiting = sys('waiting', 'En attente');
  const banned = sys('banned', 'Banni');
  const vip = manual('m-vip', 'VIP');
  const registry = {
    bySystemKey: (k: Status['systemKey']) =>
      k === 'waiting' ? waiting : k === 'banned' ? banned : null,
    byId: (id: string) => (id === 'm-vip' ? vip : null),
  };

  it('returns derived when no manualStatusId', () => {
    const out = resolveDisplayedStatus({ manualStatusId: null }, 'waiting', registry);
    expect(out).toBe(waiting);
  });

  it('returns manual when set and exists', () => {
    const out = resolveDisplayedStatus({ manualStatusId: 'm-vip' }, 'waiting', registry);
    expect(out).toBe(vip);
  });

  it('falls back to derived when manualStatusId points to missing row', () => {
    const out = resolveDisplayedStatus({ manualStatusId: 'm-gone' }, 'waiting', registry);
    expect(out).toBe(waiting);
  });

  it('manual overrides even banned', () => {
    const out = resolveDisplayedStatus({ manualStatusId: 'm-vip' }, 'banned', registry);
    expect(out).toBe(vip);
  });
});
