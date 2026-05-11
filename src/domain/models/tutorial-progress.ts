import { z } from 'zod';

export const TutorialProgressRowSchema = z.object({
  key: z.string(),
  seenAt: z.string().datetime(),
});

export type TutorialProgressRow = z.infer<typeof TutorialProgressRowSchema>;
