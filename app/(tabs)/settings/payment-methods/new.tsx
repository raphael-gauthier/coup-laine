import { Stack, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { PaymentMethodForm } from '@/ui/components/payment-method-form';
import { useUpsertPaymentMethod } from '@/state/queries/payment-methods';
import { haptics } from '@/ui/motion/haptics';

export default function NewPaymentMethodScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const upsert = useUpsertPaymentMethod();

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ presentation: 'modal' }} />
      <ScreenHeader title={t('catalogs.payment_methods.new_title')} />
      <PaymentMethodForm
        saving={upsert.isPending}
        onCancel={() => router.back()}
        onSubmit={(input) =>
          upsert.mutate(input, {
            onSuccess: () => {
              void haptics.success();
              router.back();
            },
          })
        }
      />
    </Surface>
  );
}
