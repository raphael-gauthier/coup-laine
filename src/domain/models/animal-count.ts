import { z } from 'zod';

export const AnimalCount = z.object({
  categoryId: z.string(),
  count: z.number().int().nonnegative(),
});

export type AnimalCount = z.infer<typeof AnimalCount>;

export const AnimalCountList = z.array(AnimalCount);
export type AnimalCountList = z.infer<typeof AnimalCountList>;
