import { describe, it, expect } from 'vitest';
import { findCommunesWithWaiting } from '@/domain/use-cases/find-communes-with-waiting';

describe('findCommunesWithWaiting', () => {
  it('groups waiting clients by city, sorted by count desc then name asc', () => {
    const r = findCommunesWithWaiting([
      { id: '1', isWaiting: true, addressCity: 'Quimper' },
      { id: '2', isWaiting: true, addressCity: 'Brest' },
      { id: '3', isWaiting: true, addressCity: 'Quimper' },
      { id: '4', isWaiting: false, addressCity: 'Vannes' },
      { id: '5', isWaiting: true, addressCity: 'Brest' },
      { id: '6', isWaiting: true, addressCity: null },
    ]);
    expect(r).toEqual([
      { city: 'Brest', count: 2 },
      { city: 'Quimper', count: 2 },
    ]);
  });
});
