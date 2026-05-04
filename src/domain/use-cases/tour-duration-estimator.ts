import type { TourStopService } from '@/domain/models/tour-stop-service';

interface Stop {
  clientId: string;
  plannedServices: TourStopService[];
}

interface Input {
  stops: Stop[];
  travelMinutesBetween: (from: string, to: string) => number;
}

function serviceMinutes(stop: Stop): number {
  return stop.plannedServices.reduce((sum, p) => sum + p.qty * p.minutesSnapshot, 0);
}

export function estimateTourDuration({ stops, travelMinutesBetween }: Input): number {
  if (stops.length === 0) return 0;
  let total = 0;
  let previousNode = 'BASE';
  for (const stop of stops) {
    total += travelMinutesBetween(previousNode, stop.clientId);
    total += serviceMinutes(stop);
    previousNode = stop.clientId;
  }
  return total;
}
