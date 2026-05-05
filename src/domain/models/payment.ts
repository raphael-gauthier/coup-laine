import { z } from 'zod';

export const Payment = z.object({
  methodId: z.string().nullable(),
  methodLabelSnapshot: z.string().nullable(),
  isPaid: z.boolean(),
  paidAt: z.string().nullable(),
  note: z.string().nullable(),
});

export type Payment = z.infer<typeof Payment>;

export const EMPTY_PAYMENT: Payment = {
  methodId: null,
  methodLabelSnapshot: null,
  isPaid: false,
  paidAt: null,
  note: null,
};
