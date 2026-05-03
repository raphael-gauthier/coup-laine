import { normalizePhone } from './phone-normalizer';

export function formatPhone(input: string): string {
  if (!input) return '';
  const n = normalizePhone(input);
  if (n.length === 10 && n.startsWith('0')) {
    return n.match(/.{2}/g)!.join(' ');
  }
  if (n.startsWith('+33') && n.length === 12) {
    const rest = n.slice(3);
    return `+33 ${rest[0]} ${rest.slice(1).match(/.{2}/g)!.join(' ')}`;
  }
  return input;
}
