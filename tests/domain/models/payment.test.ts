import { describe, it, expect } from 'vitest';
import { Payment } from '@/domain/models/payment';

describe('Payment', () => {
  it('parses a paid payment with all fields', () => {
    const p = Payment.parse({
      methodId: 'pm-cash',
      methodLabelSnapshot: 'Espèces',
      isPaid: true,
      paidAt: '2026-05-05T10:00:00Z',
    });
    expect(p.isPaid).toBe(true);
    expect(p.methodLabelSnapshot).toBe('Espèces');
  });

  it('parses an unpaid payment with nullable fields', () => {
    const p = Payment.parse({
      methodId: null,
      methodLabelSnapshot: null,
      isPaid: false,
      paidAt: null,
    });
    expect(p.isPaid).toBe(false);
    expect(p.methodId).toBeNull();
  });

  it('parses a backfilled paid row with null methodId (legacy data)', () => {
    // Pre-feature stops are migrated to isPaid=true, methodId=null.
    // The schema must remain permissive for this case.
    const p = Payment.parse({
      methodId: null,
      methodLabelSnapshot: null,
      isPaid: true,
      paidAt: '2026-04-12T00:00:00Z',
    });
    expect(p.isPaid).toBe(true);
    expect(p.methodId).toBeNull();
  });
});
