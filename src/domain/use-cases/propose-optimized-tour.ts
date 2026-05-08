import type { MatrixCoord } from '@/infra/services/ors-routing';
import type { ResolvedMatrix } from '@/state/queries/distance-matrix';
import { optimizeTourOrder } from '@/domain/use-cases/tour-order-optimizer';

export interface ProposeOptimizedTourInput {
  baseCoord: { lat: number; lon: number };
  candidates: { id: string; lat: number; lon: number }[];
  resolveMatrix: (coords: MatrixCoord[]) => Promise<ResolvedMatrix>;
}

export interface ProposeOptimizedTourResult {
  orderedIds: string[];
}

export async function proposeOptimizedTour(
  input: ProposeOptimizedTourInput,
): Promise<ProposeOptimizedTourResult> {
  const coords: MatrixCoord[] = [
    { id: 'BASE', lat: input.baseCoord.lat, lon: input.baseCoord.lon },
    ...input.candidates.map((c) => ({ id: c.id, lat: c.lat, lon: c.lon })),
  ];
  const result = await input.resolveMatrix(coords);
  const distanceKm = (from: string, to: string) =>
    result.matrix.get(`${from}-${to}`)?.distanceKm ?? 0;
  const orderedIds = optimizeTourOrder({
    stopIds: input.candidates.map((c) => c.id),
    distanceKm,
  });
  return { orderedIds };
}
