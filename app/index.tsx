import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Sun, Moon, Vibrate, ArrowRight } from 'lucide-react-native';
import { Button } from '@/ui/primitives/button';
import { Surface } from '@/ui/primitives/surface';
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
  const router = useRouter();
  const mode = useThemeStore((s) => s.mode);
  const setMode = useThemeStore((s) => s.setMode);

  return (
    <Surface className="flex-1 items-center justify-center px-6">
      <Text className="text-3xl font-bold">{t('hello.title')}</Text>
      <Text variant="muted" className="text-base mt-2 text-center">
        {t('hello.subtitle')}
      </Text>

      <View className="mt-12 gap-4 w-full max-w-xs">
        <Button onPress={() => setMode(NEXT_MODE[mode])}>
          {mode === 'dark' ? <Sun size={20} color="white" /> : <Moon size={20} color="white" />}
          <Text variant="onPrimary" className="font-semibold">
            {t('hello.toggle_theme')} ({mode})
          </Text>
        </Button>

        <Button variant="secondary" onPress={() => void haptics.success()}>
          <Vibrate size={20} />
          <Text className="font-semibold">{t('hello.test_haptic')}</Text>
        </Button>

        <Button variant="ghost" onPress={() => router.push('/(tabs)/clients')}>
          <Text className="font-semibold">Voir les tabs</Text>
          <ArrowRight size={18} />
        </Button>
      </View>
    </Surface>
  );
}
