import { z } from 'zod';
import { TourStopPrestation } from './tour-stop-prestation';

export const TourStop = z.object({
  id: z.string(),
  tourId: z.string(),
  clientId: z.string(),
  clientNameSnapshot: z.string().nullable(),
  ordering: z.number().int(),
  arrivalMinutes: z.number().int().nullable(),
  departureMinutes: z.number().int().nullable(),
  estimatedMinutes: z.number().int().nullable(),
  feeShareCents: z.number().int().nullable(),
  plannedPrestations: z.array(TourStopPrestation),
  actualPrestations: z.array(TourStopPrestation).nullable(),
  notes: z.string().nullable(),
  completedAt: z.string().nullable(),
});

export type TourStop = z.infer<typeof TourStop>;
