import type { AnimalCount } from '@/domain/models/animal-count';

export function animalsTotal(counts: AnimalCount[]): number {
  return counts.reduce((sum, c) => sum + c.count, 0);
}
