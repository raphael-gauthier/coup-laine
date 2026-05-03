import { useMemo } from 'react';
import { View } from 'react-native';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import { Plus, ChevronRight } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { useAnimalCategories } from '@/state/queries/species';
import { haptics } from '@/ui/motion/haptics';

export default function CategoriesListScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const { data: all = [] } = useAnimalCategories();
  const items = useMemo(() => all.filter((c) => c.speciesId === id), [all, id]);

  return (
    <Surface className="flex-1">
      <Stack.Screen
        options={{
          title: t('catalogs.categories.list_title'),
          headerRight: () => (
            <Button
              size="sm"
              onPress={() => router.push(`/(tabs)/settings/species/${id}/categories/new` as never)}
            >
              <Plus size={16} color="white" />
              <Text variant="onPrimary" className="font-semibold">{t('catalogs.categories.new_title')}</Text>
            </Button>
          ),
        }}
      />
      <FlashList
        data={items}
        keyExtractor={(c) => c.id}
        contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 24 }}
        ItemSeparatorComponent={() => <View className="h-2" />}
        renderItem={({ item }) => (
          <PressScale
            onPress={() => {
              void haptics.selection();
              router.push(`/(tabs)/settings/species/${id}/categories/${item.id}` as never);
            }}
          >
            <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
              <View className="flex-1">
                <Text className="font-semibold">{item.label}</Text>
              </View>
              <ChevronRight size={18} color="#5C4E40" />
            </Surface>
          </PressScale>
        )}
      />
    </Surface>
  );
}
