import { env } from '@/infra/config/env';

const KEY = env.maptilerApiKey;

export const mapStyles = {
  light: `https://api.maptiler.com/maps/streets-v2/style.json?key=${KEY}`,
  dark: `https://api.maptiler.com/maps/streets-v2-dark/style.json?key=${KEY}`,
} as const;

export function styleForScheme(scheme: 'light' | 'dark'): string {
  return mapStyles[scheme];
}
