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

  const [bracketKm, setBracketKm] = useState(settings?.tour_bracket_km ?? '10');
  const [feePerBracket, setFeePerBracket] = useState(
    settings?.tour_fee_eur_per_bracket ?? '8'
  );
  const [bracketTouched, setBracketTouched] = useState(false);
  const [feeTouched, setFeeTouched] = useState(false);

  const errors = useMemo(() => {
    const out: { bracket?: string; fee?: string } = {};
    const b = parseFloat(bracketKm.replace(',', '.'));
    if (!bracketKm.trim() || isNaN(b) || b <= 0) {
      out.bracket = t('settings.tour_rate.error_bracket');
    }
    const f = parseFloat(feePerBracket.replace(',', '.'));
    if (!feePerBracket.trim() || isNaN(f) || f <= 0) {
      out.fee = t('settings.tour_rate.error_fee');
    }
    return out;
  }, [bracketKm, feePerBracket, t]);

  const canSubmit = !errors.bracket && !errors.fee && !setSettingMutation.isPending;

  const onSave = async () => {
    setBracketTouched(true);
    setFeeTouched(true);
    if (!canSubmit) {
      void haptics.error();
      return;
    }
    const bracketVal = String(parseFloat(bracketKm.replace(',', '.')));
    const feeVal = String(parseFloat(feePerBracket.replace(',', '.')));

    try {
      await new Promise<void>((resolve, reject) => {
        setSettingMutation.mutate({ key: 'tour_bracket_km', value: bracketVal }, {
          onSuccess: () => resolve(),
          onError: reject,
        });
      });
      await new Promise<void>((resolve, reject) => {
        setSettingMutation.mutate({ key: 'tour_fee_eur_per_bracket', value: feeVal }, {
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
          <Text className="text-sm font-medium">{t('settings.tour_rate.bracket_km_label')}</Text>
          <Input
            value={bracketKm}
            onChangeText={setBracketKm}
            onBlur={() => setBracketTouched(true)}
            keyboardType="decimal-pad"
            placeholder="10"
          />
          <Text variant="muted" className="text-xs">{t('settings.tour_rate.bracket_km_hint')}</Text>
          {bracketTouched && errors.bracket ? (
            <Text className="text-sm text-danger dark:text-danger-dark">{errors.bracket}</Text>
          ) : null}
        </View>

        <View className="gap-2">
          <Text className="text-sm font-medium">{t('settings.tour_rate.fee_per_bracket_label')}</Text>
          <Input
            value={feePerBracket}
            onChangeText={setFeePerBracket}
            onBlur={() => setFeeTouched(true)}
            keyboardType="decimal-pad"
            placeholder="8"
          />
          <Text variant="muted" className="text-xs">{t('settings.tour_rate.fee_per_bracket_hint')}</Text>
          {feeTouched && errors.fee ? (
            <Text className="text-sm text-danger dark:text-danger-dark">{errors.fee}</Text>
          ) : null}
        </View>

        <Button onPress={onSave} disabled={!canSubmit} loading={setSettingMutation.isPending}>
          {t('common.save')}
        </Button>

      </ScrollView>
    </Surface>
  );
}
