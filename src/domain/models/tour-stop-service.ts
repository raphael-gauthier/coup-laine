import { z } from 'zod';

export const TourStopService = z.object({
  serviceId: z.string(),
  qty: z.number().int().nonnegative(),
  nameSnapshot: z.string(),
  priceCentsSnapshot: z.number().int().nonnegative(),
  minutesSnapshot: z.number().int().nonnegative(),
  categoryIdSnapshot: z.string().nullable(),
  categoryNameSnapshot: z.string().nullable(),
  speciesNameSnapshot: z.string().nullable(),
});

export type TourStopService = z.infer<typeof TourStopService>;
