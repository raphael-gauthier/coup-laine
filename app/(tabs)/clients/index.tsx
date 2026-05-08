import { useState, useMemo } from 'react';
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
import { useClientFiltersStore } from '@/state/ui/client-filters-store';
import { matchesAny } from '@/lib/text-search';
import { useOnContrastColor, useMutedForegroundColor } from '@/ui/theme/colors';

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

  return (
    <Surface className="flex-1">
      <ScreenHeader
        variant="root"
        title={t('clients.list_title')}
        rightSlot={<ClientFilterButton />}
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
    </Surface>
  );
}
