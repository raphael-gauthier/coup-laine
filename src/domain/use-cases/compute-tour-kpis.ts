import { aggregateServices, type ServiceAggregate } from './aggregate-services';
import type { TourStopService } from '@/domain/models/tour-stop-service';

interface Stop {
  clientId: string;
  plannedServices: TourStopService[];
}

interface Input {
  stops: Stop[];
  totalDistanceKm: number;
  totalDriveSeconds: number;
  totalTravelFeeCents: number;
  /** Map clientId → animals total (for the tour's animals KPI). */
  animalCountsByClient: Map<string, number>;
}

export interface TourKpis {
  stopCount: number;
  animalsTotal: number;
  revenueCents: number;
  durationMinutes: number;
  driveMinutes: number;
  travelFeeCents: number;
  distanceKm: number;
  serviceAggregates: ServiceAggregate[];
}

export function computeTourKpis({
  stops, totalDistanceKm, totalDriveSeconds, totalTravelFeeCents, animalCountsByClient,
}: Input): TourKpis {
  if (stops.length === 0) {
    return {
      stopCount: 0,
      animalsTotal: 0,
      revenueCents: 0,
      durationMinutes: 0,
      driveMinutes: 0,
      travelFeeCents: 0,
      distanceKm: 0,
      serviceAggregates: [],
    };
  }
  const aggregates = aggregateServices(stops.map((s) => s.plannedServices));
  const revenueCents = aggregates.reduce((s, a) => s + a.totalRevenueCents, 0);
  const serviceMinutes = aggregates.reduce((s, a) => s + a.totalMinutes, 0);
  const driveMinutes = Math.round(totalDriveSeconds / 60);
  const animalsTotal = stops.reduce((s, stop) => s + (animalCountsByClient.get(stop.clientId) ?? 0), 0);
  return {
    stopCount: stops.length,
    animalsTotal,
    revenueCents,
    durationMinutes: driveMinutes + serviceMinutes,
    driveMinutes,
    travelFeeCents: totalTravelFeeCents,
    distanceKm: totalDistanceKm,
    serviceAggregates: aggregates,
  };
}
