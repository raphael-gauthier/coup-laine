import { useState } from 'react';
import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import Animated, { FadeIn, FadeOut, LinearTransition } from 'react-native-reanimated';
import { Plus, Route as RouteIcon } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { motion } from '@/ui/motion/motion-tokens';
import { Surface } from '@/ui/primitives/surface';
import { Fab } from '@/ui/primitives/fab';
import { ListSkeleton } from '@/ui/primitives/skeleton';
import { SegmentedControl } from '@/ui/components/segmented-control';
import { TourCard } from '@/ui/components/tour-card';
import { EmptyState } from '@/ui/components/empty-state';
import { ErrorState } from '@/ui/components/error-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { CreateTourSheet } from '@/ui/components/create-tour-sheet';
import { useTours } from '@/state/queries/tours';
import type { TourStatus } from '@/domain/models/tour';
import { useMutedForegroundColor } from '@/ui/theme/colors';

type Filter = 'planned' | 'completed';

export default function ToursListScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const mutedFg = useMutedForegroundColor();
  const [filter, setFilter] = useState<Filter>('planned');
  const [createSheetVisible, setCreateSheetVisible] = useState(false);

  const { data: tours = [], isError, isLoading, refetch } = useTours(filter as TourStatus);

  const closeSheet = () => setCreateSheetVisible(false);

  return (
    <Surface className="flex-1">
      <ScreenHeader variant="root" title={t('tours.list_title')} />

      <View className="px-4 pt-1">
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
          icon={<RouteIcon size={48} color={mutedFg} />}
          title={t('tours.empty_filtered_title')}
          message={t('tours.empty_filtered_message')}
        />
      ) : (
        <FlashList
          data={tours}
          keyExtractor={(t) => t.tour.id}
          contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 96 }}
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

      <Fab
        icon={Plus}
        onPress={() => setCreateSheetVisible(true)}
        accessibilityLabel={t('tours.empty_cta')}
      />

      <CreateTourSheet
        visible={createSheetVisible}
        onClose={closeSheet}
        onPickManual={() => {
          closeSheet();
          router.push('/(tabs)/tours/new/draft' as never);
        }}
        onPickOptimized={() => {
          closeSheet();
          router.push('/(tabs)/tours/new/optimized-config' as never);
        }}
      />
    </Surface>
  );
}
