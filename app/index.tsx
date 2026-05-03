import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Sun, Moon, Vibrate } from 'lucide-react-native';
import { Button } from '@/ui/primitives/button';
import { Text } from '@/ui/primitives/text';
import { useThemeStore, type ThemeMode } from '@/state/stores/theme-store';
import { haptics } from '@/ui/motion/haptics';

const NEXT_MODE: Record<ThemeMode, ThemeMode> = {
  system: 'light',
  light: 'dark',
  dark: 'system',
};

export default function Index() {
  const { t } = useTranslation();
  const mode = useThemeStore((s) => s.mode);
  const setMode = useThemeStore((s) => s.setMode);

  return (
    <View className="flex-1 bg-background dark:bg-background-dark items-center justify-center px-6">
      <Text className="text-3xl font-bold text-foreground dark:text-foreground-dark">
        {t('hello.title')}
      </Text>
      <Text className="text-base text-muted-foreground dark:text-muted-dark-foreground mt-2 text-center">
        {t('hello.subtitle')}
      </Text>

      <View className="mt-12 gap-4 w-full max-w-xs">
        <Button onPress={() => setMode(NEXT_MODE[mode])}>
          {mode === 'dark' ? <Sun size={20} color="white" /> : <Moon size={20} color="white" />}
          <Text className="text-primary-foreground font-semibold">
            {t('hello.toggle_theme')} ({mode})
          </Text>
        </Button>

        <Button variant="secondary" onPress={() => void haptics.success()}>
          <Vibrate size={20} />
          <Text className="font-semibold text-foreground dark:text-foreground-dark">{t('hello.test_haptic')}</Text>
        </Button>
      </View>
    </View>
  );
}
