import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { TourRepository } from '@/data/repositories/tour-repository';
import { ManualHistoryRepository } from '@/data/repositories/manual-history-repository';
import { mergeClientHistory } from '@/domain/use-cases/merge-client-history';
import type { ManualHistoryEntry } from '@/domain/models/manual-history-entry';
import type { TourStopPrestation } from '@/domain/models/tour-stop-prestation';
import { newId } from '@/lib/id';
import { errorToast } from '@/ui/components/error-toast';

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
            prestations: s.actualPrestations ?? s.plannedPrestations,
            notes: s.notes,
          }))
      );

      const manualEntries = await manualRepo.listByClient(clientId);

      return mergeClientHistory({
        tourStopsWithDate,
        manualEntries: manualEntries.map((e) => ({
          id: e.id,
          date: e.date,
          prestations: e.prestations,
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
  prestations: TourStopPrestation[];
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
        prestations: input.prestations,
      };
      await manualRepo.upsert(entry);
      return entry;
    },
    onSuccess: (entry) => {
      void qc.invalidateQueries({ queryKey: historyKeys.byClient(entry.clientId) });
      void qc.invalidateQueries({ queryKey: historyKeys.manualByClient(entry.clientId) });
    },
    onError: (err) => {
      errorToast('Enregistrement impossible', err instanceof Error ? err.message : undefined);
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
    },
    onError: (err) => {
      errorToast('Suppression impossible', err instanceof Error ? err.message : undefined);
    },
  });
}
