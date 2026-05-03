import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { ClientRepository } from '@/data/repositories/client-repository';
import { DistanceMatrixSync } from '@/data/distance-matrix-sync';
import { errorToast } from '@/ui/components/error-toast';

const clientRepo = new ClientRepository(db);
const sync = new DistanceMatrixSync(db);

export const recomputeKeys = {
  pending: ['recompute', 'pending'] as const,
};

export function useClientsPendingRecompute() {
  return useQuery({
    queryKey: recomputeKeys.pending,
    queryFn: async () => {
      const list = await clientRepo.listWithRecomputePending();
      return list;
    },
  });
}

export function useRecomputeForClient() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => sync.recomputeForClient(id),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: recomputeKeys.pending });
      void qc.invalidateQueries({ queryKey: ['clients'] });
    },
    onError: (err) => {
      errorToast('Recalcul impossible', err instanceof Error ? err.message : undefined);
    },
  });
}

export function useRecomputeAll() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () => sync.recomputeAllForBase(),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: recomputeKeys.pending });
      void qc.invalidateQueries({ queryKey: ['clients'] });
    },
    onError: (err) => {
      errorToast('Recalcul impossible', err instanceof Error ? err.message : undefined);
    },
  });
}
