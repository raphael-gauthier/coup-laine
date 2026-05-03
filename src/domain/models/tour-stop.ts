import { z } from 'zod';
import { TourStopPrestation } from './tour-stop-prestation';

export const TourStop = z.object({
  id: z.string(),
  tourId: z.string(),
  clientId: z.string(),
  ordering: z.number().int(),
  arrivalTime: z.string().nullable(),
  estimatedMinutes: z.number().int().nullable(),
  prestations: z.array(TourStopPrestation),
  notes: z.string().nullable(),
  completedAt: z.string().nullable(),
});

export type TourStop = z.infer<typeof TourStop>;
