import { useColorScheme } from 'nativewind';
import { useEffect, type ReactNode } from 'react';
import { View } from 'react-native';
import { useThemeStore } from '@/state/stores/theme-store';

interface Props {
  children: ReactNode;
}

export function ThemeProvider({ children }: Props) {
  const mode = useThemeStore((s) => s.mode);
  const { colorScheme, setColorScheme } = useColorScheme();

  useEffect(() => {
    if (mode === 'system') {
      setColorScheme('system');
    } else {
      setColorScheme(mode);
    }
  }, [mode, setColorScheme]);

  const isDark = colorScheme === 'dark';

  return (
    <View className={isDark ? 'dark flex-1' : 'flex-1'}>
      <View className="flex-1 bg-background">{children}</View>
    </View>
  );
}
