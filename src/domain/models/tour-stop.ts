import { z } from 'zod';
import { TourStopService } from './tour-stop-service';
import { Payment } from './payment';

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
  plannedServices: z.array(TourStopService),
  actualServices: z.array(TourStopService).nullable(),
  notes: z.string().nullable(),
  completedAt: z.string().nullable(),
  payment: Payment,
});

export type TourStop = z.infer<typeof TourStop>;
