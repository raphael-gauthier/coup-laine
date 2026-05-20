import { useState } from 'react';
import { ScrollView } from 'react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { DateField } from '@/ui/components/date-field';
import { ScreenHeader } from '@/ui/components/screen-header';
import { mutationErrorToast } from '@/ui/components/error-toast';
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
  const [dateValid, setDateValid] = useState(true);

  const onSave = () => {
    const value = format(date, 'yyyy-MM-dd');
    setSettingMutation.mutate(
      { key: 'season_started_at', value },
      {
        onSuccess: () => { void haptics.success(); },
        onError: (err) => {
          mutationErrorToast(t('settings.season.save_failed'), err);
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
      <ScreenHeader title={t('settings.season.screen_title')} />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 32, gap: 16 }}>

        <Surface variant="muted" className="rounded-2xl px-4 py-3">
          <Text variant="muted" className="text-sm">{t('settings.season.help_text')}</Text>
        </Surface>

        <DateField
          label={t('settings.season.date_label')}
          value={date}
          onChange={(d) => { if (d) setDate(d); }}
          onValidityChange={setDateValid}
        />

        <Button variant="secondary" onPress={onReset}>
          {t('settings.season.reset_today')}
        </Button>

        <Button onPress={onSave} loading={setSettingMutation.isPending} disabled={!dateValid}>
          {t('common.save')}
        </Button>

      </ScrollView>
    </Surface>
  );
}
