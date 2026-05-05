import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { TourRepository } from '@/data/repositories/tour-repository';
import { ClientRepository } from '@/data/repositories/client-repository';
import type { Tour, TourStatus } from '@/domain/models/tour';
import type { TourStop } from '@/domain/models/tour-stop';
import { newId } from '@/lib/id';
import { mutationErrorToast } from '@/ui/components/error-toast';
import i18n from '@/i18n';

const tourRepo = new TourRepository(db);
const clientRepo = new ClientRepository(db);

export const toursKeys = {
  all: ['tours'] as const,
  list: (status?: TourStatus) => [...toursKeys.all, 'list', status ?? 'all'] as const,
  byId: (id: string) => [...toursKeys.all, 'byId', id] as const,
};

export function useTours(status?: TourStatus) {
  return useQuery({
    queryKey: toursKeys.list(status),
    queryFn: async () => (status ? tourRepo.listByStatus(status) : tourRepo.listAll()),
  });
}

export function useTour(id: string | undefined) {
  return useQuery({
    queryKey: toursKeys.byId(id ?? ''),
    queryFn: () => (id ? tourRepo.byId(id) : Promise.resolve(null)),
    enabled: !!id,
  });
}

export interface UpsertTourStopInput {
  id?: string;
  clientId: string;
  clientNameSnapshot?: string | null;
  plannedServices: TourStop['plannedServices'];
  arrivalMinutes: number | null;
  estimatedMinutes: number | null;
  feeShareCents: number | null;
  notes: string | null;
}

export interface UpsertTourInput {
  id?: string;
  scheduledDate: string;
  departureTime: string;
  baseLat: number;
  baseLng: number;
  status: TourStatus;
  stops: UpsertTourStopInput[];
  totalDistanceKm: number | null;
  totalMinutes: number | null;
  totalTravelFeeCents: number | null;
}

export function useUpsertTour() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: UpsertTourInput) => {
      const now = new Date().toISOString();
      const existing = input.id ? await tourRepo.byId(input.id) : null;
      const tourId = input.id ?? newId();
      const tour: Tour = {
        id: tourId,
        scheduledDate: input.scheduledDate,
        departureTime: input.departureTime,
        baseLat: input.baseLat,
        baseLng: input.baseLng,
        status: input.status,
        totalDistanceKm: input.totalDistanceKm,
        totalDriveSeconds: existing?.tour.totalDriveSeconds ?? null,
        totalMinutes: input.totalMinutes,
        totalRevenueCents: existing?.tour.totalRevenueCents ?? null,
        totalAnimalsCount: existing?.tour.totalAnimalsCount ?? null,
        totalTravelFeeCents: input.totalTravelFeeCents ?? existing?.tour.totalTravelFeeCents ?? null,
        routeGeometry: existing?.tour.routeGeometry ?? null,
        notes: existing?.tour.notes ?? null,
        completedAt: existing?.tour.completedAt ?? null,
        createdAt: existing?.tour.createdAt ?? now,
        updatedAt: now,
      };
      const stops: TourStop[] = input.stops.map((s, index) => ({
        id: s.id ?? newId(),
        tourId,
        clientId: s.clientId,
        clientNameSnapshot: s.clientNameSnapshot ?? null,
        ordering: index,
        arrivalMinutes: s.arrivalMinutes,
        departureMinutes: null,
        estimatedMinutes: s.estimatedMinutes,
        feeShareCents: s.feeShareCents,
        plannedServices: s.plannedServices,
        actualServices: null,
        notes: s.notes,
        completedAt: null,
      }));
      await tourRepo.upsertTour(tour, stops);
      return { tour, stops };
    },
    onSuccess: ({ tour }) => {
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      qc.removeQueries({ queryKey: toursKeys.byId(tour.id) });
    },
  });
}

export function useNextPlannedTourForClient(clientId: string | undefined) {
  return useQuery({
    queryKey: [...toursKeys.list('planned'), 'forClient', clientId ?? ''],
    queryFn: async () => {
      if (!clientId) return null;
      const planned = await tourRepo.listByStatus('planned');
      const matching = planned
        .filter(({ stops }) => stops.some((s) => s.clientId === clientId))
        .sort((a, b) => a.tour.scheduledDate.localeCompare(b.tour.scheduledDate));
      return matching[0] ?? null;
    },
    enabled: !!clientId,
  });
}

export function useDeleteTour() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => tourRepo.deleteTour(id),
    onSuccess: (_, id) => {
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      qc.removeQueries({ queryKey: toursKeys.byId(id) });
    },
  });
}

export function useCompleteWithBilan() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      tourId,
      perStopActuals,
      perStopNotes,
      completedAt,
    }: {
      tourId: string;
      perStopActuals: Map<string, TourStop['plannedServices']>;
      perStopNotes: Map<string, string | null>;
      completedAt: string;
    }) => {
      await tourRepo.completeWithBilan(tourId, perStopActuals, perStopNotes, completedAt);

      // Update client lastShearingDate + unmark waiting
      const result = await tourRepo.byId(tourId);
      if (result) {
        const clientIds = Array.from(new Set(result.stops.map((s) => s.clientId)));
        for (const cid of clientIds) {
          const client = await clientRepo.byId(cid);
          if (!client) continue;
          await clientRepo.upsert({
            ...client,
            lastShearingDate: result.tour.scheduledDate,
            isWaiting: false,
            updatedAt: completedAt,
          });
        }
      }
    },
    onSuccess: (_, { tourId }) => {
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      void qc.invalidateQueries({ queryKey: ['clients'] });
      qc.removeQueries({ queryKey: toursKeys.byId(tourId) });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('tours.errors.complete_failed_title'), err);
    },
  });
}

export function useCompleteTour() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ tourId, completedAt }: { tourId: string; completedAt: string }) => {
      const result = await tourRepo.byId(tourId);
      if (!result) throw new Error('Tour introuvable');
      const { tour, stops } = result;

      for (const s of stops) {
        await tourRepo.markStopCompleted(s.id, completedAt);
      }

      await tourRepo.upsertTour(
        { ...tour, status: 'completed', completedAt, updatedAt: completedAt },
        stops.map((s) => ({ ...s, completedAt }))
      );

      const clientIds = Array.from(new Set(stops.map((s) => s.clientId)));
      for (const cid of clientIds) {
        const client = await clientRepo.byId(cid);
        if (!client) continue;
        await clientRepo.upsert({
          ...client,
          lastShearingDate: tour.scheduledDate,
          isWaiting: false,
          updatedAt: completedAt,
        });
      }

      return { tour, stops };
    },
    onSuccess: ({ tour }) => {
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      void qc.invalidateQueries({ queryKey: ['clients'] });
      qc.removeQueries({ queryKey: toursKeys.byId(tour.id) });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('tours.errors.complete_failed_title'), err);
    },
  });
}
