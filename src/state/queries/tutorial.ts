import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { TutorialProgressRepository } from '@/data/repositories/tutorial-progress-repository';
import type { TutorialKey } from '@/domain/tutorial/keys';
import { resetSessionDiscoveryFlag } from '@/ui/help/session-store';

const repo = new TutorialProgressRepository(db);

export const tutorialKeys = {
  all: ['tutorial'] as const,
  list: ['tutorial', 'list'] as const,
};

interface TutorialProgressMap {
  seen: ReadonlySet<string>;
  count: number;
}

export function useTutorialProgress() {
  return useQuery<TutorialProgressMap>({
    queryKey: tutorialKeys.list,
    queryFn: async () => {
      const rows = await repo.list();
      return { seen: new Set(rows.map((r) => r.key)), count: rows.length };
    },
  });
}

export function useIsTutorialSeen(key: TutorialKey): boolean {
  const { data } = useTutorialProgress();
  return data?.seen.has(key) ?? false;
}

export function useMarkTutorialSeen() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (key: TutorialKey) => {
      await repo.markSeen(key, new Date().toISOString());
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: tutorialKeys.list });
    },
  });
}

export function useResetTutorials() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      await repo.resetAll();
    },
    onSuccess: () => {
      resetSessionDiscoveryFlag();
      qc.invalidateQueries({ queryKey: tutorialKeys.list });
    },
  });
}
