import { describe, it, expect } from 'vitest';
import { clientStatusColor } from '@/lib/client-status-color';

describe('clientStatusColor', () => {
  it('returns waiting tokens with dark variants baked in', () => {
    expect(clientStatusColor('waiting')).toEqual({
      bgClass: 'bg-waiting dark:bg-waiting-dark',
      textClass: 'text-primary-foreground dark:text-primary-dark-foreground',
    });
  });

  it('returns shorn tokens for shorn-recent status', () => {
    expect(clientStatusColor('shorn-recent').bgClass).toBe('bg-shorn dark:bg-shorn-dark');
  });

  it('returns muted tokens for shorn-old status', () => {
    expect(clientStatusColor('shorn-old').bgClass).toBe('bg-muted dark:bg-muted-dark');
  });

  it('returns transparent for never status (no dark variant needed)', () => {
    expect(clientStatusColor('never').bgClass).toBe('bg-transparent');
  });
});
