import { describe, it, expect } from 'vitest';
import { matchesQuery, normalizeForSearch } from '@/lib/text-search';

describe('normalizeForSearch', () => {
  it('lowercases', () => expect(normalizeForSearch('FOO')).toBe('foo'));
  it('strips accents', () => expect(normalizeForSearch('élève')).toBe('eleve'));
  it('collapses whitespace', () => expect(normalizeForSearch('  a   b  ')).toBe('a b'));
});

describe('matchesQuery', () => {
  it('matches case-insensitively', () => expect(matchesQuery('Hello World', 'hello')).toBe(true));
  it('matches accent-insensitively', () => expect(matchesQuery('Brévent', 'brevent')).toBe(true));
  it('matches across word boundaries', () => expect(matchesQuery('Jean-Pierre', 'pierre')).toBe(true));
  it('returns false on no match', () => expect(matchesQuery('Hello', 'xyz')).toBe(false));
  it('returns true on empty query', () => expect(matchesQuery('Hello', '')).toBe(true));
});
