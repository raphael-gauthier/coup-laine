import { useState, useMemo } from 'react';
import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import Animated, { FadeIn, FadeOut, LinearTransition } from 'react-native-reanimated';
import { Plus, UserRound } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { motion } from '@/ui/motion/motion-tokens';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';
import { Surface } from '@/ui/primitives/surface';
import { Button } from '@/ui/primitives/button';
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
import { useClients, useToggleWaiting, useClientStatusMap, type ClientsFilter } from '@/state/queries/clients';
import { useClientFiltersStore } from '@/state/ui/client-filters-store';
import { matchesAny } from '@/lib/text-search';
import { useOnContrastColor } from '@/ui/theme/colors';

export default function ClientsListScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const onContrast = useOnContrastColor();
  const [filter, setFilter] = useState<ClientsFilter>('all');
  const [search, setSearch] = useState('');

  const { data: allClients = [], isLoading, isError, refetch } = useClients(filter);
  const { data: statusMap } = useClientStatusMap();
  const toggle = useToggleWaiting();
  const { enabledStatuses } = useClientFiltersStore();

  const filtered = useMemo(() => {
    let list = allClients;
    // Apply status filter
    if (enabledStatuses.size < 6 && statusMap) {
      list = list.filter((c) => {
        const s = statusMap.get(c.id) ?? 'default';
        return enabledStatuses.has(s);
      });
    }
    // Apply text search
    if (search.trim()) {
      list = list.filter((c) => matchesAny([c.displayName, c.addressCity], search));
    }
    return list;
  }, [allClients, search, enabledStatuses, statusMap]);

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
            { value: 'waiting', label: t('clients.filter_waiting') },
          ]}
        />
      </View>

      {isError ? (
        <ErrorState onRetry={() => refetch()} />
      ) : isLoading ? (
        <ListSkeleton />
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={<UserRound size={48} color="#5C4E40" />}
          title={search ? t('clients.empty_filtered_title') : t('clients.empty_title')}
          message={search ? t('clients.empty_filtered_message') : t('clients.empty_message')}
          action={
            !search ? (
              <Button onPress={() => router.push('/(tabs)/clients/new')}>
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

      <PressScale
        onPress={() => {
          void haptics.selection();
          router.push('/(tabs)/clients/new');
        }}
        accessibilityLabel={t('clients.empty_cta')}
        style={{ position: 'absolute', bottom: 24, right: 24 }}
      >
        <Surface
          variant="primary"
          className="rounded-full p-4"
          style={{ shadowColor: '#000', shadowOpacity: 0.2, shadowRadius: 6, elevation: 6 }}
        >
          <Plus size={24} color={onContrast} />
        </Surface>
      </PressScale>
    </Surface>
  );
}
