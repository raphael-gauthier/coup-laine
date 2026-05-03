import { colorScheme as nativewindColorScheme, useColorScheme } from 'nativewind';
import { useEffect, type ReactNode } from 'react';
import { useThemeStore } from '@/state/stores/theme-store';

interface Props {
  children: ReactNode;
}

/**
 * Bridges the persisted theme store ('system' | 'light' | 'dark') with
 * NativeWind's global colorScheme. Renders children as-is — NativeWind
 * applies the theme to all `dark:` classes globally, no wrapper needed.
 */
export function ThemeProvider({ children }: Props) {
  const mode = useThemeStore((s) => s.mode);

  useEffect(() => {
    nativewindColorScheme.set(mode);
  }, [mode]);

  return <>{children}</>;
}

/**
 * Hook for components that need to know whether the resolved theme is dark.
 * Useful for the navigation ThemeProvider (light vs dark navigation tokens).
 */
export function useResolvedColorScheme(): 'light' | 'dark' {
  const { colorScheme } = useColorScheme();
  return colorScheme === 'dark' ? 'dark' : 'light';
}
