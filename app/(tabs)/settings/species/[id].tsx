import { View, ScrollView } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Trash2, ChevronRight, PawPrint } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { EmptyState } from '@/ui/components/empty-state';
import { ErrorState } from '@/ui/components/error-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { confirm } from '@/ui/components/confirm-dialog';
import { SpeciesForm } from '@/ui/components/species-form';
import { useSpecies } from '@/state/queries/species';
import { useUpsertSpecies, useDeleteSpecies } from '@/state/queries/catalogs';
import { haptics } from '@/ui/motion/haptics';
import { useMutedForegroundColor, useOnContrastColor } from '@/ui/theme/colors';

export default function EditSpeciesScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const onContrast = useOnContrastColor();
  const mutedFg = useMutedForegroundColor();
  const { data: species = [], isError, refetch } = useSpecies();
  const upsert = useUpsertSpecies();
  const del = useDeleteSpecies();

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  const item = species.find((s) => s.id === id);
  if (!item) {
    return (
      <Surface className="flex-1">
        <ScreenHeader title={t('catalogs.species.edit_title')} />
        <EmptyState
          icon={<PawPrint size={48} color={mutedFg} />}
          title={t('catalogs.species.not_found_title')}
        />
      </Surface>
    );
  }

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
      <ScreenHeader
        title={t('catalogs.species.edit_title')}
        rightSlot={
          item.isCustom ? (
            <Button size="sm" variant="danger" onPress={onDelete} accessibilityLabel={t('common.delete')}>
              <Trash2 size={16} color={onContrast} />
            </Button>
          ) : undefined
        }
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
            accessibilityLabel={t('catalogs.species.manage_categories')}
          >
            <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
              <Text className="flex-1 font-medium">{t('catalogs.species.manage_categories')}</Text>
              <ChevronRight size={18} color={mutedFg} />
            </Surface>
          </PressScale>
        </View>
      </ScrollView>
    </Surface>
  );
}
