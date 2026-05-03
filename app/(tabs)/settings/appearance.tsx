import { ScrollView } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { RadioRow } from '@/ui/components/radio-row';
import { useThemeMode, useSetThemeMode } from '@/state/queries/settings';
import type { ThemeMode } from '@/state/stores/theme-store';

const ORDER: ThemeMode[] = ['system', 'light', 'dark'];

export default function AppearanceScreen() {
  const { t } = useTranslation();
  const mode = useThemeMode();
  const setMode = useSetThemeMode();

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ title: t('settings.appearance.screen_title') }} />
      <ScrollView contentContainerClassName="px-4 pt-4 gap-3">
        {ORDER.map((option) => (
          <RadioRow
            key={option}
            label={t(`settings.appearance.options.${option}`)}
            selected={mode === option}
            onPress={() => setMode.mutate(option)}
          />
        ))}
      </ScrollView>
    </Surface>
  );
}
