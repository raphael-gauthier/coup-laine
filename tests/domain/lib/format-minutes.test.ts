import { describe, it, expect } from 'vitest';
import { formatMinutes } from '@/lib/format-minutes';

describe('formatMinutes', () => {
  it('formats 0 as "0 min"', () => expect(formatMinutes(0)).toBe('0 min'));
  it('formats < 60 as minutes', () => expect(formatMinutes(45)).toBe('45 min'));
  it('formats exact hour as "Xh"', () => expect(formatMinutes(60)).toBe('1h'));
  it('formats hour + min', () => expect(formatMinutes(75)).toBe('1h 15'));
  it('formats multi-hour', () => expect(formatMinutes(125)).toBe('2h 05'));
  it('zero-pads minutes < 10 in compound', () => expect(formatMinutes(122)).toBe('2h 02'));
});
