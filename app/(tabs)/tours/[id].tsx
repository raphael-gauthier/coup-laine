import { View, ScrollView, StyleSheet } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useMemo } from 'react';
import { Pencil, Trash2, CircleCheck } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ErrorState } from '@/ui/components/error-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { confirm } from '@/ui/components/confirm-dialog';
import { mutationErrorToast } from '@/ui/components/error-toast';
import { TourKpiRow } from '@/ui/components/tour-kpi-row';
import { ServiceAggregationSummary } from '@/ui/components/service-aggregation-summary';
import { TourStopRow } from '@/ui/components/tour-stop-row';
import { useTour, useDeleteTour } from '@/state/queries/tours';
import { useClients } from '@/state/queries/clients';
import { useBaseAddress } from '@/state/queries/settings';
import { haptics } from '@/ui/motion/haptics';
import { Map } from '@/ui/components/map';
import { ClientPin } from '@/ui/components/client-pin';
import { BasePin } from '@/ui/components/base-pin';
import { TourRoutePolyline } from '@/ui/components/tour-route-polyline';
import { useOnContrastColor, useForegroundColor } from '@/ui/theme/colors';

export default function TourDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const onContrast = useOnContrastColor();
  const fg = useForegroundColor();
  const { data, isError, refetch } = useTour(id);
  const deleteMutation = useDeleteTour();
  const { data: clients = [] } = useClients('all');
  const { data: base } = useBaseAddress();

  const clientsById = useMemo(() => new globalThis.Map(clients.map((c) => [c.id, c])), [clients]);

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  if (!data) return <Surface className="flex-1" />;

  const { tour, stops } = data;

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
        mutationErrorToast(t('tours.delete_failed_title'), err);
      },
    });
  };

  const routeGeometry = tour.routeGeometry
    ? (() => { try { return JSON.parse(tour.routeGeometry); } catch { return null; } })()
    : null;

  return (
    <Surface className="flex-1">
      <ScreenHeader
        title={t('tours.detail_title')}
        rightSlot={
          <View className="flex-row gap-2">
            {tour.status !== 'completed' ? (
              <Button
                size="sm"
                variant="ghost"
                onPress={() => router.push(`/(tabs)/tours/${tour.id}/edit` as never)}
                accessibilityLabel={t('common.edit')}
              >
                <Pencil size={16} color={fg} />
              </Button>
            ) : null}
            <Button size="sm" variant="danger" onPress={onDelete} accessibilityLabel={t('tours.delete')}>
              <Trash2 size={16} color={onContrast} />
            </Button>
          </View>
        }
      />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 32, gap: 16 }}>
        {/* Header date + status */}
        <Text className="text-2xl font-bold">
          {format(parseISO(`${tour.scheduledDate}T${tour.departureTime}:00`), 'PPPp', { locale: fr })}
        </Text>

        {/* KPI row */}
        <TourKpiRow tourId={tour.id} />

        {/* Service aggregation */}
        <ServiceAggregationSummary tourId={tour.id} />

        {/* Map with route geometry if present */}
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
              <BasePin lat={base.lat} lon={base.lon} />
            </Map>
          </View>
        ) : null}

        {/* Stops list */}
        <View className="gap-2">
          <Text className="text-sm font-medium">{t('tours.stops_section')}</Text>
          {stops.map((stop) => (
            <TourStopRow
              key={stop.id}
              stop={stop}
              client={clientsById.get(stop.clientId)}
              departureTime={tour.departureTime}
            />
          ))}
        </View>

        {/* Complete button */}
        {tour.status !== 'completed' ? (
          <Button
            onPress={() => router.push(`/(tabs)/tours/${tour.id}/complete` as never)}
            accessibilityLabel={t('tours.complete_cta')}
          >
            <CircleCheck size={18} color={onContrast} />
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
