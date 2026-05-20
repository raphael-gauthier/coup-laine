import { describe, it, expect } from 'vitest';
import { parseDateInput, parseTimeInput } from '@/domain/use-cases/parse-date-input';

describe('parseDateInput', () => {
  it('parses a valid date', () => {
    const r = parseDateInput('05/05/2026');
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.date.getFullYear()).toBe(2026);
      expect(r.date.getMonth()).toBe(4); // May = index 4
      expect(r.date.getDate()).toBe(5);
    }
  });

  it('rejects an empty string as empty', () => {
    expect(parseDateInput('')).toEqual({ ok: false, reason: 'empty' });
    expect(parseDateInput('   ')).toEqual({ ok: false, reason: 'empty' });
  });

  it('rejects an incomplete date as invalid', () => {
    expect(parseDateInput('05/05')).toEqual({ ok: false, reason: 'invalid' });
    expect(parseDateInput('5/5/26')).toEqual({ ok: false, reason: 'invalid' });
  });

  it('rejects an out-of-range date as invalid', () => {
    expect(parseDateInput('32/13/2026')).toEqual({ ok: false, reason: 'invalid' });
  });

  it('rejects a non-existent calendar date as invalid', () => {
    expect(parseDateInput('31/02/2026')).toEqual({ ok: false, reason: 'invalid' });
  });

  it('accepts Feb 29 in a leap year but rejects it otherwise', () => {
    expect(parseDateInput('29/02/2024').ok).toBe(true);
    expect(parseDateInput('29/02/2025')).toEqual({ ok: false, reason: 'invalid' });
  });
});

describe('parseTimeInput', () => {
  it('parses a valid time', () => {
    expect(parseTimeInput('08:30')).toEqual({ ok: true, value: '08:30' });
    expect(parseTimeInput('23:59')).toEqual({ ok: true, value: '23:59' });
  });

  it('rejects empty as empty', () => {
    expect(parseTimeInput('')).toEqual({ ok: false, reason: 'empty' });
  });

  it('rejects out-of-range times as invalid', () => {
    expect(parseTimeInput('24:00')).toEqual({ ok: false, reason: 'invalid' });
    expect(parseTimeInput('25:70')).toEqual({ ok: false, reason: 'invalid' });
    expect(parseTimeInput('8:5')).toEqual({ ok: false, reason: 'invalid' });
  });
});
