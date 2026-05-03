import { z } from 'zod';
import { TourStopPrestation } from './tour-stop-prestation';

export const ManualHistoryEntry = z.object({
  id: z.string(),
  clientId: z.string(),
  date: z.string(),
  notes: z.string().nullable(),
  prestations: z.array(TourStopPrestation),
});

export type ManualHistoryEntry = z.infer<typeof ManualHistoryEntry>;
