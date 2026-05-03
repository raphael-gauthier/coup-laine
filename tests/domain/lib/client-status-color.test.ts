import { describe, it, expect } from 'vitest';
import { clientStatusColor } from '@/lib/client-status-color';

describe('clientStatusColor', () => {
  it('returns waiting tokens for waiting status', () => {
    expect(clientStatusColor('waiting')).toEqual({
      bg: 'bg-waiting',
      bgDark: 'bg-waiting-dark',
      text: 'text-primary-foreground',
      textDark: 'text-primary-dark-foreground',
    });
  });

  it('returns shorn tokens for shorn-recent status', () => {
    expect(clientStatusColor('shorn-recent').bg).toBe('bg-shorn');
  });

  it('returns muted tokens for shorn-old status', () => {
    expect(clientStatusColor('shorn-old').bg).toBe('bg-muted');
  });

  it('returns transparent tokens for never status', () => {
    expect(clientStatusColor('never').bg).toBe('bg-transparent');
  });
});
