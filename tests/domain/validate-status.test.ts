import { describe, it, expect } from 'vitest';
import {
  validateStatusLabel,
  validateColorHex,
  validateColorPair,
} from '@/domain/use-cases/validate-status';

describe('validateStatusLabel', () => {
  it('rejects empty', () => {
    const r = validateStatusLabel('');
    expect(r.ok).toBe(false);
  });
  it('rejects whitespace-only', () => {
    expect(validateStatusLabel('   ').ok).toBe(false);
  });
  it('rejects > 30 chars', () => {
    expect(validateStatusLabel('x'.repeat(31)).ok).toBe(false);
  });
  it('accepts and trims', () => {
    const r = validateStatusLabel('  Hello  ');
    expect(r).toEqual({ ok: true, value: 'Hello' });
  });
});

describe('validateColorHex', () => {
  it('accepts #RRGGBB lowercase', () => {
    expect(validateColorHex('#a1602f')).toBe(true);
  });
  it('accepts #RRGGBB uppercase', () => {
    expect(validateColorHex('#A1602F')).toBe(true);
  });
  it('rejects #RGB', () => {
    expect(validateColorHex('#abc')).toBe(false);
  });
  it('rejects without hash', () => {
    expect(validateColorHex('A1602F')).toBe(false);
  });
  it('rejects transparent', () => {
    expect(validateColorHex('transparent')).toBe(false);
  });
});

describe('validateColorPair', () => {
  it('passes when both valid', () => {
    expect(validateColorPair({ light: '#A1602F', dark: '#C68A58' })).toBe(true);
  });
  it('fails when light invalid', () => {
    expect(validateColorPair({ light: 'nope', dark: '#C68A58' })).toBe(false);
  });
  it('fails when dark invalid', () => {
    expect(validateColorPair({ light: '#A1602F', dark: 'nope' })).toBe(false);
  });
});
