import { describe, it, expect } from 'vitest';
import { computeClientStatus } from '@/domain/use-cases/client-status';

describe('computeClientStatus', () => {
  const today = '2026-05-03';

  it('returns "waiting" when isWaiting=true', () => {
    expect(computeClientStatus({
      isWaiting: true, lastShearingDate: '2025-05-01', today,
    })).toBe('waiting');
  });

  it('returns "shorn-recent" when last shearing within 60 days', () => {
    expect(computeClientStatus({
      isWaiting: false, lastShearingDate: '2026-04-15', today,
    })).toBe('shorn-recent');
  });

  it('returns "shorn-old" when last shearing > 60 days ago', () => {
    expect(computeClientStatus({
      isWaiting: false, lastShearingDate: '2025-05-01', today,
    })).toBe('shorn-old');
  });

  it('returns "never" when no last shearing date and not waiting', () => {
    expect(computeClientStatus({
      isWaiting: false, lastShearingDate: null, today,
    })).toBe('never');
  });
});
