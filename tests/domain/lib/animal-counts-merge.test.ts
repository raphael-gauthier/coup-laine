import { describe, it, expect } from 'vitest';
import { mergeAnimalCounts } from '@/lib/animal-counts-merge';

describe('mergeAnimalCounts', () => {
  it('returns empty for empty input', () => {
    expect(mergeAnimalCounts([])).toEqual([]);
  });

  it('sums counts by categoryId', () => {
    const result = mergeAnimalCounts([
      [{ categoryId: 'a', count: 3 }],
      [{ categoryId: 'a', count: 2 }, { categoryId: 'b', count: 5 }],
    ]);
    expect(result).toEqual([
      { categoryId: 'a', count: 5 },
      { categoryId: 'b', count: 5 },
    ]);
  });

  it('preserves first-seen ordering', () => {
    const result = mergeAnimalCounts([
      [{ categoryId: 'b', count: 1 }],
      [{ categoryId: 'a', count: 1 }],
    ]);
    expect(result.map((c) => c.categoryId)).toEqual(['b', 'a']);
  });
});
