import { describe, it, expect } from 'vitest';
import { formatPhone } from '@/lib/phone-formatter';

describe('formatPhone', () => {
  it('formats a 10-digit FR number in pairs', () => {
    expect(formatPhone('0612345678')).toBe('06 12 34 56 78');
  });
  it('formats +33 number as +33 6 12 34 56 78', () => {
    expect(formatPhone('+33612345678')).toBe('+33 6 12 34 56 78');
  });
  it('returns input unchanged for unrecognized formats', () => {
    expect(formatPhone('123')).toBe('123');
  });
  it('handles empty input', () => {
    expect(formatPhone('')).toBe('');
  });
});
