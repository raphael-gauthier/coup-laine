import type { AnimalCount } from '@/domain/models/animal-count';

interface Stop {
  clientId: string;
  animalCounts: AnimalCount[];
}

interface Input {
  stops: Stop[];
  travelMinutesBetween: (from: string, to: string) => number;
  categoryMinutes: Map<string, number>;
}

export function estimateTourDuration({
  stops,
  travelMinutesBetween,
  categoryMinutes,
}: Input): number {
  if (stops.length === 0) return 0;

  let total = 0;
  let previousNode = 'BASE';
  for (const stop of stops) {
    total += travelMinutesBetween(previousNode, stop.clientId);
    for (const { categoryId, count } of stop.animalCounts) {
      const perUnit = categoryMinutes.get(categoryId) ?? 0;
      total += perUnit * count;
    }
    previousNode = stop.clientId;
  }
  return total;
}
