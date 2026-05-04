import { useQuery } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { ClientRepository } from '@/data/repositories/client-repository';
import { TourRepository } from '@/data/repositories/tour-repository';
import { ManualHistoryRepository } from '@/data/repositories/manual-history-repository';
import { ServiceRepository } from '@/data/repositories/service-repository';
import { SettingsRepository } from '@/data/repositories/settings-repository';
import { computeClientKpis } from '@/domain/use-cases/compute-client-kpis';
import { computeTourKpis } from '@/domain/use-cases/compute-tour-kpis';
import { computeServiceKpis } from '@/domain/use-cases/compute-service-kpis';
import { computeMapKpis } from '@/domain/use-cases/compute-map-kpis';
import { computeClientStatus, type ClientStatus } from '@/domain/use-cases/client-status';
import { animalsTotal } from '@/lib/animals-total';

const clientRepo = new ClientRepository(db);
const tourRepo = new TourRepository(db);
const manualRepo = new ManualHistoryRepository(db);
const serviceRepo = new ServiceRepository(db);
const settingsRepo = new SettingsRepository(db);

export const kpisKeys = {
  client: (id: string) => ['kpis', 'client', id] as const,
  tour: (id: string) => ['kpis', 'tour', id] as const,
  services: ['kpis', 'services'] as const,
  map: ['kpis', 'map'] as const,
};

export function useClientKpis(clientId: string | undefined) {
  return useQuery({
    queryKey: kpisKeys.client(clientId ?? ''),
    queryFn: async () => {
      if (!clientId) return null;
      const completed = await tourRepo.listByStatus('completed');
      const tourStops = completed.flatMap(({ tour, stops }) =>
        stops
          .filter((s) => s.clientId === clientId)
          .map((s) => ({ date: tour.scheduledDate, services: s.actualServices ?? s.plannedServices }))
      );
      const manualEntries = await manualRepo.listByClient(clientId);
      const today = new Date().toISOString().slice(0, 10);
      return computeClientKpis({
        tourStops,
        manualEntries: manualEntries.map((e) => ({ date: e.date, services: e.services })),
        today,
      });
    },
    enabled: !!clientId,
  });
}

export function useTourKpis(tourId: string | undefined) {
  return useQuery({
    queryKey: kpisKeys.tour(tourId ?? ''),
    queryFn: async () => {
      if (!tourId) return null;
      const result = await tourRepo.byId(tourId);
      if (!result) return null;
      const { tour, stops } = result;
      const animalCountsByClient = new Map<string, number>();
      for (const s of stops) {
        const c = await clientRepo.byId(s.clientId);
        if (c) animalCountsByClient.set(s.clientId, animalsTotal(c.animalCounts));
      }
      return computeTourKpis({
        stops: stops.map((s) => ({
          clientId: s.clientId,
          plannedServices: s.actualServices ?? s.plannedServices,
        })),
        totalDistanceKm: tour.totalDistanceKm ?? 0,
        totalDriveSeconds: tour.totalDriveSeconds ?? 0,
        totalTravelFeeCents: tour.totalTravelFeeCents ?? 0,
        animalCountsByClient,
      });
    },
    enabled: !!tourId,
  });
}

export function useServiceKpis() {
  return useQuery({
    queryKey: kpisKeys.services,
    queryFn: async () => {
      const services = await serviceRepo.listAll();
      // Pull every intervention from this month
      const today = new Date().toISOString().slice(0, 10);
      const yyyymm = today.slice(0, 7);
      const completedTours = await tourRepo.listByStatus('completed');
      const fromTours = completedTours.flatMap(({ tour, stops }) =>
        stops
          .filter(() => tour.scheduledDate.slice(0, 7) === yyyymm)
          .map((s) => ({ date: tour.scheduledDate, services: s.actualServices ?? s.plannedServices }))
      );
      // Note: manual entries this month would also count — for now, tours are the main source. Add manual later if needed.
      return computeServiceKpis({
        services,
        thisMonthInterventions: fromTours,
        today,
      });
    },
  });
}

export function useMapKpis() {
  return useQuery({
    queryKey: kpisKeys.map,
    queryFn: async () => {
      const clients = await clientRepo.listAll();
      const seasonStartedAt = (await settingsRepo.get('season_started_at')) ?? '2025-05-01';
      // Build maps of completed/planned tour dates per client
      const completed = await tourRepo.listByStatus('completed');
      const planned = await tourRepo.listByStatus('planned');
      const completedByClient = new Map<string, string[]>();
      const plannedByClient = new Map<string, string[]>();
      for (const { tour, stops } of completed) {
        for (const s of stops) {
          const arr = completedByClient.get(s.clientId) ?? [];
          arr.push(tour.scheduledDate);
          completedByClient.set(s.clientId, arr);
        }
      }
      for (const { tour, stops } of planned) {
        for (const s of stops) {
          const arr = plannedByClient.get(s.clientId) ?? [];
          arr.push(tour.scheduledDate);
          plannedByClient.set(s.clientId, arr);
        }
      }
      const statusByClientId = new Map<string, ClientStatus>();
      for (const c of clients) {
        const status = computeClientStatus({
          isBanned: c.isBanned,
          isWaiting: c.isWaiting,
          animalsTotal: animalsTotal(c.animalCounts),
          seasonStartedAt,
          completedTourDates: completedByClient.get(c.id) ?? [],
          plannedTourDates: plannedByClient.get(c.id) ?? [],
        });
        statusByClientId.set(c.id, status);
      }
      return computeMapKpis({ statusByClientId });
    },
  });
}
