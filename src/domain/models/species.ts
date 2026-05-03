import { z } from 'zod';

export const Species = z.object({
  id: z.string(),
  label: z.string(),
  color: z.string().nullable(),
  ordering: z.number().int(),
  isCustom: z.boolean(),
});

export type Species = z.infer<typeof Species>;
