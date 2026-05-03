import { z } from 'zod';

export const DistanceMatrixEntry = z.object({
  fromId: z.string(),
  toId: z.string(),
  distanceKm: z.number().nonnegative(),
  durationMinutes: z.number().int().nonnegative(),
  fetchedAt: z.string(),
});

export type DistanceMatrixEntry = z.infer<typeof DistanceMatrixEntry>;
