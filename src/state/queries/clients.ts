import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { ClientRepository } from '@/data/repositories/client-repository';
import { TourRepository } from '@/data/repositories/tour-repository';
import { SettingsRepository } from '@/data/repositories/settings-repository';
import { computeClientStatus, type ClientStatus } from '@/domain/use-cases/client-status';
import { animalsTotal } from '@/lib/animals-total';
import type { Client } from '@/domain/models/client';
import { newId } from '@/lib/id';
import { errorToast } from '@/ui/components/error-toast';

const repo = new ClientRepository(db);

export const clientsKeys = {
  all: ['clients'] as const,
  list: (filter: ClientsFilter) => [...clientsKeys.all, 'list', filter] as const,
  byId: (id: string) => [...clientsKeys.all, 'byId', id] as const,
};

export type ClientsFilter = 'all' | 'waiting';

export function useClients(filter: ClientsFilter = 'all') {
  return useQuery({
    queryKey: clientsKeys.list(filter),
    queryFn: async () => {
      return filter === 'waiting' ? repo.listWaiting() : repo.listAll();
    },
  });
}

export function useClient(id: string | undefined) {
  return useQuery({
    queryKey: clientsKeys.byId(id ?? ''),
    queryFn: () => (id ? repo.byId(id) : Promise.resolve(null)),
    enabled: !!id,
  });
}

export interface UpsertClientInput {
  id?: string;
  displayName: string;
  phones: string[];
  addressLabel?: string | null;
  addressCity?: string | null;
  addressPostcode?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  isWaiting: boolean;
  animalCounts: { categoryId: string; count: number }[];
}

export function useUpsertClient() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: UpsertClientInput) => {
      const now = new Date().toISOString();
      const existing = input.id ? await repo.byId(input.id) : null;

      const addressChanged =
        existing != null &&
        (existing.latitude !== (input.latitude ?? null) ||
          existing.longitude !== (input.longitude ?? null));

      const client: Client = {
        id: input.id ?? newId(),
        displayName: input.displayName,
        phones: input.phones,
        addressLabel: input.addressLabel ?? null,
        addressCity: input.addressCity ?? null,
        addressPostcode: input.addressPostcode ?? null,
        latitude: input.latitude ?? null,
        longitude: input.longitude ?? null,
        isWaiting: input.isWaiting,
        isBanned: existing?.isBanned ?? false,
        needsDistanceRecompute:
          addressChanged || (input.latitude != null && existing == null)
            ? true
            : (existing?.needsDistanceRecompute ?? false),
        lastShearingDate: existing?.lastShearingDate ?? null,
        animalCounts: input.animalCounts,
        markerColorHex: existing?.markerColorHex ?? null,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      };
      await repo.upsert(client);
      return client;
    },
    onSuccess: (client) => {
      void qc.invalidateQueries({ queryKey: clientsKeys.all });
      qc.setQueryData(clientsKeys.byId(client.id), client);
    },
  });
}

export function useDeleteClient() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => repo.delete(id),
    onSuccess: (_, id) => {
      void qc.invalidateQueries({ queryKey: clientsKeys.all });
      qc.removeQueries({ queryKey: clientsKeys.byId(id) });
    },
  });
}

export function useToggleWaiting() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, isWaiting }: { id: string; isWaiting: boolean }) => {
      const now = new Date().toISOString();
      await repo.setWaiting(id, isWaiting, now);
    },
    onMutate: async ({ id, isWaiting }) => {
      await qc.cancelQueries({ queryKey: clientsKeys.all });
      const previous = qc.getQueryData<Client>(clientsKeys.byId(id));
      if (previous) {
        qc.setQueryData(clientsKeys.byId(id), { ...previous, isWaiting });
      }
      const allLists = qc.getQueriesData<Client[]>({ queryKey: [...clientsKeys.all, 'list'] });
      for (const [key, list] of allLists) {
        if (!list) continue;
        qc.setQueryData(
          key,
          list.map((c) => (c.id === id ? { ...c, isWaiting } : c))
        );
      }
      return { previous };
    },
    onError: (err, { id }, ctx) => {
      if (ctx?.previous) qc.setQueryData(clientsKeys.byId(id), ctx.previous);
      void qc.invalidateQueries({ queryKey: clientsKeys.all });
      errorToast('Action impossible', err instanceof Error ? err.message : undefined);
    },
    onSettled: () => {
      void qc.invalidateQueries({ queryKey: clientsKeys.all });
    },
  });
}

const tourRepo = new TourRepository(db);
const settingsRepo = new SettingsRepository(db);

export function useClientStatusMap() {
  return useQuery({
    queryKey: ['clients', 'statusMap'],
    queryFn: async (): Promise<Map<string, ClientStatus>> => {
      const clientsList = await repo.listAll();
      const seasonStartedAt = (await settingsRepo.get('season_started_at')) ?? '2025-05-01';
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
      const out = new Map<string, ClientStatus>();
      for (const c of clientsList) {
        out.set(c.id, computeClientStatus({
          isBanned: c.isBanned,
          isWaiting: c.isWaiting,
          animalsTotal: animalsTotal(c.animalCounts),
          seasonStartedAt,
          completedTourDates: completedByClient.get(c.id) ?? [],
          plannedTourDates: plannedByClient.get(c.id) ?? [],
        }));
      }
      return out;
    },
  });
}
