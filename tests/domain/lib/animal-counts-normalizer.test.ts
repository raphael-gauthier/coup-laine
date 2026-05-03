import { describe, it, expect } from 'vitest';
import { normalizeAnimalCounts } from '@/lib/animal-counts-normalizer';

describe('normalizeAnimalCounts', () => {
  it('drops zero-count entries', () => {
    expect(normalizeAnimalCounts([
      { categoryId: 'a', count: 0 },
      { categoryId: 'b', count: 3 },
    ])).toEqual([{ categoryId: 'b', count: 3 }]);
  });

  it('returns empty for empty input', () => {
    expect(normalizeAnimalCounts([])).toEqual([]);
  });
});
