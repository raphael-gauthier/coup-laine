import { useState, useMemo } from 'react';
import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import { ScreenHeader } from '@/ui/components/screen-header';
import { errorToast } from '@/ui/components/error-toast';
import { useAllSettings, useSetSetting } from '@/state/queries/settings';
import { haptics } from '@/ui/motion/haptics';

export default function TourRateScreen() {
  const { t } = useTranslation();
  const { data: settings } = useAllSettings();
  const setSettingMutation = useSetSetting();

  const [ratePerKm, setRatePerKm] = useState(
    settings?.tour_rate_eur_per_km ?? '0.5'
  );
  const [minFee, setMinFee] = useState(
    settings?.tour_min_fee_eur ?? '5'
  );
  const [rateTouched, setRateTouched] = useState(false);
  const [minFeeTouched, setMinFeeTouched] = useState(false);

  const errors = useMemo(() => {
    const out: { ratePerKm?: string; minFee?: string } = {};
    const r = parseFloat(ratePerKm.replace(',', '.'));
    if (!ratePerKm.trim() || isNaN(r) || r <= 0) {
      out.ratePerKm = t('settings.tour_rate.error_rate');
    }
    const m = parseFloat(minFee.replace(',', '.'));
    if (!minFee.trim() || isNaN(m) || m <= 0) {
      out.minFee = t('settings.tour_rate.error_min_fee');
    }
    return out;
  }, [ratePerKm, minFee, t]);

  const canSubmit = !errors.ratePerKm && !errors.minFee && !setSettingMutation.isPending;

  const onSave = async () => {
    setRateTouched(true);
    setMinFeeTouched(true);
    if (!canSubmit) {
      void haptics.error();
      return;
    }
    const rateVal = String(parseFloat(ratePerKm.replace(',', '.')));
    const minVal = String(parseFloat(minFee.replace(',', '.')));

    try {
      await new Promise<void>((resolve, reject) => {
        setSettingMutation.mutate({ key: 'tour_rate_eur_per_km', value: rateVal }, {
          onSuccess: () => resolve(),
          onError: reject,
        });
      });
      await new Promise<void>((resolve, reject) => {
        setSettingMutation.mutate({ key: 'tour_min_fee_eur', value: minVal }, {
          onSuccess: () => resolve(),
          onError: reject,
        });
      });
      void haptics.success();
    } catch (err) {
      errorToast(t('settings.tour_rate.save_failed'), err instanceof Error ? err.message : undefined);
    }
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('settings.tour_rate.screen_title')} />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 32, gap: 16 }}>

        <View className="gap-2">
          <Text className="text-sm font-medium">{t('settings.tour_rate.rate_per_km_label')}</Text>
          <Input
            value={ratePerKm}
            onChangeText={setRatePerKm}
            onBlur={() => setRateTouched(true)}
            keyboardType="decimal-pad"
            placeholder="0,50"
          />
          {rateTouched && errors.ratePerKm ? (
            <Text className="text-sm text-danger dark:text-danger-dark">{errors.ratePerKm}</Text>
          ) : null}
        </View>

        <View className="gap-2">
          <Text className="text-sm font-medium">{t('settings.tour_rate.min_fee_label')}</Text>
          <Input
            value={minFee}
            onChangeText={setMinFee}
            onBlur={() => setMinFeeTouched(true)}
            keyboardType="decimal-pad"
            placeholder="5"
          />
          {minFeeTouched && errors.minFee ? (
            <Text className="text-sm text-danger dark:text-danger-dark">{errors.minFee}</Text>
          ) : null}
        </View>

        <Button onPress={onSave} disabled={!canSubmit} loading={setSettingMutation.isPending}>
          {t('common.save')}
        </Button>

      </ScrollView>
    </Surface>
  );
}
