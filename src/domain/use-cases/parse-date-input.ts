import { parse, isValid, format } from 'date-fns';

const DATE_RE = /^\d{2}\/\d{2}\/\d{4}$/;
const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d$/;

export type DateParseResult =
  | { ok: true; date: Date }
  | { ok: false; reason: 'empty' | 'invalid' };

export type TimeParseResult =
  | { ok: true; value: string }
  | { ok: false; reason: 'empty' | 'invalid' };

/** Parse a `DD/MM/YYYY` string into a Date, rejecting incomplete or
 *  non-existent calendar dates (e.g. 31/02). */
export function parseDateInput(text: string): DateParseResult {
  const trimmed = text.trim();
  if (trimmed === '') return { ok: false, reason: 'empty' };
  if (!DATE_RE.test(trimmed)) return { ok: false, reason: 'invalid' };
  const parsed = parse(trimmed, 'dd/MM/yyyy', new Date());
  // Round-trip guards against date-fns rolling over impossible dates.
  if (!isValid(parsed) || format(parsed, 'dd/MM/yyyy') !== trimmed) {
    return { ok: false, reason: 'invalid' };
  }
  return { ok: true, date: parsed };
}

/** Parse a `HH:MM` (24h) string, validating hour/minute ranges. */
export function parseTimeInput(text: string): TimeParseResult {
  const trimmed = text.trim();
  if (trimmed === '') return { ok: false, reason: 'empty' };
  if (!TIME_RE.test(trimmed)) return { ok: false, reason: 'invalid' };
  return { ok: true, value: trimmed };
}
