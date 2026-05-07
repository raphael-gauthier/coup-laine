import { describe, it, expect } from 'vitest';
import { compareSemver } from '@/domain/use-cases/compare-semver';

describe('compareSemver', () => {
  const cases: Array<[string, string, -1 | 0 | 1]> = [
    ['0.10.0', '0.10.0', 0],
    ['0.10.0', '0.10.1', -1],
    ['0.10.1', '0.10.0', 1],
    ['0.9.99', '0.10.0', -1],
    ['1.0.0', '0.99.99', 1],
    ['0.10', '0.10.0', 0], // missing patch defaults to 0
    ['0.10.0-beta.1', '0.10.0', 0], // prerelease treated as stable
    ['0.10.0', '0.10.0-beta.1', 0],
    ['', '0.10.0', 0], // malformed → fail-open: equality
    ['lol', '0.10.0', 0], // malformed → equality
  ];

  it.each(cases)('compareSemver(%s, %s) === %s', (a, b, expected) => {
    expect(compareSemver(a, b)).toBe(expected);
  });
});
