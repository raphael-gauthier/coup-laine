const HEX_RE = /^#[0-9A-Fa-f]{6}$/;

export type ValidationResult<T> =
  | { ok: true; value: T }
  | { ok: false; error: 'empty' | 'too_long' };

export function validateStatusLabel(raw: string): ValidationResult<string> {
  const trimmed = raw.trim();
  if (trimmed.length === 0) return { ok: false, error: 'empty' };
  if (trimmed.length > 30) return { ok: false, error: 'too_long' };
  return { ok: true, value: trimmed };
}

export function validateColorHex(raw: string): boolean {
  return HEX_RE.test(raw);
}

export function validateColorPair(pair: { light: string; dark: string }): boolean {
  return validateColorHex(pair.light) && validateColorHex(pair.dark);
}
