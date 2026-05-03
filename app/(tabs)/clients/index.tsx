import { useState, useMemo } from 'react';
import { View } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import { Plus, UserRound } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Button } from '@/ui/primitives/button';
import { Text } from '@/ui/primitives/text';
import { ListSkeleton } from '@/ui/primitives/skeleton';
import { SearchBar } from '@/ui/components/search-bar';
import { SegmentedControl } from '@/ui/components/segmented-control';
import { ClientCard } from '@/ui/components/client-card';
import { EmptyState } from '@/ui/components/empty-state';
import { ErrorState } from '@/ui/components/error-state';
import { useClients, useToggleWaiting, type ClientsFilter } from '@/state/queries/clients';
import { matchesQuery } from '@/lib/text-search';

export default function ClientsListScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const [filter, setFilter] = useState<ClientsFilter>('all');
  const [search, setSearch] = useState('');

  const { data: allClients = [], isLoading, isError, refetch } = useClients(filter);
  const toggle = useToggleWaiting();

  const filtered = useMemo(() => {
    if (!search.trim()) return allClients;
    return allClients.filter((c) => matchesQuery(c.displayName, search));
  }, [allClients, search]);

  return (
    <Surface className="flex-1">
      <Stack.Screen
        options={{
          title: t('clients.list_title'),
          headerRight: () => (
            <Button size="sm" onPress={() => router.push('/(tabs)/clients/new')}>
              <Plus size={16} color="white" />
              <Text variant="onPrimary" className="font-semibold">
                {t('clients.empty_cta')}
              </Text>
            </Button>
          ),
        }}
      />

      <View className="px-4 pt-3 gap-3">
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
                <Plus size={16} color="white" />
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
          contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 24 }}
          ItemSeparatorComponent={() => <View className="h-2" />}
          renderItem={({ item }) => (
            <ClientCard
              client={item}
              onPress={() => router.push(`/(tabs)/clients/${item.id}`)}
              onToggleWaiting={() => toggle.mutate({ id: item.id, isWaiting: !item.isWaiting })}
            />
          )}
        />
      )}
    </Surface>
  );
}
