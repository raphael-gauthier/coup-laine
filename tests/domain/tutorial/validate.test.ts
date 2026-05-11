import { describe, it, expect } from 'vitest';
import { validateTutorialKey, TUTORIAL_KEYS } from '@/domain/tutorial/keys';

describe('validateTutorialKey', () => {
  it('accepts every key from the catalog', () => {
    for (const k of Object.values(TUTORIAL_KEYS)) {
      expect(validateTutorialKey(k)).toBe(true);
    }
  });

  it('rejects an unknown key', () => {
    expect(validateTutorialKey('sheet.does-not-exist')).toBe(false);
  });

  it('rejects an empty string', () => {
    expect(validateTutorialKey('')).toBe(false);
  });
});
