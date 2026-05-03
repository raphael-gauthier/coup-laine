import { z } from 'zod';

export const AnimalCategory = z.object({
  id: z.string(),
  speciesId: z.string(),
  label: z.string(),
  ordering: z.number().int(),
  isCustom: z.boolean(),
  archivedAt: z.string().nullable(),
});

export type AnimalCategory = z.infer<typeof AnimalCategory>;
