import { useState, useMemo } from 'react';
import { View } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import { Check } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { SearchBar } from '@/ui/components/search-bar';
import { SegmentedControl } from '@/ui/components/segmented-control';
import { EmptyState } from '@/ui/components/empty-state';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';
import { useClients, type ClientsFilter } from '@/state/queries/clients';
import { useTourDraftStore } from '@/state/stores/tour-draft-store';
import { matchesQuery } from '@/lib/text-search';
import { cn } from '@/lib/cn';

export default function PickClientsScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const [filter, setFilter] = useState<ClientsFilter>('waiting');
  const [search, setSearch] = useState('');
  const { data: clients = [] } = useClients(filter);
  const picked = useTourDraftStore((s) => s.pickedClientIds);
  const toggle = useTourDraftStore((s) => s.toggle);

  const filtered = useMemo(() => {
    if (!search.trim()) return clients;
    return clients.filter((c) => matchesQuery(c.displayName, search));
  }, [clients, search]);

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ title: t('tours.pick_clients_title'), presentation: 'modal' }} />

      <View className="px-4 pt-3 gap-3">
        <SearchBar value={search} onChange={setSearch} placeholder={t('clients.search_placeholder')} />
        <SegmentedControl<ClientsFilter>
          value={filter}
          onChange={setFilter}
          options={[
            { value: 'waiting', label: t('clients.filter_waiting') },
            { value: 'all', label: t('clients.filter_all') },
          ]}
        />
      </View>

      {filtered.length === 0 ? (
        <EmptyState title={t('clients.empty_title')} message={t('clients.empty_message')} />
      ) : (
        <FlashList
          data={filtered}
          keyExtractor={(c) => c.id}
          contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 96 }}
          ItemSeparatorComponent={() => <View className="h-2" />}
          renderItem={({ item }) => {
            const isPicked = picked.includes(item.id);
            return (
              <PressScale
                onPress={() => {
                  void haptics.selection();
                  toggle(item.id);
                }}
              >
                <Surface
                  variant="muted"
                  className={cn(
                    'flex-row items-center rounded-2xl px-4 py-3 gap-3',
                    isPicked && 'border-2 border-primary dark:border-primary-dark'
                  )}
                >
                  <View className={cn(
                    'w-6 h-6 rounded-full items-center justify-center',
                    isPicked ? 'bg-primary dark:bg-primary-dark' : 'bg-background dark:bg-background-dark'
                  )}>
                    {isPicked ? <Check size={14} color="white" /> : null}
                  </View>
                  <View className="flex-1">
                    <Text className="font-semibold">{item.displayName}</Text>
                    {item.addressCity ? (
                      <Text variant="muted" className="text-sm mt-0.5">{item.addressCity}</Text>
                    ) : null}
                  </View>
                </Surface>
              </PressScale>
            );
          }}
        />
      )}

      {picked.length > 0 ? (
        <View className="absolute bottom-4 left-4 right-4">
          <Button onPress={() => router.back()}>
            {t('tours.pick_clients_continue', { count: picked.length })}
          </Button>
        </View>
      ) : null}
    </Surface>
  );
}
