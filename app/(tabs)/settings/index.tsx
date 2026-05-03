import { ScrollView } from 'react-native';
import { useRouter, Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { SettingsRow } from '@/ui/components/settings-row';

export default function SettingsScreen() {
  const router = useRouter();
  const { t } = useTranslation();

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ title: t('settings.title') }} />
      <ScrollView contentContainerClassName="px-4 pt-4 gap-3">
        <SettingsRow
          label={t('catalogs.species.row_label')}
          hint={t('catalogs.species.row_hint')}
          onPress={() => router.push('/(tabs)/settings/species' as never)}
        />
        <SettingsRow
          label={t('catalogs.prestations.row_label')}
          hint={t('catalogs.prestations.row_hint')}
          onPress={() => router.push('/(tabs)/settings/prestations' as never)}
        />
        <SettingsRow
          label={t('settings.appearance.row_label')}
          hint={t('settings.appearance.row_hint')}
          onPress={() => router.push('/(tabs)/settings/appearance')}
        />
        <SettingsRow
          label={t('settings.base.row_label')}
          hint={t('settings.base.row_hint')}
          onPress={() => router.push('/(tabs)/settings/base')}
        />
      </ScrollView>
    </Surface>
  );
}
