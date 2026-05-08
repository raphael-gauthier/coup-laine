import type { Tour } from '@/domain/models/tour';
import type { TourStop } from '@/domain/models/tour-stop';
import type { TourStopService } from '@/domain/models/tour-stop-service';
import { EMPTY_PAYMENT } from '@/domain/models/payment';

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
  stops,
  now,
  newId,
}: Input): Output {
  const tourId = newId();
  const tour: Tour = {
    id: tourId,
    scheduledDate,
    departureTime,
    title: null,
    baseLat: base.lat,
    baseLng: base.lon,
    status: 'planned',
    totalDistanceKm: null,
    totalDriveSeconds: null,
    totalMinutes: null,
    totalRevenueCents: null,
    totalAnimalsCount: null,
    routeGeometry: null,
    notes: null,
    completedAt: null,
    createdAt: now,
    updatedAt: now,
  };
  const tourStops: TourStop[] = stops.map((s, index) => ({
    id: newId(),
    tourId,
    clientId: s.clientId,
    clientNameSnapshot: s.clientNameSnapshot,
    ordering: index,
    arrivalMinutes: null,
    departureMinutes: null,
    estimatedMinutes: null,
    travelFeeCents: null,
    plannedServices: s.plannedServices,
    actualServices: null,
    notes: s.notes,
    completedAt: null,
    payment: EMPTY_PAYMENT,
  }));
  return { tour, stops: tourStops };
}
