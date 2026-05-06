import { aggregateServices, type ServiceAggregate } from './aggregate-services';
import type { TourStopService } from '@/domain/models/tour-stop-service';

interface Stop {
  clientId: string;
  plannedServices: TourStopService[];
  travelFeeCents: number | null;
}

interface Input {
  stops: Stop[];
  totalDistanceKm: number;
  totalDriveSeconds: number;
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
  stops, totalDistanceKm, totalDriveSeconds, animalCountsByClient,
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
  const servicesRevenue = aggregates.reduce((s, a) => s + a.totalRevenueCents, 0);
  const travelFeeCents = stops.reduce((s, st) => s + (st.travelFeeCents ?? 0), 0);
  const serviceMinutes = aggregates.reduce((s, a) => s + a.totalMinutes, 0);
  const driveMinutes = Math.round(totalDriveSeconds / 60);
  const animalsTotal = stops.reduce((s, stop) => s + (animalCountsByClient.get(stop.clientId) ?? 0), 0);
  return {
    stopCount: stops.length,
    animalsTotal,
    revenueCents: servicesRevenue + travelFeeCents,
    durationMinutes: driveMinutes + serviceMinutes,
    driveMinutes,
    travelFeeCents,
    distanceKm: totalDistanceKm,
    serviceAggregates: aggregates,
  };
}
