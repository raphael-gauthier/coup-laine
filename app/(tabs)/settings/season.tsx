import { useState } from 'react';
import { ScrollView, View, Platform } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import DateTimePicker from '@react-native-community/datetimepicker';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { errorToast } from '@/ui/components/error-toast';
import { useAllSettings, useSetSetting } from '@/state/queries/settings';
import { haptics } from '@/ui/motion/haptics';

export default function SeasonScreen() {
  const { t } = useTranslation();
  const { data: settings } = useAllSettings();
  const setSettingMutation = useSetSetting();

  const savedDate = settings?.season_started_at
    ? parseISO(settings.season_started_at)
    : new Date();

  const [date, setDate] = useState<Date>(savedDate);
  const [showPicker, setShowPicker] = useState(false);

  const onSave = () => {
    const value = format(date, 'yyyy-MM-dd');
    setSettingMutation.mutate(
      { key: 'season_started_at', value },
      {
        onSuccess: () => { void haptics.success(); },
        onError: (err) => {
          errorToast(t('settings.season.save_failed'), err instanceof Error ? err.message : undefined);
        },
      }
    );
  };

  const onReset = () => {
    const today = new Date();
    setDate(today);
  };

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ title: t('settings.season.screen_title') }} />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 24, paddingBottom: 32, gap: 16 }}>

        <Surface variant="muted" className="rounded-2xl px-4 py-3">
          <Text variant="muted" className="text-sm">{t('settings.season.help_text')}</Text>
        </Surface>

        <View className="gap-2">
          <Text className="text-sm font-medium">{t('settings.season.date_label')}</Text>
          <PressScale onPress={() => setShowPicker(true)}>
            <Surface variant="muted" className="rounded-2xl px-4 py-3">
              <Text>{format(date, 'PPPP', { locale: fr })}</Text>
            </Surface>
          </PressScale>
          {showPicker ? (
            <DateTimePicker
              value={date}
              mode="date"
              onChange={(_, d) => {
                setShowPicker(Platform.OS === 'ios');
                if (d) setDate(d);
              }}
            />
          ) : null}
        </View>

        <Button variant="secondary" onPress={onReset}>
          {t('settings.season.reset_today')}
        </Button>

        <Button onPress={onSave} loading={setSettingMutation.isPending}>
          {t('common.save')}
        </Button>

      </ScrollView>
    </Surface>
  );
}
