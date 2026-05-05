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

/**
 * Muted foreground — for secondary icons and de-emphasised glyphs
 * (matches `text-muted-foreground dark:text-muted-foreground-dark`).
 */
export function useMutedForegroundColor(): string {
  return useColorScheme() === 'dark' ? '#B4A490' : '#5C4E40';
}

/** Primary brand color (matches `bg-primary` / `text-primary`). */
export function usePrimaryColor(): string {
  return useColorScheme() === 'dark' ? '#C68A58' : '#A1602F';
}

/** Danger color (matches `text-danger dark:text-danger-dark`). */
export function useDangerColor(): string {
  return useColorScheme() === 'dark' ? '#DC605A' : '#B23832';
}

/** Waiting / pending status color. */
export function useWaitingColor(): string {
  return useColorScheme() === 'dark' ? '#DC9E4E' : '#C88226';
}
