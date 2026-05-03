import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { Trash2 } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Button } from '@/ui/primitives/button';
import { confirm } from '@/ui/components/confirm-dialog';
import { PrestationForm } from '@/ui/components/prestation-form';
import { usePrestations } from '@/state/queries/species';
import { useUpsertPrestation, useDeletePrestation } from '@/state/queries/catalogs';
import { haptics } from '@/ui/motion/haptics';

export default function EditPrestationScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const { data: prestations = [] } = usePrestations();
  const upsert = useUpsertPrestation();
  const del = useDeletePrestation();

  const item = prestations.find((p) => p.id === id);
  if (!item) return <Surface className="flex-1" />;

  const onDelete = async () => {
    const ok = await confirm({
      title: t('catalogs.prestations.delete_confirm_title'),
      message: t('catalogs.prestations.delete_confirm_message'),
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
      <Stack.Screen
        options={{
          title: t('catalogs.prestations.edit_title'),
          headerRight: () => (
            <Button size="sm" variant="danger" onPress={onDelete}>
              <Trash2 size={16} color="white" />
            </Button>
          ),
        }}
      />
      <PrestationForm
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
