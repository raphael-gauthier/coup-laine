import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { TourRepository } from '@/data/repositories/tour-repository';
import { ClientRepository } from '@/data/repositories/client-repository';
import type { Tour, TourStatus } from '@/domain/models/tour';
import type { TourStop } from '@/domain/models/tour-stop';
import { newId } from '@/lib/id';
import { EMPTY_PAYMENT } from '@/domain/models/payment';
import type { Payment } from '@/domain/models/payment';
import { mutationErrorToast } from '@/ui/components/error-toast';
import i18n from '@/i18n';
import { assertTourInvariants } from '@/domain/use-cases/assert-tour-invariants';

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
  notes: string | null;
}

function buildStops(tourId: string, inputs: UpsertTourStopInput[]): TourStop[] {
  return inputs.map((s, index) => ({
    id: s.id ?? newId(),
    tourId,
    clientId: s.clientId,
    clientNameSnapshot: s.clientNameSnapshot ?? null,
    ordering: index,
    arrivalMinutes: s.arrivalMinutes,
    departureMinutes: null,
    estimatedMinutes: s.estimatedMinutes,
    travelFeeCents: null,
    plannedServices: s.plannedServices,
    actualServices: null,
    notes: s.notes,
    completedAt: null,
    payment: EMPTY_PAYMENT,
  }));
}

export interface SaveDraftInput {
  id?: string;
  title: string | null;
  baseLat: number;
  baseLng: number;
  stops: UpsertTourStopInput[];
  totalDistanceKm: number | null;
  totalMinutes: number | null;
}

export function useSaveDraft() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: SaveDraftInput) => {
      const now = new Date().toISOString();
      const existing = input.id ? await tourRepo.byId(input.id) : null;
      const tourId = input.id ?? newId();
      const tour: Tour = {
        id: tourId,
        scheduledDate: null,
        departureTime: null,
        title: input.title,
        baseLat: input.baseLat,
        baseLng: input.baseLng,
        status: 'draft',
        totalDistanceKm: input.totalDistanceKm,
        totalDriveSeconds: existing?.tour.totalDriveSeconds ?? null,
        totalMinutes: input.totalMinutes,
        totalRevenueCents: existing?.tour.totalRevenueCents ?? null,
        totalAnimalsCount: existing?.tour.totalAnimalsCount ?? null,
        routeGeometry: existing?.tour.routeGeometry ?? null,
        notes: existing?.tour.notes ?? null,
        completedAt: null,
        createdAt: existing?.tour.createdAt ?? now,
        updatedAt: now,
      };
      assertTourInvariants(tour);
      const stops = buildStops(tourId, input.stops);
      await tourRepo.upsertTour(tour, stops);
      return { tour, stops };
    },
    onSuccess: ({ tour }) => {
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      void qc.invalidateQueries({ queryKey: ['kpis'] });
      qc.removeQueries({ queryKey: toursKeys.byId(tour.id) });
    },
  });
}

export interface ScheduleTourInput {
  id?: string;
  title: string | null;
  scheduledDate: string;
  departureTime: string;
  baseLat: number;
  baseLng: number;
  stops: UpsertTourStopInput[];
  totalDistanceKm: number | null;
  totalMinutes: number | null;
}

export function useScheduleTour() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: ScheduleTourInput) => {
      const now = new Date().toISOString();
      const existing = input.id ? await tourRepo.byId(input.id) : null;
      const tourId = input.id ?? newId();
      const tour: Tour = {
        id: tourId,
        scheduledDate: input.scheduledDate,
        departureTime: input.departureTime,
        title: input.title,
        baseLat: input.baseLat,
        baseLng: input.baseLng,
        status: 'planned',
        totalDistanceKm: input.totalDistanceKm,
        totalDriveSeconds: existing?.tour.totalDriveSeconds ?? null,
        totalMinutes: input.totalMinutes,
        totalRevenueCents: existing?.tour.totalRevenueCents ?? null,
        totalAnimalsCount: existing?.tour.totalAnimalsCount ?? null,
        routeGeometry: existing?.tour.routeGeometry ?? null,
        notes: existing?.tour.notes ?? null,
        completedAt: null,
        createdAt: existing?.tour.createdAt ?? now,
        updatedAt: now,
      };
      assertTourInvariants(tour);
      const stops = buildStops(tourId, input.stops);
      await tourRepo.upsertTour(tour, stops);
      return { tour, stops };
    },
    onSuccess: ({ tour }) => {
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      void qc.invalidateQueries({ queryKey: ['clients'] });
      void qc.invalidateQueries({ queryKey: ['kpis'] });
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
        .sort((a, b) =>
          (a.tour.scheduledDate ?? '').localeCompare(b.tour.scheduledDate ?? ''),
        );
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
      void qc.invalidateQueries({ queryKey: ['clients'] });
      void qc.invalidateQueries({ queryKey: ['kpis'] });
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
      perStopPayments,
      perStopTravelFees,
      completedAt,
    }: {
      tourId: string;
      perStopActuals: Map<string, TourStop['plannedServices']>;
      perStopNotes: Map<string, string | null>;
      perStopPayments: Map<string, Payment>;
      perStopTravelFees: Map<string, number>;
      completedAt: string;
    }) => {
      await tourRepo.completeWithBilan(tourId, perStopActuals, perStopNotes, perStopPayments, perStopTravelFees, completedAt);

      // Update client lastShearingDate + unmark waiting
      const result = await tourRepo.byId(tourId);
      if (result) {
        const clientIds = Array.from(new Set(result.stops.map((s) => s.clientId)));
        for (const cid of clientIds) {
          const client = await clientRepo.byId(cid);
          if (!client) continue;
          await clientRepo.upsert({
            ...client,
            lastShearingDate: result.tour.scheduledDate ?? completedAt.slice(0, 10),
            isWaiting: false,
            updatedAt: completedAt,
          });
        }
      }
    },
    onSuccess: (_, { tourId }) => {
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      void qc.invalidateQueries({ queryKey: ['clients'] });
      void qc.invalidateQueries({ queryKey: ['kpis'] });
      void qc.invalidateQueries({ queryKey: ['history'] });
      qc.removeQueries({ queryKey: toursKeys.byId(tourId) });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('tours.errors.complete_failed_title'), err);
    },
  });
}

export function useMarkStopPayment() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ stopId, tourId: _tourId, payment }: { stopId: string; tourId: string; payment: Payment }) => {
      await tourRepo.markStopPayment(stopId, payment);
    },
    onSuccess: (_, { tourId }) => {
      void qc.invalidateQueries({ queryKey: toursKeys.byId(tourId) });
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      void qc.invalidateQueries({ queryKey: ['clients'] });
      void qc.invalidateQueries({ queryKey: ['history'] });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('payments.errors.save_failed_title'), err);
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
          lastShearingDate: tour.scheduledDate ?? completedAt.slice(0, 10),
          isWaiting: false,
          updatedAt: completedAt,
        });
      }

      return { tour, stops };
    },
    onSuccess: ({ tour }) => {
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      void qc.invalidateQueries({ queryKey: ['clients'] });
      void qc.invalidateQueries({ queryKey: ['kpis'] });
      void qc.invalidateQueries({ queryKey: ['history'] });
      qc.removeQueries({ queryKey: toursKeys.byId(tour.id) });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('tours.errors.complete_failed_title'), err);
    },
  });
}
