import { describe, it, expect } from 'vitest';
import { animalsTotal } from '@/lib/animals-total';

describe('animalsTotal', () => {
  it('sums counts', () => {
    expect(animalsTotal([{ categoryId: 'a', count: 3 }, { categoryId: 'b', count: 5 }])).toBe(8);
  });
  it('returns 0 for empty', () => {
    expect(animalsTotal([])).toBe(0);
  });
});
