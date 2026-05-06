import { ScrollView } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import type { TFunction } from 'i18next';

import { Surface } from '@/ui/primitives/surface';
import { Button } from '@/ui/primitives/button';
import { Text } from '@/ui/primitives/text';
import { ScreenHeader } from '@/ui/components/screen-header';
import { RHFTextField } from '@/ui/components/rhf-text-field';
import { mutationErrorToast } from '@/ui/components/error-toast';
import { useAllSettings, useSetSetting } from '@/state/queries/settings';
import { haptics } from '@/ui/motion/haptics';

interface FormValues {
  bracketKm: string;
  feePerBracket: string;
}

function makeSchema(t: TFunction) {
  const positiveNumber = (msg: string) =>
    z.string().refine((v) => {
      const n = parseFloat(v.replace(',', '.'));
      return !Number.isNaN(n) && n > 0;
    }, msg);
  return z.object({
    bracketKm: positiveNumber(t('settings.tour_rate.error_bracket')),
    feePerBracket: positiveNumber(t('settings.tour_rate.error_fee')),
  });
}

export default function TourRateScreen() {
  const { t } = useTranslation();
  const { data: settings } = useAllSettings();
  const setSettingMutation = useSetSetting();

  const { control, handleSubmit } = useForm<FormValues>({
    defaultValues: {
      bracketKm: settings?.tour_bracket_km ?? '10',
      feePerBracket: settings?.tour_fee_eur_per_bracket ?? '8',
    },
    resolver: zodResolver(makeSchema(t)),
    mode: 'onTouched',
  });

  const onValid = async (values: FormValues) => {
    const bracketVal = String(parseFloat(values.bracketKm.replace(',', '.')));
    const feeVal = String(parseFloat(values.feePerBracket.replace(',', '.')));

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
      mutationErrorToast(t('settings.tour_rate.save_failed'), err);
    }
  };

  const onInvalid = () => {
    void haptics.error();
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('settings.tour_rate.screen_title')} />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 32, gap: 16 }}>

        <Text variant="muted" className="text-sm">
          {t('settings.tour_rate.explanation')}
        </Text>

        <RHFTextField
          control={control}
          name="bracketKm"
          label={t('settings.tour_rate.bracket_km_label')}
          keyboardType="decimal-pad"
          placeholder="10"
          hint={t('settings.tour_rate.bracket_km_hint')}
        />

        <RHFTextField
          control={control}
          name="feePerBracket"
          label={t('settings.tour_rate.fee_per_bracket_label')}
          keyboardType="decimal-pad"
          placeholder="8"
          hint={t('settings.tour_rate.fee_per_bracket_hint')}
        />

        <Button onPress={handleSubmit(onValid, onInvalid)} loading={setSettingMutation.isPending}>
          {t('common.save')}
        </Button>

      </ScrollView>
    </Surface>
  );
}
