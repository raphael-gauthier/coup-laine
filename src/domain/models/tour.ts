import { z } from 'zod';

export const TourStatus = z.enum(['planned', 'completed']);
export type TourStatus = z.infer<typeof TourStatus>;

export const Tour = z.object({
  id: z.string(),
  scheduledDate: z.string(),
  departureTime: z.string(),
  baseLat: z.number(),
  baseLng: z.number(),
  status: TourStatus,
  totalDistanceKm: z.number().nullable(),
  totalDriveSeconds: z.number().int().nullable(),
  totalMinutes: z.number().int().nullable(),
  totalRevenueCents: z.number().int().nullable(),
  totalAnimalsCount: z.number().int().nullable(),
  routeGeometry: z.string().nullable(),
  notes: z.string().nullable(),
  completedAt: z.string().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export type Tour = z.infer<typeof Tour>;
