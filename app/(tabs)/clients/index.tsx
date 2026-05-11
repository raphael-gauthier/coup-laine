import { useState, useMemo, useRef } from 'react';
import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import Animated, { FadeIn, FadeOut, LinearTransition } from 'react-native-reanimated';
import { Plus, UserRound } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { motion } from '@/ui/motion/motion-tokens';
import { Surface } from '@/ui/primitives/surface';
import { Button } from '@/ui/primitives/button';
import { Fab } from '@/ui/primitives/fab';
import { Text } from '@/ui/primitives/text';
import { ListSkeleton } from '@/ui/primitives/skeleton';
import { SearchBar } from '@/ui/components/search-bar';
import { SegmentedControl } from '@/ui/components/segmented-control';
import { ClientCard } from '@/ui/components/client-card';
import { EmptyState } from '@/ui/components/empty-state';
import { ErrorState } from '@/ui/components/error-state';
import { RecomputeBanner } from '@/ui/components/recompute-banner';
import { ScreenHeader } from '@/ui/components/screen-header';
import { ClientFilterButton } from '@/ui/components/client-status-filter-dialog';
import { useClients, useToggleWaiting, useDisplayedStatusMap, useClientsWithOutstanding, type ClientsFilter } from '@/state/queries/clients';
import { useStatusRegistry } from '@/state/queries/statuses';
import { useTours } from '@/state/queries/tours';
import { useSession } from '@/state/queries/auth';
import { useClientFiltersStore } from '@/state/ui/client-filters-store';
import { matchesAny } from '@/lib/text-search';
import { useOnContrastColor, useMutedForegroundColor } from '@/ui/theme/colors';
import { TUTORIAL_KEYS } from '@/domain/tutorial/keys';
import { HelpButton } from '@/ui/help/help-button';
import { HelpSheetClients } from '@/ui/help/sheets/help-sheet-clients';
import { CoachMark } from '@/ui/help/coach-mark';
import { useHelpSheet, useCoachMark } from '@/ui/help/hooks';

