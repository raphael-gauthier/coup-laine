import { useLocalSearchParams, useRouter } from 'expo-router';
import { Trash2 } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Button } from '@/ui/primitives/button';
import { ScreenHeader } from '@/ui/components/screen-header';
import { confirm } from '@/ui/components/confirm-dialog';
import { PaymentMethodForm } from '@/ui/components/payment-method-form';
import { usePaymentMethods, useUpsertPaymentMethod, useDeletePaymentMethod } from '@/state/queries/payment-methods';
import { haptics } from '@/ui/motion/haptics';
import { useOnContrastColor } from '@/ui/theme/colors';

export default function EditPaymentMethodScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const onContrast = useOnContrastColor();
  const { data: methods = [] } = usePaymentMethods('all');
  const upsert = useUpsertPaymentMethod();
  const del = useDeletePaymentMethod();

  const item = methods.find((m) => m.id === id);
  if (!item) return <Surface className="flex-1" />;

  const onDelete = async () => {
    const ok = await confirm({
      title: t('catalogs.payment_methods.delete_confirm_title'),
      message: t('catalogs.payment_methods.delete_confirm_message'),
      confirmLabel: t('common.delete'),
      cancelLabel: t('common.cancel'),
      destructive: true,
    });
    if (!ok) return;
    del.mutate(item.id, {
      onSuccess: () => {
        void haptics.success();
        router.back();
      },
    });
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader
        title={t('catalogs.payment_methods.edit_title')}
        rightSlot={
          <Button size="sm" variant="danger" onPress={onDelete} accessibilityLabel={t('common.delete')}>
            <Trash2 size={16} color={onContrast} />
          </Button>
        }
      />
      <PaymentMethodForm
        initial={item}
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
