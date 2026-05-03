import type { Tour } from '@/domain/models/tour';
import type { TourStop } from '@/domain/models/tour-stop';

interface Input {
  scheduledDate: string;
  departureTime: string;
  base: { lat: number; lon: number };
  clientIds: string[];
  now: string;
  newId: () => string;
}

interface Output {
  tour: Tour;
  stops: TourStop[];
}

export function buildTourDraft({
  scheduledDate,
  departureTime,
  base,
  clientIds,
  now,
  newId,
}: Input): Output {
  const tourId = newId();
  const tour: Tour = {
    id: tourId,
    scheduledDate,
    departureTime,
    baseLat: base.lat,
    baseLng: base.lon,
    status: 'draft',
    totalDistanceKm: null,
    totalMinutes: null,
    createdAt: now,
    updatedAt: now,
  };
  const stops: TourStop[] = clientIds.map((clientId, index) => ({
    id: newId(),
    tourId,
    clientId,
    ordering: index,
    arrivalTime: null,
    estimatedMinutes: null,
    prestations: [],
    notes: null,
    completedAt: null,
  }));
  return { tour, stops };
}
