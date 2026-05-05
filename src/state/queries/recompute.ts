import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import i18n from '@/i18n';
import { db } from '@/infra/db/client';
import { ClientRepository } from '@/data/repositories/client-repository';
import { DistanceMatrixSync } from '@/data/distance-matrix-sync';
import { errorToast, mutationErrorToast } from '@/ui/components/error-toast';

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
      mutationErrorToast(i18n.t('recompute.failed_title'), err);
    },
  });
}

export function useRecomputeAll() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () => sync.recomputeAllForBase(),
    onSuccess: ({ ok, failed }) => {
      void qc.invalidateQueries({ queryKey: recomputeKeys.pending });
      void qc.invalidateQueries({ queryKey: ['clients'] });
      if (failed > 0 && ok === 0) {
        errorToast(
          i18n.t('recompute.failed_title'),
          i18n.t('recompute.failed_message')
        );
      } else if (failed > 0) {
        errorToast(
          i18n.t('recompute.partial_title'),
          i18n.t('recompute.partial_success', { ok, failed })
        );
      }
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('recompute.failed_title'), err);
    },
  });
}
