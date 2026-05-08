import { useMemo, useRef } from 'react';
import { View, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import { Search, ChevronRight, X } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { Slider } from '@/ui/primitives/slider';
import { ScreenHeader } from '@/ui/components/screen-header';
import { SegmentedControl } from '@/ui/components/segmented-control';
import { EmptyState } from '@/ui/components/empty-state';
import { Map, type MapHandle } from '@/ui/components/map';
import { ClientPin } from '@/ui/components/client-pin';
import { ClientCard } from '@/ui/components/client-card';
import { ProximityCircle } from '@/ui/components/proximity-circle';
import { PressScale } from '@/ui/motion/press-scale';
import { useClients, useClient, useToggleWaiting } from '@/state/queries/clients';
import { useProximityStore } from '@/state/stores/proximity-store';
import { findNearbyClients } from '@/domain/use-cases/find-nearby-clients';
import { useMutedForegroundColor } from '@/ui/theme/colors';

export default function ProximityScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const mapRef = useRef<MapHandle>(null);
  const { pivotId, radiusKm, view, setPivotId, setRadiusKm, setView } = useProximityStore();
  const { data: pivot } = useClient(pivotId ?? undefined);
  const { data: allClients = [], isLoading: clientsLoading } = useClients('all');
  const toggle = useToggleWaiting();
  const mutedFg = useMutedForegroundColor();

  const nearby = useMemo(() => {
    if (!pivot || pivot.latitude == null || pivot.longitude == null) return [];
    return findNearbyClients({
      pivot: { id: pivot.id, lat: pivot.latitude, lon: pivot.longitude },
      radiusKm,
      clients: allClients.map((c) => ({ id: c.id, lat: c.latitude, lon: c.longitude })),
    });
  }, [pivot, allClients, radiusKm]);

  const nearbyClients = useMemo(() => {
    const clientMap = new globalThis.Map(allClients.map((c) => [c.id, c] as const));
    return nearby
      .map((n) => {
        const c = clientMap.get(n.id);
        return c ? { ...c, distanceKm: n.distanceKm } : null;
      })
      .filter((c): c is NonNullable<typeof c> => c != null);
  }, [nearby, allClients]);

  if (clientsLoading && allClients.length === 0) {
    return (
      <Surface className="flex-1">
        <ScreenHeader variant="root" title={t('proximity.title')} />
        <View className="flex-1 items-center justify-center">
          <ActivityIndicator />
        </View>
      </Surface>
    );
  }

  if (!pivot) {
    return (
      <Surface className="flex-1">
        <ScreenHeader variant="root" title={t('proximity.title')} />
        <EmptyState
          icon={<Search size={48} color={mutedFg} />}
          title={t('proximity.no_pivot_title')}
          message={t('proximity.no_pivot_message')}
          action={
            <Button onPress={() => router.push('/(tabs)/proximity/pick-pivot')}>
              {t('proximity.pick_pivot_cta')}
            </Button>
          }
        />
      </Surface>
    );
  }

  return (
    <Surface className="flex-1">
      <ScreenHeader variant="root" title={t('proximity.title')} />

      <View className="px-4 pt-2 gap-3">
        <PressScale
          onPress={() => router.push('/(tabs)/proximity/pick-pivot')}
          accessibilityLabel={pivot.displayName}
        >
          <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-2">
            <View className="flex-1">
              <Text variant="muted" className="text-xs">{t('proximity.pivot_label')}</Text>
              <Text className="font-semibold mt-0.5">{pivot.displayName}</Text>
            </View>
            <PressScale
              onPress={() => setPivotId(null)}
              accessibilityLabel={t('proximity.clear_pivot')}
              hitSlop={8}
              className="p-1"
            >
              <X size={18} color={mutedFg} />
            </PressScale>
            <ChevronRight size={18} color={mutedFg} />
          </Surface>
        </PressScale>

        <Slider
          value={radiusKm}
          min={5}
          max={80}
          step={1}
          label={t('proximity.radius_label')}
          formatValue={(v) => `${v} km`}
          onChange={setRadiusKm}
        />

        <SegmentedControl<'list' | 'map'>
          value={view}
          onChange={setView}
          options={[
            { value: 'list', label: t('proximity.view_list') },
            { value: 'map', label: t('proximity.view_map') },
          ]}
        />
      </View>

      {view === 'list' ? (
        nearbyClients.length === 0 ? (
          <EmptyState title={t('proximity.empty_title')} message={t('proximity.empty_message')} />
        ) : (
          <FlashList
            data={nearbyClients}
            keyExtractor={(c) => c.id}
            contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 32 }}
            ItemSeparatorComponent={() => <View className="h-2" />}
            renderItem={({ item }) => (
              <ClientCard
                client={item}
                distanceKm={item.distanceKm}
                onPress={() => router.push(`/(tabs)/clients/${item.id}`)}
                onToggleWaiting={() => toggle.mutate({ id: item.id, isWaiting: !item.isWaiting })}
              />
            )}
          />
        )
      ) : (
        <View className="flex-1">
          <Map
            ref={mapRef}
            initialCenter={{ lat: pivot.latitude!, lon: pivot.longitude! }}
            initialZoom={Math.max(8, 14 - Math.log2(Math.max(radiusKm, 1)))}
          >
            <ProximityCircle
              centerLat={pivot.latitude!}
              centerLon={pivot.longitude!}
              radiusKm={radiusKm}
            />
            <ClientPin
              client={pivot as typeof pivot & { latitude: number; longitude: number }}
              onPress={() => router.push(`/(tabs)/clients/${pivot.id}`)}
            />
            {nearbyClients
              .filter((c) => c.latitude != null && c.longitude != null)
              .map((c) => (
                <ClientPin
                  key={c.id}
                  client={c as typeof c & { latitude: number; longitude: number }}
                  onPress={() => router.push(`/(tabs)/clients/${c.id}`)}
                />
              ))}
          </Map>
        </View>
      )}
    </Surface>
  );
}
