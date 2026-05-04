import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { AnimalCategoryForm } from '@/ui/components/animal-category-form';
import { useUpsertAnimalCategory } from '@/state/queries/catalogs';
import { haptics } from '@/ui/motion/haptics';

export default function NewCategoryScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { t } = useTranslation();
  const router = useRouter();
  const upsert = useUpsertAnimalCategory();

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ presentation: 'modal' }} />
      <ScreenHeader title={t('catalogs.categories.new_title')} />
      <AnimalCategoryForm
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
