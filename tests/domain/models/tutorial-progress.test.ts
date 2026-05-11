import { describe, it, expect } from 'vitest';
import { TutorialProgressRowSchema } from '@/domain/models/tutorial-progress';

describe('TutorialProgressRowSchema', () => {
  it('parses a well-formed row', () => {
    const parsed = TutorialProgressRowSchema.parse({
      key: 'sheet.clients',
      seenAt: '2026-05-11T10:00:00.000Z',
    });
    expect(parsed.key).toBe('sheet.clients');
    expect(parsed.seenAt).toBe('2026-05-11T10:00:00.000Z');
  });

  it('rejects a non-ISO seenAt', () => {
    expect(() =>
      TutorialProgressRowSchema.parse({ key: 'sheet.clients', seenAt: 'yesterday' }),
    ).toThrow();
  });
});
