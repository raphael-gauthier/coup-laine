import { useState } from 'react';
import { ScrollView } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Button } from '@/ui/primitives/button';
import { Slider } from '@/ui/primitives/slider';
import { ScreenHeader } from '@/ui/components/screen-header';
import { errorToast } from '@/ui/components/error-toast';
import { useAllSettings, useSetSetting } from '@/state/queries/settings';
import { haptics } from '@/ui/motion/haptics';

export default function ProximityScreen() {
  const { t } = useTranslation();
  const { data: settings } = useAllSettings();
  const setSettingMutation = useSetSetting();

  const savedValue = settings?.proximity_radius_km != null
    ? parseInt(settings.proximity_radius_km, 10)
    : 10;

  const [radius, setRadius] = useState(savedValue);

  const onSave = () => {
    setSettingMutation.mutate(
      { key: 'proximity_radius_km', value: String(radius) },
      {
        onSuccess: () => { void haptics.success(); },
        onError: (err) => {
          errorToast(t('settings.proximity.save_failed'), err instanceof Error ? err.message : undefined);
        },
      }
    );
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('settings.proximity.screen_title')} />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 32, gap: 24 }}>
        <Slider
          value={radius}
          onChange={setRadius}
          min={1}
          max={50}
          step={1}
          label={t('settings.proximity.slider_label', { value: radius })}
          formatValue={(v) => `${v} km`}
        />
        <Button onPress={onSave} loading={setSettingMutation.isPending}>
          {t('common.save')}
        </Button>
      </ScrollView>
    </Surface>
  );
}
