import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { TourRepository } from '@/data/repositories/tour-repository';
import { ManualHistoryRepository } from '@/data/repositories/manual-history-repository';
import { mergeClientHistory } from '@/domain/use-cases/merge-client-history';
import type { ManualHistoryEntry } from '@/domain/models/manual-history-entry';
import type { TourStopService } from '@/domain/models/tour-stop-service';
import { newId } from '@/lib/id';
import { EMPTY_PAYMENT } from '@/domain/models/payment';
import { kpisKeys } from '@/state/queries/kpis';
import { mutationErrorToast } from '@/ui/components/error-toast';
import i18n from '@/i18n';

const tourRepo = new TourRepository(db);
const manualRepo = new ManualHistoryRepository(db);

export const historyKeys = {
  byClient: (id: string) => ['history', 'byClient', id] as const,
  manualByClient: (id: string) => ['manualHistory', 'byClient', id] as const,
};

export function useClientHistory(clientId: string | undefined) {
  return useQuery({
    queryKey: historyKeys.byClient(clientId ?? ''),
    queryFn: async () => {
      if (!clientId) return [];

      const completed = await tourRepo.listByStatus('completed');
      const tourStopsWithDate = completed.flatMap(({ tour, stops }) =>
        stops
          .filter((s) => s.clientId === clientId)
          .map((s) => ({
            tourId: tour.id,
            stopId: s.id,
            date: tour.scheduledDate,
            services: s.actualServices ?? s.plannedServices,
            notes: s.notes,
          }))
      );

      const manualEntries = await manualRepo.listByClient(clientId);

      return mergeClientHistory({
        tourStopsWithDate,
        manualEntries: manualEntries.map((e) => ({
          id: e.id,
          date: e.date,
          services: e.services,
          notes: e.notes,
        })),
      });
    },
    enabled: !!clientId,
  });
}

export function useManualHistoryByClient(clientId: string | undefined) {
  return useQuery({
    queryKey: historyKeys.manualByClient(clientId ?? ''),
    queryFn: () => (clientId ? manualRepo.listByClient(clientId) : Promise.resolve([])),
    enabled: !!clientId,
  });
}

export interface UpsertManualHistoryInput {
  id?: string;
  clientId: string;
  date: string;
  notes: string | null;
  services: TourStopService[];
}

export function useUpsertManualHistoryEntry() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: UpsertManualHistoryInput) => {
      const entry: ManualHistoryEntry = {
        id: input.id ?? newId(),
        clientId: input.clientId,
        date: input.date,
        notes: input.notes,
        services: input.services,
        payment: EMPTY_PAYMENT,
      };
      await manualRepo.upsert(entry);
      return entry;
    },
    onSuccess: (entry) => {
      void qc.invalidateQueries({ queryKey: historyKeys.byClient(entry.clientId) });
      void qc.invalidateQueries({ queryKey: historyKeys.manualByClient(entry.clientId) });
      void qc.invalidateQueries({ queryKey: kpisKeys.client(entry.clientId) });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('history.errors.save_failed_title'), err);
    },
  });
}

export function useDeleteManualHistoryEntry() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id }: { id: string; clientId: string }) => {
      await manualRepo.delete(id);
    },
    onSuccess: (_, { clientId }) => {
      void qc.invalidateQueries({ queryKey: historyKeys.byClient(clientId) });
      void qc.invalidateQueries({ queryKey: historyKeys.manualByClient(clientId) });
      void qc.invalidateQueries({ queryKey: kpisKeys.client(clientId) });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('history.errors.delete_failed_title'), err);
    },
  });
}
