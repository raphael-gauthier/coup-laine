import { View, ScrollView } from 'react-native';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { Trash2, ChevronRight } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { ErrorState } from '@/ui/components/error-state';
import { confirm } from '@/ui/components/confirm-dialog';
import { SpeciesForm } from '@/ui/components/species-form';
import { useSpecies } from '@/state/queries/species';
import { useUpsertSpecies, useDeleteSpecies } from '@/state/queries/catalogs';
import { haptics } from '@/ui/motion/haptics';

export default function EditSpeciesScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const { data: species = [], isError, refetch } = useSpecies();
  const upsert = useUpsertSpecies();
  const del = useDeleteSpecies();

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  const item = species.find((s) => s.id === id);
  if (!item) return <Surface className="flex-1" />;

  const onDelete = async () => {
    const ok = await confirm({
      title: t('catalogs.species.delete_confirm_title'),
      message: t('catalogs.species.delete_confirm_message'),
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
          title: t('catalogs.species.edit_title'),
          headerRight: () =>
            item.isCustom ? (
              <Button size="sm" variant="danger" onPress={onDelete} accessibilityLabel={t('common.delete')}>
                <Trash2 size={16} color="white" />
              </Button>
            ) : null,
        }}
      />
      <ScrollView contentContainerStyle={{ flexGrow: 1 }}>
        <SpeciesForm
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
        <View className="px-4 pb-8">
          <PressScale
            onPress={() => router.push(`/(tabs)/settings/species/${item.id}/categories` as never)}
          >
            <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
              <Text className="flex-1 font-medium">{t('catalogs.species.manage_categories')}</Text>
              <ChevronRight size={18} color="#5C4E40" />
            </Surface>
          </PressScale>
        </View>
      </ScrollView>
    </Surface>
  );
}
