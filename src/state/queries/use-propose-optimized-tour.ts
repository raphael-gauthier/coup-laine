import { useMutation } from '@tanstack/react-query';
import { useRouter } from 'expo-router';
import { proposeOptimizedTour } from '@/domain/use-cases/propose-optimized-tour';
import { useResolveDistanceMatrix } from '@/state/queries/distance-matrix';
import { useTourDraftStore } from '@/state/stores/tour-draft-store';

export interface ProposeTourInput {
  baseCoord: { lat: number; lon: number };
  candidates: { id: string; lat: number; lon: number }[];
}

export function useProposeOptimizedTour() {
  const resolve = useResolveDistanceMatrix();
  const reset = useTourDraftStore((s) => s.reset);
  const setOrder = useTourDraftStore((s) => s.setOrder);
  const router = useRouter();

  return useMutation({
    mutationFn: async (input: ProposeTourInput) => {
      const { orderedIds } = await proposeOptimizedTour({
        ...input,
        resolveMatrix: resolve.mutateAsync,
      });
      reset();
      setOrder(orderedIds);
      router.push('/tour-new/draft' as never);
    },
  });
}
