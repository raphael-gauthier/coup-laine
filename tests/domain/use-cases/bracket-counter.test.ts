import { describe, it, expect } from 'vitest';
import { countBrackets } from '@/domain/use-cases/bracket-counter';

describe('countBrackets (10km bracket size)', () => {
  it('0 km = 0 brackets', () => expect(countBrackets(0, 10)).toBe(0));
  it('0.5 km = 1 bracket', () => expect(countBrackets(0.5, 10)).toBe(1));
  it('1 km = 1 bracket', () => expect(countBrackets(1, 10)).toBe(1));
  it('10 km exactly = 1 bracket', () => expect(countBrackets(10, 10)).toBe(1));
  it('10.001 km = 2 brackets', () => expect(countBrackets(10.001, 10)).toBe(2));
  it('25 km = 3 brackets', () => expect(countBrackets(25, 10)).toBe(3));

  it('respects custom bracket size', () => {
    expect(countBrackets(15, 5)).toBe(3);
    expect(countBrackets(16, 5)).toBe(4);
  });

  it('throws on non-positive bracket size', () => {
    expect(() => countBrackets(10, 0)).toThrow();
    expect(() => countBrackets(10, -1)).toThrow();
  });
});
