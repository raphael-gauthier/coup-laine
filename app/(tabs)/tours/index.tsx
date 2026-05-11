import { useEffect, useRef, useState } from 'react';
import { View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import Animated, { FadeIn, FadeOut, LinearTransition } from 'react-native-reanimated';
import { Plus, Route as RouteIcon, FileText } from 'lucide-react-native';
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
import { TUTORIAL_KEYS } from '@/domain/tutorial/keys';
import { HelpButton } from '@/ui/help/help-button';
import { HelpSheetTours } from '@/ui/help/sheets/help-sheet-tours';
import { CoachMark } from '@/ui/help/coach-mark';
import { useHelpSheet, useCoachMark } from '@/ui/help/hooks';
import { useClients } from '@/state/queries/clients';

type Filter = 'draft' | 'planned' | 'completed';

export default function ToursListScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const mutedFg = useMutedForegroundColor();
  const params = useLocalSearchParams<{ filter?: Filter }>();
  const [filter, setFilter] = useState<Filter>(params.filter ?? 'planned');

  useEffect(() => {
    if (params.filter && params.filter !== filter) {
      setFilter(params.filter);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [params.filter]);
  const [createSheetVisible, setCreateSheetVisible] = useState(false);

  const { data: tours = [], isError, isLoading, refetch } = useTours(filter as TourStatus);

  const helpSheet = useHelpSheet(TUTORIAL_KEYS.sheetTours);
  const emptyCtaRef = useRef<View>(null);
  const { data: allClientsForCoachmark = [] } = useClients('all');
  // Spec §7.2: only fire when 1+ clients AND 0 tours, to avoid overlapping
  // with the first-client coach-mark on the sibling tab.
  const coachmark = useCoachMark(
    TUTORIAL_KEYS.coachmarkFirstTour,
    !isLoading && !isError && allClientsForCoachmark.length >= 1 && tours.length === 0,
  );

  const headerHelpAnchorRef = useRef<View>(null);
  const { data: completedToursForCatalog = [] } = useTours('completed');
  const catalogCoach = useCoachMark(
    TUTORIAL_KEYS.coachmarkDiscoverCatalog,
    !isLoading && !isError && completedToursForCatalog.length >= 1,
  );

  const closeSheet = () => setCreateSheetVisible(false);

  const renderEmpty = () => {
    if (filter === 'draft') {
      return (
        <EmptyState
          icon={<FileText size={48} color={mutedFg} />}
          title={t('tours.draft_empty_title')}
          message={t('tours.draft_empty_message')}
        />
      );
    }
    return (
      <EmptyState
        icon={<RouteIcon size={48} color={mutedFg} />}
        title={t('tours.empty_filtered_title')}
        message={t('tours.empty_filtered_message')}
      />
    );
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader
        variant="root"
        title={t('tours.list_title')}
        rightSlot={
          <View ref={headerHelpAnchorRef} collapsable={false}>
            <HelpButton tutorialKey={TUTORIAL_KEYS.sheetTours} onPress={helpSheet.open} />
          </View>
        }
      />

      <View className="px-4 pt-1">
        <SegmentedControl<Filter>
          value={filter}
          onChange={setFilter}
          options={[
            { value: 'draft',     label: t('tours.filter_draft') },
            { value: 'planned',   label: t('tours.filter_planned') },
            { value: 'completed', label: t('tours.filter_completed') },
          ]}
        />
      </View>

      {isError ? (
        <ErrorState onRetry={() => refetch()} />
      ) : isLoading ? (
        <ListSkeleton />
      ) : tours.length === 0 ? (
        <View ref={emptyCtaRef} collapsable={false}>
          {renderEmpty()}
        </View>
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
          router.push('/tour-new/draft' as never);
        }}
        onPickOptimized={() => {
          closeSheet();
          router.push('/tour-new/optimized-config' as never);
        }}
      />

      <HelpSheetTours visible={helpSheet.isOpen} onClose={helpSheet.close} />
      <CoachMark
        visible={coachmark.isVisible}
        onDismiss={coachmark.dismiss}
        anchorRef={emptyCtaRef}
        arrowDirection="up"
        title={t('coachmark.first_tour.title')}
        body={t('coachmark.first_tour.body')}
      />
      <CoachMark
        visible={catalogCoach.isVisible}
        onDismiss={catalogCoach.dismiss}
        anchorRef={headerHelpAnchorRef}
        arrowDirection="up"
        title={t('coachmark.discover_catalog.title')}
        body={t('coachmark.discover_catalog.body')}
      />
    </Surface>
  );
}
