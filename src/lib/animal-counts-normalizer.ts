import type { AnimalCount } from '@/domain/models/animal-count';

export function normalizeAnimalCounts(list: AnimalCount[]): AnimalCount[] {
  return list.filter((c) => c.count > 0);
}
