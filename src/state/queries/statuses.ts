import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { StatusRepository } from '@/data/repositories/status-repository';
import { ClientRepository } from '@/data/repositories/client-repository';
import type { Status, SystemStatusKey } from '@/domain/models/status';
import { validateStatusLabel, validateColorPair } from '@/domain/use-cases/validate-status';
import { clientsKeys } from '@/state/queries/clients';

const repo = new StatusRepository(db);
const clientRepo = new ClientRepository(db);

export const statusesKeys = {
  all: ['statuses'] as const,
  list: ['statuses', 'list'] as const,
};

export interface StatusRegistry {
  list: Status[];
  bySystemKey(key: SystemStatusKey): Status;
  byId(id: string): Status | null;
}

export function useStatusRegistry() {
  return useQuery<StatusRegistry>({
    queryKey: statusesKeys.list,
    queryFn: async () => {
      const list = await repo.list();
      const bySys = new Map<SystemStatusKey, Status>();
      const byId = new Map<string, Status>();
      for (const s of list) {
        if (s.systemKey) bySys.set(s.systemKey, s);
        byId.set(s.id, s);
      }
      return {
        list,
        bySystemKey: (k) => {
          const r = bySys.get(k);
          if (!r) throw new Error(`System status missing: ${k}`);
          return r;
        },
        byId: (id) => byId.get(id) ?? null,
      };
    },
  });
}

export function useCreateManualStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: { label: string; colorLight: string; colorDark: string }) => {
      const labelV = validateStatusLabel(input.label);
      if (!labelV.ok) throw new Error('invalid_label');
      if (!validateColorPair({ light: input.colorLight, dark: input.colorDark })) {
        throw new Error('invalid_color');
      }
      return repo.createManual({ ...input, label: labelV.value });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: statusesKeys.list });
    },
  });
}

export function useRenameStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, label }: { id: string; label: string }) => {
      const v = validateStatusLabel(label);
      if (!v.ok) throw new Error('invalid_label');
      return repo.update(id, { label: v.value });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: statusesKeys.list });
      qc.invalidateQueries({ queryKey: clientsKeys.all });
    },
  });
}

export function useRecolorStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      id, colorLight, colorDark,
    }: { id: string; colorLight: string; colorDark: string }) => {
      if (!validateColorPair({ light: colorLight, dark: colorDark })) {
        throw new Error('invalid_color');
      }
      return repo.update(id, { colorLight, colorDark });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: statusesKeys.list });
      qc.invalidateQueries({ queryKey: clientsKeys.all });
    },
  });
}

export function useDeleteManualStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => repo.deleteManual(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: statusesKeys.list });
      qc.invalidateQueries({ queryKey: clientsKeys.all });
    },
  });
}

export function useAssignManualStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ clientId, statusId }: { clientId: string; statusId: string | null }) => {
      if (statusId !== null) {
        const row = await repo.byId(statusId);
        if (!row || row.kind !== 'manual') throw new Error('not_a_manual_status');
      }
      await clientRepo.setManualStatus(clientId, statusId, new Date().toISOString());
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: clientsKeys.all }),
  });
}

export function useCountClientsUsingStatus(id: string | null) {
  return useQuery({
    queryKey: ['statuses', 'count', id ?? ''],
    queryFn: async () => (id ? repo.countClientsUsing(id) : 0),
    enabled: !!id,
  });
}
