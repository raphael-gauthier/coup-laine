import { z } from 'zod';

export const StatusKind = z.enum(['system', 'manual']);
export type StatusKind = z.infer<typeof StatusKind>;

export const SystemStatusKey = z.enum([
  'default', 'waiting', 'scheduled', 'done', 'noAnimals', 'banned',
]);
export type SystemStatusKey = z.infer<typeof SystemStatusKey>;

export const Status = z.object({
  id: z.string(),
  kind: StatusKind,
  systemKey: SystemStatusKey.nullable(),
  label: z.string(),
  colorLight: z.string(),
  colorDark: z.string(),
  sortOrder: z.number().int(),
  createdAt: z.string(),
});
export type Status = z.infer<typeof Status>;
