import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { ClientRepository } from '@/data/repositories/client-repository';
import type { Client } from '@/domain/models/client';
import { newId } from '@/lib/id';

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
  firstName?: string | null;
  lastName?: string | null;
  phones: string[];
  email?: string | null;
  addressLabel?: string | null;
  addressCity?: string | null;
  addressPostcode?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  isWaiting: boolean;
  notes?: string | null;
  animalCounts: { categoryId: string; count: number }[];
}

export function useUpsertClient() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: UpsertClientInput) => {
      const now = new Date().toISOString();
      const existing = input.id ? await repo.byId(input.id) : null;
      const client: Client = {
        id: input.id ?? newId(),
        displayName: input.displayName,
        firstName: input.firstName ?? null,
        lastName: input.lastName ?? null,
        phones: input.phones,
        email: input.email ?? null,
        addressLabel: input.addressLabel ?? null,
        addressCity: input.addressCity ?? null,
        addressPostcode: input.addressPostcode ?? null,
        latitude: input.latitude ?? null,
        longitude: input.longitude ?? null,
        isWaiting: input.isWaiting,
        notes: input.notes ?? null,
        lastShearingDate: existing?.lastShearingDate ?? null,
        animalCounts: input.animalCounts,
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
    onError: (_err, { id }, ctx) => {
      if (ctx?.previous) qc.setQueryData(clientsKeys.byId(id), ctx.previous);
      void qc.invalidateQueries({ queryKey: clientsKeys.all });
    },
    onSettled: () => {
      void qc.invalidateQueries({ queryKey: clientsKeys.all });
    },
  });
}
