import { z } from 'zod';

export const AnimalCategory = z.object({
  id: z.string(),
  speciesId: z.string(),
  label: z.string(),
  averageMinutesPerUnit: z.number().nonnegative(),
  ordering: z.number().int(),
  isCustom: z.boolean(),
});

export type AnimalCategory = z.infer<typeof AnimalCategory>;
