import { useColorScheme } from 'react-native';

/**
 * Foreground color to use on top of any *contrast* surface
 * (primary / accent / danger / success). All four token pairs share
 * the same on-foreground: #FAF6F0 in light, #16120F in dark.
 */
export function useOnContrastColor(): string {
  return useColorScheme() === 'dark' ? '#16120F' : '#FAF6F0';
}
