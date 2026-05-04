import { useColorScheme } from 'react-native';

/**
 * Foreground color to use on top of any *contrast* surface
 * (primary / accent / danger / success). All four token pairs share
 * the same on-foreground: #FAF6F0 in light, #16120F in dark.
 */
export function useOnContrastColor(): string {
  return useColorScheme() === 'dark' ? '#16120F' : '#FAF6F0';
}

/**
 * Default foreground color (matches `text-foreground dark:text-foreground-dark`).
 * Use for icons inside ghost / muted-bg buttons where the text adapts but a
 * Lucide icon would otherwise default to black and disappear in dark mode.
 */
export function useForegroundColor(): string {
  return useColorScheme() === 'dark' ? '#F0E8DC' : '#1C1612';
}
