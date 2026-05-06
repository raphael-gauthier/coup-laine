import { z } from 'zod';
import { TourStopService } from './tour-stop-service';
import { Payment } from './payment';

export const ManualHistoryEntry = z.object({
  id: z.string(),
  clientId: z.string(),
  date: z.string(),
  notes: z.string().nullable(),
  services: z.array(TourStopService),
  travelFeeCents: z.number().int().nullable(),
  payment: Payment,
});

export type ManualHistoryEntry = z.infer<typeof ManualHistoryEntry>;
