import type { AnimalCount } from '@/domain/models/animal-count';

export function mergeAnimalCounts(lists: AnimalCount[][]): AnimalCount[] {
  const order: string[] = [];
  const sums = new Map<string, number>();
  for (const list of lists) {
    for (const { categoryId, count } of list) {
      if (!sums.has(categoryId)) order.push(categoryId);
      sums.set(categoryId, (sums.get(categoryId) ?? 0) + count);
    }
  }
  return order.map((id) => ({ categoryId: id, count: sums.get(id)! }));
}
