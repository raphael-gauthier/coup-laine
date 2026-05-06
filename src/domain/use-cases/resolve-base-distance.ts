import { haversineDistanceKm } from '@/lib/haversine-distance';
import type { Coordinates } from '@/domain/models/coordinates';

interface CachedDistance {
  distanceKm: number;
  failed: boolean;
}

interface Input {
  base: Coordinates;
  client: Coordinates | null;
  /** Returns the cached entry for (base, client) or null if absent. */
  lookup: () => CachedDistance | null;
}

export function resolveBaseDistance({ base, client, lookup }: Input): number {
  if (!client) return 0;
  const cached = lookup();
  if (cached && !cached.failed) return cached.distanceKm;
  return haversineDistanceKm(base, client);
}
