import { describe, it, expect } from 'vitest';
import { normalizePhone } from '@/lib/phone-normalizer';

describe('normalizePhone', () => {
  it('strips spaces, dots, and dashes', () => {
    expect(normalizePhone('06 12.34-56 78')).toBe('0612345678');
  });
  it('preserves a leading +', () => {
    expect(normalizePhone('+33 6 12 34 56 78')).toBe('+33612345678');
  });
  it('returns empty for non-digit input', () => {
    expect(normalizePhone('abc')).toBe('');
  });
});
