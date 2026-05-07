import * as SecureStore from 'expo-secure-store';
import type { Platform, VersionConfig } from '@/domain/models/version-status';
import { fetchVersionConfig } from '@/infra/services/version-check-api';

const CACHE_KEY = (p: Platform) => `version-gate.cache.${p}`;

type CacheEntry = { config: VersionConfig; fetchedAt: number };

export type RepoResult =
  | { status: 'fresh'; config: VersionConfig }
  | { status: 'stale'; config: VersionConfig }
  | { status: 'unavailable'; config: null };

async function readCache(platform: Platform): Promise<CacheEntry | null> {
  const raw = await SecureStore.getItemAsync(CACHE_KEY(platform));
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as CacheEntry;
    if (!parsed?.config || typeof parsed.fetchedAt !== 'number') return null;
    return parsed;
  } catch {
    return null;
  }
}

async function writeCache(platform: Platform, config: VersionConfig): Promise<void> {
  const entry: CacheEntry = { config, fetchedAt: Date.now() };
  await SecureStore.setItemAsync(CACHE_KEY(platform), JSON.stringify(entry));
}

/**
 * For tests only. Cache resets are otherwise unnecessary because the
 * mocked SecureStore is reset by the test harness.
 */
export function __resetForTests(): void {
  // No in-memory state to reset for now — placeholder for future memoization.
}

export async function getVersionConfig(platform: Platform): Promise<RepoResult> {
  const cache = await readCache(platform);
  try {
    const fetched = await fetchVersionConfig(platform);
    if (fetched) {
      await writeCache(platform, fetched);
      return { status: 'fresh', config: fetched };
    }
    // 404 from API — platform not configured server-side. Honor cache if any.
    if (cache) return { status: 'stale', config: cache.config };
    return { status: 'unavailable', config: null };
  } catch {
    if (cache) return { status: 'stale', config: cache.config };
    return { status: 'unavailable', config: null };
  }
}
