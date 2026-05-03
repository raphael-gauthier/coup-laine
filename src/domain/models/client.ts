import { z } from 'zod';
import { AnimalCountList } from './animal-count';

export const Client = z.object({
  id: z.string(),
  displayName: z.string(),
  firstName: z.string().nullable(),
  lastName: z.string().nullable(),
  phones: z.array(z.string()),
  email: z.string().email().nullable(),
  addressLabel: z.string().nullable(),
  addressCity: z.string().nullable(),
  addressPostcode: z.string().nullable(),
  latitude: z.number().nullable(),
  longitude: z.number().nullable(),
  isWaiting: z.boolean(),
  notes: z.string().nullable(),
  lastShearingDate: z.string().nullable(),
  animalCounts: AnimalCountList,
  createdAt: z.string(),
  updatedAt: z.string(),
});

export type Client = z.infer<typeof Client>;
