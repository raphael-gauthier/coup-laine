import { z } from 'zod';
import { TourStopService } from './tour-stop-service';

export const InterventionSource = z.enum(['tour', 'manual']);

export const Intervention = z.object({
  source: InterventionSource,
  date: z.string(),
  services: z.array(TourStopService),
  travelFeeCents: z.number().int().nullable(),
  notes: z.string().nullable(),
  tourId: z.string().nullable(),
  tourStopId: z.string().nullable(),
  manualEntryId: z.string().nullable(),
});

export type Intervention = z.infer<typeof Intervention>;
