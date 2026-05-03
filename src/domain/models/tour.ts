import { z } from 'zod';

export const TourStatus = z.enum(['draft', 'planned', 'completed']);
export type TourStatus = z.infer<typeof TourStatus>;

export const Tour = z.object({
  id: z.string(),
  scheduledDate: z.string(),
  departureTime: z.string(),
  baseLat: z.number(),
  baseLng: z.number(),
  status: TourStatus,
  totalDistanceKm: z.number().nullable(),
  totalMinutes: z.number().int().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export type Tour = z.infer<typeof Tour>;
