import { optimizeTourOrder } from './tour-order-optimizer';
import { buildTourDraft } from './build-tour-draft';
import type { Tour } from '@/domain/models/tour';
import type { TourStop } from '@/domain/models/tour-stop';

interface Input {
  scheduledDate: string;
  departureTime: string;
  base: { lat: number; lon: number };
  clientIds: string[];
  distanceKm: (from: string, to: string) => number;
  now: string;
  newId: () => string;
}

interface Output {
  tour: Tour;
  stops: TourStop[];
}

export function buildOptimizedTourProposal(input: Input): Output {
  const orderedIds = optimizeTourOrder({
    stopIds: input.clientIds,
    distanceKm: input.distanceKm,
  });
  return buildTourDraft({
    scheduledDate: input.scheduledDate,
    departureTime: input.departureTime,
    base: input.base,
    clientIds: orderedIds,
    now: input.now,
    newId: input.newId,
  });
}
