import { View, ScrollView, StyleSheet } from 'react-native';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useMemo } from 'react';
import { Pencil, Trash2, CircleCheck } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ErrorState } from '@/ui/components/error-state';
import { confirm } from '@/ui/components/confirm-dialog';
import { errorToast } from '@/ui/components/error-toast';
import { useTour, useDeleteTour } from '@/state/queries/tours';
import { useClients } from '@/state/queries/clients';
import { useBaseAddress } from '@/state/queries/settings';
import { haversineDistanceKm } from '@/lib/haversine-distance';
import { estimateTourArrivals } from '@/domain/use-cases/estimate-tour-arrivals';
import { splitTravelCost } from '@/domain/use-cases/cost-split-calculator';
import { haptics } from '@/ui/motion/haptics';
import { Map } from '@/ui/components/map';
import { ClientPin } from '@/ui/components/client-pin';
import { TourRoutePolyline } from '@/ui/components/tour-route-polyline';

export default function TourDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const { data, isError, refetch } = useTour(id);
  const deleteMutation = useDeleteTour();
  const { data: clients = [] } = useClients('all');
  const { data: base } = useBaseAddress();

  const clientsById = useMemo(() => new globalThis.Map(clients.map((c) => [c.id, c])), [clients]);

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  if (!data) return <Surface className="flex-1" />;

  const { tour, stops } = data;

  const distanceKm = (from: string, to: string): number => {
    const get = (key: string) =>
      key === 'BASE'
        ? base ? { lat: base.lat, lon: base.lon } : null
        : (() => {
            const c = clientsById.get(key);
            return c?.latitude != null && c?.longitude != null
              ? { lat: c.latitude, lon: c.longitude }
              : null;
          })();
    const a = get(from);
    const b = get(to);
    if (!a || !b) return 0;
    return haversineDistanceKm(a, b);
  };
  const minutesBetween = (from: string, to: string) => Math.round(distanceKm(from, to) * 1.5);

  let totalDistanceKm = 0;
  let prev = 'BASE';
  for (const s of stops) {
    totalDistanceKm += distanceKm(prev, s.clientId);
    prev = s.clientId;
  }
  totalDistanceKm += distanceKm(prev, 'BASE');

  // TODO R1.E: derive service minutes from prestation snapshots.
  const arrivals = estimateTourArrivals({
    departureTime: tour.departureTime,
    stops: stops.map((s) => ({
      clientId: s.clientId,
      plannedPrestations: s.plannedPrestations,
    })),
    travelMinutesBetween: minutesBetween,
  });

  const baseToStopDistancesKm = stops.map((s) => distanceKm('BASE', s.clientId));
  const interStopDistancesKm = stops.slice(1).map((s, i) =>
    distanceKm(stops[i]!.clientId, s.clientId)
  );
  const split = splitTravelCost({
    baseToStopDistancesKm,
    interStopDistancesKm,
    pricePerBracket: 8,
    bracketSizeKm: 10,
  });

  const onDelete = async () => {
    const ok = await confirm({
      title: t('tours.delete_confirm_title'),
      message: t('tours.delete_confirm_message'),
      confirmLabel: t('tours.delete'),
      cancelLabel: t('common.cancel'),
      destructive: true,
    });
    if (!ok) return;
    deleteMutation.mutate(tour.id, {
      onSuccess: () => {
        void haptics.success();
        router.back();
      },
      onError: (err) => {
        errorToast(t('tours.delete_failed_title'), err instanceof Error ? err.message : undefined);
      },
    });
  };

  return (
    <Surface className="flex-1">
      <Stack.Screen
        options={{
          title: t('tours.detail_title'),
          headerRight: () => (
            <View className="flex-row gap-2">
              {tour.status !== 'completed' ? (
                <Button
                  size="sm"
                  variant="ghost"
                  onPress={() => router.push(`/(tabs)/tours/${tour.id}/edit` as never)}
                  accessibilityLabel={t('common.edit')}
                >
                  <Pencil size={16} />
                </Button>
              ) : null}
              <Button size="sm" variant="danger" onPress={onDelete} accessibilityLabel={t('tours.delete')}>
                <Trash2 size={16} color="white" />
              </Button>
            </View>
          ),
        }}
      />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 32, gap: 16 }}>
        <Text className="text-2xl font-bold">
          {format(parseISO(`${tour.scheduledDate}T${tour.departureTime}:00`), 'PPPp', { locale: fr })}
        </Text>

        {base && stops.length > 0 ? (
          <View style={styles.mapContainer}>
            <Map
              initialCenter={{ lat: base.lat, lon: base.lon }}
              initialZoom={9}
            >
              <TourRoutePolyline
                coords={[
                  { id: 'BASE', lat: base.lat, lon: base.lon },
                  ...stops
                    .filter((s) => {
                      const c = clientsById.get(s.clientId);
                      return c?.latitude != null && c?.longitude != null;
                    })
                    .map((s) => {
                      const c = clientsById.get(s.clientId)!;
                      return { id: s.clientId, lat: c.latitude!, lon: c.longitude! };
                    }),
                  { id: 'BASE-end', lat: base.lat, lon: base.lon },
                ]}
              />
              {stops
                .filter((s) => {
                  const c = clientsById.get(s.clientId);
                  return c?.latitude != null && c?.longitude != null;
                })
                .map((s) => {
                  const c = clientsById.get(s.clientId)!;
                  return (
                    <ClientPin
                      key={s.id}
                      client={{ ...c, latitude: c.latitude!, longitude: c.longitude! }}
                      onPress={() => {}}
                    />
                  );
                })}
            </Map>
          </View>
        ) : null}

        <Surface variant="muted" className="rounded-2xl px-4 py-3">
          <View className="flex-row justify-between">
            <Text variant="muted">{t('tours.total_distance')}</Text>
            <Text className="font-semibold">{totalDistanceKm.toFixed(1)} km</Text>
          </View>
          <View className="flex-row justify-between mt-1">
            <Text variant="muted">{t('tours.total_duration')}</Text>
            <Text className="font-semibold">
              {Math.floor((tour.totalMinutes ?? 0) / 60)}h {String((tour.totalMinutes ?? 0) % 60).padStart(2, '0')}
            </Text>
          </View>
          <View className="flex-row justify-between mt-1">
            <Text variant="muted">{t('tours.total_cost')}</Text>
            <Text className="font-semibold">{split.totalEuros} €</Text>
          </View>
        </Surface>

        <View className="gap-2">
          <Text className="text-sm font-medium">{t('tours.stops_section')}</Text>
          {stops.map((stop, index) => {
            const client = clientsById.get(stop.clientId);
            const arr = arrivals[index];
            const share = split.perStop[index] ?? 0;
            return (
              <Surface key={stop.id} variant="muted" className="rounded-2xl px-4 py-3 gap-1">
                <View className="flex-row justify-between">
                  <Text className="font-semibold">{client?.displayName ?? stop.clientId}</Text>
                  <Text variant="muted" className="font-mono text-sm">{share} €</Text>
                </View>
                {arr ? (
                  <Text variant="muted" className="text-xs">
                    {t('tours.stop_arrival')} {arr.arrivalTime} · {arr.estimatedMinutes} min
                  </Text>
                ) : null}
              </Surface>
            );
          })}
        </View>

        {tour.status !== 'completed' ? (
          <Button onPress={() => router.push(`/(tabs)/tours/${tour.id}/complete` as never)}>
            <CircleCheck size={18} color="white" />
            <Text variant="onPrimary" className="font-semibold">{t('tours.complete_cta')}</Text>
          </Button>
        ) : null}
      </ScrollView>
    </Surface>
  );
}

const styles = StyleSheet.create({
  mapContainer: {
    height: 200,
    borderRadius: 16,
    overflow: 'hidden',
  },
});
