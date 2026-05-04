import { optimizeTourOrder } from './tour-order-optimizer';
import { buildTourDraft } from './build-tour-draft';
import type { Tour } from '@/domain/models/tour';
import type { TourStop } from '@/domain/models/tour-stop';
import type { TourStopService } from '@/domain/models/tour-stop-service';

interface InputStop {
  clientId: string;
  clientNameSnapshot: string | null;
  plannedServices: TourStopService[];
  notes: string | null;
}

interface Input {
  scheduledDate: string;
  departureTime: string;
  base: { lat: number; lon: number };
  stops: InputStop[];
  distanceKm: (from: string, to: string) => number;
  now: string;
  newId: () => string;
}

interface Output {
  tour: Tour;
  stops: TourStop[];
}

export function buildOptimizedTourProposal(input: Input): Output {
  const stopIds = input.stops.map((s) => s.clientId);
  const orderedIds = optimizeTourOrder({
    stopIds,
    distanceKm: input.distanceKm,
  });
  const stopByClientId = new Map(input.stops.map((s) => [s.clientId, s]));
  const orderedStops = orderedIds
    .map((id) => stopByClientId.get(id))
    .filter((s): s is InputStop => s != null);
  return buildTourDraft({
    scheduledDate: input.scheduledDate,
    departureTime: input.departureTime,
    base: input.base,
    stops: orderedStops,
    now: input.now,
    newId: input.newId,
  });
}
