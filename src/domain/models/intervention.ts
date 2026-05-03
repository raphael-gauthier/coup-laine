import { z } from 'zod';
import { TourStopPrestation } from './tour-stop-prestation';

export const InterventionSource = z.enum(['tour', 'manual']);

export const Intervention = z.object({
  source: InterventionSource,
  date: z.string(),
  prestations: z.array(TourStopPrestation),
  notes: z.string().nullable(),
  tourId: z.string().nullable(),
  tourStopId: z.string().nullable(),
  manualEntryId: z.string().nullable(),
});

export type Intervention = z.infer<typeof Intervention>;
