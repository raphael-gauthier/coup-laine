import { describe, it, expect } from 'vitest';
import { pluralize } from '@/lib/text-pluralization';

describe('pluralize (FR)', () => {
  it('singular for 0 in FR', () => expect(pluralize(0, 'client', 'clients')).toBe('client'));
  it('singular for 1', () => expect(pluralize(1, 'client', 'clients')).toBe('client'));
  it('plural for >1', () => expect(pluralize(2, 'client', 'clients')).toBe('clients'));
});
