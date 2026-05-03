import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { Trash2 } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Button } from '@/ui/primitives/button';
import { confirm } from '@/ui/components/confirm-dialog';
import { AnimalCategoryForm } from '@/ui/components/animal-category-form';
import { useAnimalCategories } from '@/state/queries/species';
import { useUpsertAnimalCategory, useDeleteAnimalCategory } from '@/state/queries/catalogs';
import { haptics } from '@/ui/motion/haptics';

export default function EditCategoryScreen() {
  const { id, categoryId } = useLocalSearchParams<{ id: string; categoryId: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const { data: all = [] } = useAnimalCategories();
  const upsert = useUpsertAnimalCategory();
  const del = useDeleteAnimalCategory();

  const item = all.find((c) => c.id === categoryId);
  if (!item) return <Surface className="flex-1" />;

  const onDelete = async () => {
    const ok = await confirm({
      title: t('catalogs.categories.delete_confirm_title'),
      message: t('catalogs.categories.delete_confirm_message'),
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
          title: t('catalogs.categories.edit_title'),
          headerRight: () => (
            <Button size="sm" variant="danger" onPress={onDelete}>
              <Trash2 size={16} color="white" />
            </Button>
          ),
        }}
      />
      <AnimalCategoryForm
        initial={item}
        speciesId={id}
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
