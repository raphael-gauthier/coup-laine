import { z } from 'zod';

export const PaymentMethod = z.object({
  id: z.string(),
  label: z.string(),
  isActive: z.boolean(),
  archivedAt: z.string().nullable(),
  ordering: z.number().int(),
});

export type PaymentMethod = z.infer<typeof PaymentMethod>;
