import { z } from 'zod';

export const Prestation = z.object({
  id: z.string(),
  label: z.string(),
  priceCents: z.number().int().nonnegative().nullable(),
  minutes: z.number().int().nonnegative(),
  categoryId: z.string().nullable(),
  isActive: z.boolean(),
  archivedAt: z.string().nullable(),
  ordering: z.number().int(),
});

export type Prestation = z.infer<typeof Prestation>;
