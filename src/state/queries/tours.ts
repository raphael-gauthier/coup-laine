import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { TourRepository } from '@/data/repositories/tour-repository';
import { ClientRepository } from '@/data/repositories/client-repository';
import type { Tour, TourStatus } from '@/domain/models/tour';
import type { TourStop } from '@/domain/models/tour-stop';
import { newId } from '@/lib/id';
import { errorToast } from '@/ui/components/error-toast';

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

export interface UpsertTourInput {
  id?: string;
  scheduledDate: string;
  departureTime: string;
  baseLat: number;
  baseLng: number;
  status: TourStatus;
  stops: { id?: string; clientId: string; prestations: TourStop['prestations']; arrivalTime: string | null; estimatedMinutes: number | null; notes: string | null }[];
  totalDistanceKm: number | null;
  totalMinutes: number | null;
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
        totalMinutes: input.totalMinutes,
        createdAt: existing?.tour.createdAt ?? now,
        updatedAt: now,
      };
      const stops: TourStop[] = input.stops.map((s, index) => ({
        id: s.id ?? newId(),
        tourId,
        clientId: s.clientId,
        ordering: index,
        arrivalTime: s.arrivalTime,
        estimatedMinutes: s.estimatedMinutes,
        prestations: s.prestations,
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
        { ...tour, status: 'completed', updatedAt: completedAt },
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
      errorToast('Clôture impossible', err instanceof Error ? err.message : undefined);
    },
  });
}