export default function ClientsListScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const onContrast = useOnContrastColor();
  const mutedFg = useMutedForegroundColor();
  const [filter, setFilter] = useState<ClientsFilter>('all');
  const [search, setSearch] = useState('');

  const { data: allClients = [], isLoading, isError, refetch } = useClients(filter);
  const { data: displayedMap } = useDisplayedStatusMap();
  const { data: outstandingIds } = useClientsWithOutstanding();
  const { data: registry } = useStatusRegistry();
  const toggle = useToggleWaiting();
  const { enabledStatusIds, uninitialized } = useClientFiltersStore();
  const waitingLabel = registry?.bySystemKey('waiting').label ?? t('clients.filter_waiting');

  const filtered = useMemo(() => {
    let list = allClients;
    // Apply status filter (only once initialized — initial state means "show all")
    if (!uninitialized && displayedMap) {
      list = list.filter((c) => {
        const status = displayedMap.get(c.id);
        if (status && !enabledStatusIds.has(status.id)) return false;
        return true;
      });
    }
    // Apply outstanding filter
    if (filter === 'outstanding' && outstandingIds) {
      list = list.filter((c) => outstandingIds.has(c.id));
    }
    // Apply text search
    if (search.trim()) {
      list = list.filter((c) => matchesAny([c.displayName, c.addressCity], search));
    }
    return list;
  }, [allClients, search, enabledStatusIds, uninitialized, displayedMap, filter, outstandingIds]);

  const helpSheet = useHelpSheet(TUTORIAL_KEYS.sheetClients);
  const emptyCtaRef = useRef<View>(null);
  const coachmark = useCoachMark(
    TUTORIAL_KEYS.coachmarkFirstClient,
    !isLoading && !isError && allClients.length === 0,
  );

  // Phase 2 anchors and predicates
  const headerHelpAnchorRef = useRef<View>(null);
  const filterAnchorRef = useRef<View>(null);

  const { data: session } = useSession();
  const isCloudOptedIn = !!session && !session.user.is_anonymous;

  const { data: completedTours = [] } = useTours('completed');
  const completedToursCount = completedTours.length;

  const cloudCoach = useCoachMark(
    TUTORIAL_KEYS.coachmarkCloudBackup,
    !isLoading && !isError
      && !isCloudOptedIn
      && (allClients.length >= 5 || completedToursCount >= 1),
  );

  const statusesCoach = useCoachMark(
    TUTORIAL_KEYS.coachmarkManualStatuses,
    !isLoading && !isError
      && allClients.length >= 10
      && !cloudCoach.isVisible,
  );

  return (
    <Surface className="flex-1">
      <ScreenHeader
        variant="root"
        title={t('clients.list_title')}
        rightSlot={
          <View className="flex-row items-center gap-1">
            <View ref={filterAnchorRef} collapsable={false}>
              <ClientFilterButton />
            </View>
            <View ref={headerHelpAnchorRef} collapsable={false}>
              <HelpButton tutorialKey={TUTORIAL_KEYS.sheetClients} onPress={helpSheet.open} />
            </View>
          </View>
        }
      />

      <RecomputeBanner />

      <View className="px-4 pt-2 gap-3">
        <SearchBar value={search} onChange={setSearch} placeholder={t('clients.search_placeholder')} />
        <SegmentedControl<ClientsFilter>
          value={filter}
          onChange={setFilter}
          options={[
            { value: 'all', label: t('clients.filter_all') },
            { value: 'waiting', label: waitingLabel },
            { value: 'outstanding', label: t('clients.filters.outstanding') },
          ]}
        />
      </View>

      {isError ? (
        <ErrorState onRetry={() => refetch()} />
      ) : isLoading ? (
        <ListSkeleton />
      ) : filtered.length === 0 ? (
        <View ref={emptyCtaRef} collapsable={false}>
          <EmptyState
            icon={<UserRound size={48} color={mutedFg} />}
            title={search ? t('clients.empty_filtered_title') : t('clients.empty_title')}
            message={search ? t('clients.empty_filtered_message') : t('clients.empty_message')}
            action={
              !search ? (
                <Button
                  onPress={() => router.push('/(tabs)/clients/new')}
                  accessibilityLabel={t('clients.empty_cta')}
                >
                  <Plus size={16} color={onContrast} />
                  <Text variant="onPrimary" className="font-semibold">
                    {t('clients.empty_cta')}
                  </Text>
                </Button>
              ) : undefined
            }
          />
        </View>
      ) : (
        <FlashList
          data={filtered}
          keyExtractor={(c) => c.id}
          contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 96 }}
          ItemSeparatorComponent={() => <View className="h-2" />}
          renderItem={({ item }) => (
            <Animated.View
              entering={FadeIn.duration(motion.duration.fast)}
              exiting={FadeOut.duration(motion.duration.fast)}
              layout={LinearTransition.duration(motion.duration.normal)}
            >
              <ClientCard
                client={item}
                onPress={() => router.push(`/(tabs)/clients/${item.id}`)}
                onToggleWaiting={() => toggle.mutate({ id: item.id, isWaiting: !item.isWaiting })}
              />
            </Animated.View>
          )}
        />
      )}

      <Fab
        icon={Plus}
        onPress={() => router.push('/(tabs)/clients/new')}
        accessibilityLabel={t('clients.empty_cta')}
      />

      <HelpSheetClients visible={helpSheet.isOpen} onClose={helpSheet.close} />
      <CoachMark
        visible={coachmark.isVisible}
        onDismiss={coachmark.dismiss}
        anchorRef={emptyCtaRef}
        arrowDirection="up"
        title={t('coachmark.first_client.title')}
        body={t('coachmark.first_client.body')}
      />
      <CoachMark
        visible={cloudCoach.isVisible}
        onDismiss={cloudCoach.dismiss}
        anchorRef={headerHelpAnchorRef}
        arrowDirection="up"
        title={t('coachmark.cloud_backup.title')}
        body={t('coachmark.cloud_backup.body')}
      />
      <CoachMark
        visible={statusesCoach.isVisible}
        onDismiss={statusesCoach.dismiss}
        anchorRef={filterAnchorRef}
        arrowDirection="up"
        title={t('coachmark.manual_statuses.title')}
        body={t('coachmark.manual_statuses.body')}
      />
    </Surface>
  );
}
