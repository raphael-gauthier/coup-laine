import { useState } from 'react';
import { View, Alert } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import Animated, { FadeIn, FadeOut, LinearTransition } from 'react-native-reanimated';
import { Plus, Route as RouteIcon } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { motion } from '@/ui/motion/motion-tokens';
import { Surface } from '@/ui/primitives/surface';
import { Button } from '@/ui/primitives/button';
import { Text } from '@/ui/primitives/text';
import { ListSkeleton } from '@/ui/primitives/skeleton';
import { SegmentedControl } from '@/ui/components/segmented-control';
import { TourCard } from '@/ui/components/tour-card';
import { EmptyState } from '@/ui/components/empty-state';
import { ErrorState } from '@/ui/components/error-state';
import { useTours } from '@/state/queries/tours';
import type { TourStatus } from '@/domain/models/tour';

type Filter = 'planned' | 'completed';

export default function ToursListScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const [filter, setFilter] = useState<Filter>('planned');

  const { data: tours = [], isError, isLoading, refetch } = useTours(filter as TourStatus);

  return (
    <Surface className="flex-1">
      <Stack.Screen
        options={{
          title: t('tours.list_title'),
          headerRight: () => (
            <Button size="sm" onPress={() => {
              Alert.alert(t('tours.empty_cta'), undefined, [
                { text: t('tours.create_manual'), onPress: () => router.push('/(tabs)/tours/new/draft' as never) },
                { text: t('tours.create_optimized'), onPress: () => router.push('/(tabs)/tours/new/optimized' as never) },
                { text: t('common.cancel'), style: 'cancel' },
              ]);
            }}>
              <Plus size={16} color="white" />
              <Text variant="onPrimary" className="font-semibold">{t('tours.empty_cta')}</Text>
            </Button>
          ),
        }}
      />

      <View className="px-4 pt-3">
        <SegmentedControl<Filter>
          value={filter}
          onChange={setFilter}
          options={[
            { value: 'planned', label: t('tours.filter_planned') },
            { value: 'completed', label: t('tours.filter_completed') },
          ]}
        />
      </View>

      {isError ? (
        <ErrorState onRetry={() => refetch()} />
      ) : isLoading ? (
        <ListSkeleton />
      ) : tours.length === 0 ? (
        <EmptyState
          icon={<RouteIcon size={48} color="#5C4E40" />}
          title={t('tours.empty_filtered_title')}
          message={t('tours.empty_filtered_message')}
        />
      ) : (
        <FlashList
          data={tours}
          keyExtractor={(t) => t.tour.id}
          contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 24 }}
          ItemSeparatorComponent={() => <View className="h-2" />}
          renderItem={({ item }) => (
            <Animated.View
              entering={FadeIn.duration(motion.duration.fast)}
              exiting={FadeOut.duration(motion.duration.fast)}
              layout={LinearTransition.duration(motion.duration.normal)}
            >
              <TourCard
                tour={item.tour}
                stopCount={item.stops.length}
                onPress={() => router.push(`/(tabs)/tours/${item.tour.id}` as never)}
              />
            </Animated.View>
          )}
        />
      )}
    </Surface>
  );
}
