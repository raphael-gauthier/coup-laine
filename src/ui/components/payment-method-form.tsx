import { useTranslation } from 'react-i18next';
import { ScrollView, View } from 'react-native';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import type { TFunction } from 'i18next';

import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ThemedSwitch } from '@/ui/primitives/themed-switch';
import { RHFTextField } from '@/ui/components/rhf-text-field';
import { haptics } from '@/ui/motion/haptics';
import type { PaymentMethod } from '@/domain/models/payment-method';
import type { UpsertPaymentMethodInput } from '@/state/queries/payment-methods';

interface Props {
  initial?: PaymentMethod;
  saving?: boolean;
  onSubmit: (input: UpsertPaymentMethodInput) => void;
  onCancel?: () => void;
}

interface FormValues { label: string; isActive: boolean; }

function makeSchema(t: TFunction) {
  return z.object({
    label: z.string().trim().min(1, t('catalogs.errors.label_required')),
    isActive: z.boolean(),
  });
}

export function PaymentMethodForm({ initial, saving, onSubmit, onCancel }: Props) {
  const { t } = useTranslation();
  const { control, handleSubmit } = useForm<FormValues>({
    defaultValues: {
      label: initial?.label ?? '',
      isActive: initial?.isActive ?? true,
    },
    resolver: zodResolver(makeSchema(t)),
    mode: 'onTouched',
  });

  const onValid = (values: FormValues) => {
    onSubmit({
      id: initial?.id,
      label: values.label.trim(),
      isActive: values.isActive,
      ordering: initial?.ordering ?? 100,
    });
  };

  return (
    <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 32, gap: 16 }}>
      <RHFTextField control={control} name="label" label={t('catalogs.payment_methods.label')} />
      <Controller
        control={control}
        name="isActive"
        render={({ field }) => (
          <View className="flex-row items-center justify-between">
            <Text className="text-sm font-medium">{t('catalogs.payment_methods.active')}</Text>
            <ThemedSwitch value={field.value} onValueChange={field.onChange} />
          </View>
        )}
      />
      <View className="flex-row gap-2 mt-4">
        {onCancel ? (
          <Button variant="secondary" className="flex-1" onPress={onCancel} disabled={saving}>
            {t('common.cancel')}
          </Button>
        ) : null}
        <Button className="flex-1" onPress={handleSubmit(onValid, () => void haptics.error())} loading={saving}>
          {t('common.save')}
        </Button>
      </View>
    </ScrollView>
  );
}
