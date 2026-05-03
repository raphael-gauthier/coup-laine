import { useMutation } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { DistanceMatrixRepository } from '@/data/repositories/distance-matrix-repository';
import { fetchDistanceMatrix, type MatrixCoord } from '@/infra/services/ors-routing';
import { haversineDistanceKm } from '@/lib/haversine-distance';

const repo = new DistanceMatrixRepository(db);

const TTL_DAYS = 90;
const STALE_MS = TTL_DAYS * 24 * 60 * 60 * 1000;

export interface ResolvedMatrix {
  matrix: Map<string, { distanceKm: number; durationMinutes: number; isEstimate: boolean }>;
  source: 'cache' | 'ors' | 'haversine';
}

export async function resolveDistanceMatrix(coords: MatrixCoord[]): Promise<ResolvedMatrix> {
  const cacheStaleBefore = new Date(Date.now() - STALE_MS).toISOString();
  await repo.deleteOlderThan(cacheStaleBefore);

  const matrix = new Map<string, { distanceKm: number; durationMinutes: number; isEstimate: boolean }>();
  let missing = false;

  for (let i = 0; i < coords.length; i++) {
    for (let j = 0; j < coords.length; j++) {
      if (i === j) continue;
      const from = coords[i]!;
      const to = coords[j]!;
      const cached = await repo.byPair(from.id, to.id);
      if (cached) {
        matrix.set(`${from.id}-${to.id}`, {
          distanceKm: cached.distanceKm,
          durationMinutes: cached.durationMinutes,
          isEstimate: false,
        });
      } else {
        missing = true;
      }
    }
  }

  if (!missing) {
    return { matrix, source: 'cache' };
  }

  try {
    const fresh = await fetchDistanceMatrix(coords);
    const now = new Date().toISOString();
    for (const r of fresh) {
      matrix.set(`${r.fromId}-${r.toId}`, {
        distanceKm: r.distanceKm,
        durationMinutes: r.durationMinutes,
        isEstimate: false,
      });
      await repo.upsert({
        fromId: r.fromId,
        toId: r.toId,
        distanceKm: r.distanceKm,
        durationMinutes: r.durationMinutes,
        fetchedAt: now,
        failed: false,
      });
    }
    return { matrix, source: 'ors' };
  } catch {
    for (let i = 0; i < coords.length; i++) {
      for (let j = 0; j < coords.length; j++) {
        if (i === j) continue;
        const from = coords[i]!;
        const to = coords[j]!;
        const d = haversineDistanceKm({ lat: from.lat, lon: from.lon }, { lat: to.lat, lon: to.lon });
        matrix.set(`${from.id}-${to.id}`, {
          distanceKm: d,
          durationMinutes: Math.round(d * 1.5),
          isEstimate: true,
        });
      }
    }
    return { matrix, source: 'haversine' };
  }
}

export function useResolveDistanceMatrix() {
  return useMutation({
    mutationFn: (coords: MatrixCoord[]) => resolveDistanceMatrix(coords),
  });
}
