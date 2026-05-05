import { useMemo } from 'react';
import { View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import { Plus, ChevronRight, Tags } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { Fab } from '@/ui/primitives/fab';
import { ListSkeleton } from '@/ui/primitives/skeleton';
import { PressScale } from '@/ui/motion/press-scale';
import { EmptyState } from '@/ui/components/empty-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { useAnimalCategories } from '@/state/queries/species';
import { haptics } from '@/ui/motion/haptics';
import { useOnContrastColor, useMutedForegroundColor } from '@/ui/theme/colors';

export default function CategoriesListScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const onContrast = useOnContrastColor();
  const mutedFg = useMutedForegroundColor();
  const { data: all = [], isLoading } = useAnimalCategories();
  const items = useMemo(() => all.filter((c) => c.speciesId === id), [all, id]);

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('catalogs.categories.list_title')} />
      {isLoading ? (
        <ListSkeleton />
      ) : items.length === 0 ? (
        <EmptyState
          icon={<Tags size={48} color={mutedFg} />}
          title={t('catalogs.categories.empty_title')}
          message={t('catalogs.categories.empty_message')}
          action={
            <Button
              onPress={() => {
                void haptics.selection();
                router.push(`/(tabs)/settings/species/${id}/categories/new` as never);
              }}
              accessibilityLabel={t('catalogs.categories.empty_cta')}
            >
              <Plus size={16} color={onContrast} />
              <Text variant="onPrimary" className="font-semibold">
                {t('catalogs.categories.empty_cta')}
              </Text>
            </Button>
          }
        />
      ) : (
        <FlashList
          data={items}
          keyExtractor={(c) => c.id}
          contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 96 }}
          ItemSeparatorComponent={() => <View className="h-2" />}
          renderItem={({ item }) => (
            <PressScale
              onPress={() => {
                void haptics.selection();
                router.push(`/(tabs)/settings/species/${id}/categories/${item.id}` as never);
              }}
              accessibilityLabel={item.label}
            >
              <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
                <View className="flex-1">
                  <Text className="font-semibold">{item.label}</Text>
                </View>
                <ChevronRight size={18} color={mutedFg} />
              </Surface>
            </PressScale>
          )}
        />
      )}

      <Fab
        icon={Plus}
        onPress={() => router.push(`/(tabs)/settings/species/${id}/categories/new` as never)}
        accessibilityLabel={t('catalogs.categories.new_title')}
      />
    </Surface>
  );
}
