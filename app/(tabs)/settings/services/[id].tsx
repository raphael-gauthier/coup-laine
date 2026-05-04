import { useLocalSearchParams, useRouter } from 'expo-router';
import { Trash2 } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Button } from '@/ui/primitives/button';
import { ScreenHeader } from '@/ui/components/screen-header';
import { confirm } from '@/ui/components/confirm-dialog';
import { ServiceForm } from '@/ui/components/service-form';
import { useServices } from '@/state/queries/species';
import { useUpsertService, useDeleteService } from '@/state/queries/catalogs';
import { haptics } from '@/ui/motion/haptics';

export default function EditServiceScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const { data: services = [] } = useServices();
  const upsert = useUpsertService();
  const del = useDeleteService();

  const item = services.find((p) => p.id === id);
  if (!item) return <Surface className="flex-1" />;

  const onDelete = async () => {
    const ok = await confirm({
      title: t('catalogs.services.delete_confirm_title'),
      message: t('catalogs.services.delete_confirm_message'),
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
        title={t('catalogs.services.edit_title')}
        rightSlot={
          <Button size="sm" variant="danger" onPress={onDelete} accessibilityLabel={t('common.delete')}>
            <Trash2 size={16} color="white" />
          </Button>
        }
      />
      <ServiceForm
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
