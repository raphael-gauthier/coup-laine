import type { AnimalCount } from '@/domain/models/animal-count';

interface InputStop {
  clientId: string;
  animalCounts: AnimalCount[];
}

interface Input {
  departureTime: string;
  stops: InputStop[];
  travelMinutesBetween: (from: string, to: string) => number;
  categoryMinutes: Map<string, number>;
}

export interface ArrivalStop extends InputStop {
  arrivalTime: string;
  estimatedMinutes: number;
}

function parseHHmm(s: string): number {
  const [h, m] = s.split(':').map((x) => parseInt(x, 10));
  return (h ?? 0) * 60 + (m ?? 0);
}

function formatHHmm(totalMinutes: number): string {
  const wrapped = ((totalMinutes % 1440) + 1440) % 1440;
  const h = Math.floor(wrapped / 60);
  const m = wrapped % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

function serviceMinutes(stop: InputStop, categoryMinutes: Map<string, number>): number {
  let total = 0;
  for (const { categoryId, count } of stop.animalCounts) {
    total += (categoryMinutes.get(categoryId) ?? 0) * count;
  }
  return total;
}

export function estimateTourArrivals(input: Input): ArrivalStop[] {
  const { departureTime, stops, travelMinutesBetween, categoryMinutes } = input;
  if (stops.length === 0) return [];

  const result: ArrivalStop[] = [];
  let cursor = parseHHmm(departureTime);
  let previousNode = 'BASE';

  for (const stop of stops) {
    cursor += travelMinutesBetween(previousNode, stop.clientId);
    const minutes = serviceMinutes(stop, categoryMinutes);
    result.push({ ...stop, arrivalTime: formatHHmm(cursor), estimatedMinutes: minutes });
    cursor += minutes;
    previousNode = stop.clientId;
  }

  return result;
}
