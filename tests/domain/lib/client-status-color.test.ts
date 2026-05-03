import { describe, it, expect } from 'vitest';
import { clientStatusColor } from '@/lib/client-status-color';

describe('clientStatusColor', () => {
  it('returns waiting tokens', () => {
    const t = clientStatusColor('waiting');
    expect(t.bgClass).toBe('bg-waiting dark:bg-waiting-dark');
    expect(t.settingsKey).toBe('marker_waiting_color');
  });

  it('returns scheduled tokens', () => {
    const t = clientStatusColor('scheduled');
    expect(t.bgClass).toBe('bg-primary dark:bg-primary-dark');
    expect(t.settingsKey).toBe('marker_scheduled_color');
  });

  it('returns done tokens', () => {
    const t = clientStatusColor('done');
    expect(t.bgClass).toBe('bg-shorn dark:bg-shorn-dark');
    expect(t.settingsKey).toBe('marker_done_color');
  });

  it('returns noAnimals tokens', () => {
    const t = clientStatusColor('noAnimals');
    expect(t.bgClass).toBe('bg-muted dark:bg-muted-dark');
    expect(t.settingsKey).toBe('marker_no_animals_color');
  });

  it('returns banned tokens', () => {
    const t = clientStatusColor('banned');
    expect(t.bgClass).toBe('bg-danger dark:bg-danger-dark');
    expect(t.settingsKey).toBe('marker_banned_color');
  });

  it('returns default tokens (transparent)', () => {
    const t = clientStatusColor('default');
    expect(t.bgClass).toBe('bg-transparent');
    expect(t.settingsKey).toBe('marker_default_color');
  });
});
