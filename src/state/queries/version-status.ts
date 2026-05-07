import { useQuery } from '@tanstack/react-query';
import { getVersionConfig, type RepoResult } from '@/data/repositories/version-config-repository';
import type { Platform } from '@/domain/models/version-status';

export const versionStatusKeys = {
  config: (platform: Platform) => ['version-status', platform] as const,
};

const SIX_HOURS_MS = 6 * 60 * 60 * 1000;
const TWENTY_FOUR_HOURS_MS = 24 * 60 * 60 * 1000;

export function useVersionStatusQuery(platform: Platform | null) {
  return useQuery<RepoResult>({
    queryKey: platform ? versionStatusKeys.config(platform) : ['version-status', 'noop'],
    enabled: platform !== null,
    queryFn: () => getVersionConfig(platform!),
    staleTime: SIX_HOURS_MS,
    gcTime: TWENTY_FOUR_HOURS_MS,
    retry: 1,
  });
}
