import { z } from 'zod';

export const Species = z.object({
  id: z.string(),
  label: z.string(),
  iconKey: z.string().nullable(),
  ordering: z.number().int(),
  isCustom: z.boolean(),
  archivedAt: z.string().nullable(),
});

export type Species = z.infer<typeof Species>;
