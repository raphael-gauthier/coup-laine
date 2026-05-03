import type { TourStopPrestation } from '@/domain/models/tour-stop-prestation';

interface InputStop {
  clientId: string;
  plannedPrestations: TourStopPrestation[];
}

interface Input {
  departureTime: string;
  stops: InputStop[];
  travelMinutesBetween: (from: string, to: string) => number;
}

export interface ArrivalStop extends InputStop {
  arrivalTime: string;
  arrivalMinutes: number;
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

function serviceMinutes(stop: InputStop): number {
  return stop.plannedPrestations.reduce((sum, p) => sum + p.qty * p.minutesSnapshot, 0);
}

export function estimateTourArrivals(input: Input): ArrivalStop[] {
  const { departureTime, stops, travelMinutesBetween } = input;
  if (stops.length === 0) return [];

  const result: ArrivalStop[] = [];
  let cursor = parseHHmm(departureTime);
  let previousNode = 'BASE';

  for (const stop of stops) {
    cursor += travelMinutesBetween(previousNode, stop.clientId);
    const arrivalMinutes = cursor;
    const minutes = serviceMinutes(stop);
    result.push({
      ...stop,
      arrivalTime: formatHHmm(cursor),
      arrivalMinutes,
      estimatedMinutes: minutes,
    });
    cursor += minutes;
    previousNode = stop.clientId;
  }
  return result;
}
