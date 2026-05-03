import { z } from 'zod';

export const Prestation = z.object({
  id: z.string(),
  label: z.string(),
  price: z.number().nullable(),
  isActive: z.boolean(),
  ordering: z.number().int(),
});

export type Prestation = z.infer<typeof Prestation>;
