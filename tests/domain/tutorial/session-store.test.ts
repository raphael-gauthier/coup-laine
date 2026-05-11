import { describe, it, expect, beforeEach } from 'vitest';
import {
  hasDiscoveryFiredThisSession,
  markDiscoveryFired,
  resetSessionDiscoveryFlag,
} from '@/ui/help/session-store';

describe('session-store', () => {
  beforeEach(() => {
    resetSessionDiscoveryFlag();
  });

  it('starts at false', () => {
    expect(hasDiscoveryFiredThisSession()).toBe(false);
  });

  it('flips to true after markDiscoveryFired', () => {
    markDiscoveryFired();
    expect(hasDiscoveryFiredThisSession()).toBe(true);
  });

  it('resets back to false on resetSessionDiscoveryFlag', () => {
    markDiscoveryFired();
    expect(hasDiscoveryFiredThisSession()).toBe(true);
    resetSessionDiscoveryFlag();
    expect(hasDiscoveryFiredThisSession()).toBe(false);
  });
});
