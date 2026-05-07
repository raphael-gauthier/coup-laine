import { useQuery } from '@tanstack/react-query';
import * as Sentry from '@sentry/react-native';
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
    queryFn: async () => {
      try {
        return await getVersionConfig(platform!);
      } catch (e) {
        Sentry.addBreadcrumb({
          category: 'version-gate',
          level: 'warning',
          message: 'version-gate.check.failure',
          data: { platform, errorKind: classifyError(e) },
        });
        throw e;
      }
    },
    staleTime: SIX_HOURS_MS,
    gcTime: TWENTY_FOUR_HOURS_MS,
    retry: 1,
  });
}

function classifyError(err: unknown): string {
  const msg = err instanceof Error ? err.message : String(err);
  if (msg.includes('aborted') || msg.toLowerCase().includes('timeout')) return 'timeout';
  if (/\b5\d{2}\b/.test(msg)) return 'http_5xx';
  if (/\b4\d{2}\b/.test(msg)) return 'http_4xx';
  if (msg.toLowerCase().includes('invalid')) return 'parse';
  return 'network';
}
