import { useState, useMemo } from 'react';
import { View } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { SearchBar } from '@/ui/components/search-bar';
import { ClientCard } from '@/ui/components/client-card';
import { EmptyState } from '@/ui/components/empty-state';
import { useClients } from '@/state/queries/clients';
import { useProximityStore } from '@/state/stores/proximity-store';
import { matchesQuery } from '@/lib/text-search';

export default function PickPivotScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const [search, setSearch] = useState('');
  const { data: clients = [] } = useClients('all');
  const setPivot = useProximityStore((s) => s.setPivotId);

  const geocoded = useMemo(
    () => clients.filter((c) => c.latitude != null && c.longitude != null),
    [clients]
  );
  const filtered = useMemo(() => {
    if (!search.trim()) return geocoded;
    return geocoded.filter((c) => matchesQuery(c.displayName, search));
  }, [geocoded, search]);

  const onPick = (id: string) => {
    setPivot(id);
    router.back();
  };

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ title: t('proximity.pick_pivot_title'), presentation: 'modal' }} />
      <View className="px-4 pt-3">
        <SearchBar value={search} onChange={setSearch} placeholder={t('clients.search_placeholder')} />
      </View>
      {filtered.length === 0 ? (
        <EmptyState
          title={t('proximity.no_geocoded_title')}
          message={t('proximity.no_geocoded_message')}
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
              onPress={() => onPick(item.id)}
              onToggleWaiting={() => {}}
            />
          )}
        />
      )}
    </Surface>
  );
}
