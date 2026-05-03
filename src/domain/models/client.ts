import { z } from 'zod';
import { AnimalCountList } from './animal-count';

export const Client = z.object({
  id: z.string(),
  displayName: z.string(),
  phones: z.array(z.string()),
  addressLabel: z.string().nullable(),
  addressCity: z.string().nullable(),
  addressPostcode: z.string().nullable(),
  latitude: z.number().nullable(),
  longitude: z.number().nullable(),
  isWaiting: z.boolean(),
  isBanned: z.boolean(),
  needsDistanceRecompute: z.boolean(),
  lastShearingDate: z.string().nullable(),
  animalCounts: AnimalCountList,
  markerColorHex: z.string().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export type Client = z.infer<typeof Client>;
