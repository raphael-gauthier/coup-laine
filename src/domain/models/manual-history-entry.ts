import { z } from 'zod';
import { TourStopService } from './tour-stop-service';

export const ManualHistoryEntry = z.object({
  id: z.string(),
  clientId: z.string(),
  date: z.string(),
  notes: z.string().nullable(),
  services: z.array(TourStopService),
});

export type ManualHistoryEntry = z.infer<typeof ManualHistoryEntry>;
