import { View, ScrollView } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect, useMemo, useState } from 'react';
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
import { StopPaymentSheet } from '@/ui/components/stop-payment-sheet';
import { useTour, useDeleteTour } from '@/state/queries/tours';
import { useClients } from '@/state/queries/clients';
import { useBaseAddress } from '@/state/queries/settings';
import { haptics } from '@/ui/motion/haptics';
import { TourMapPreview, type PreviewStop } from '@/ui/components/tour-map-preview';
import { useOnContrastColor, useForegroundColor } from '@/ui/theme/colors';
import { computeTourPaymentKpis } from '@/domain/use-cases/compute-tour-payment-kpis';
import { estimateTourArrivals } from '@/domain/use-cases/estimate-tour-arrivals';
import { haversineDistanceKm } from '@/lib/haversine-distance';
import type { Payment } from '@/domain/models/payment';

function minutesToTime(minutes: number, departureTime: string): string {
  const [bh, bm] = departureTime.split(':').map(Number);
  const total = (bh ?? 0) * 60 + (bm ?? 0) + minutes;
  const h = Math.floor(total / 60) % 24;
  const m = total % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

function formatEur(cents: number): string {
  return `${(cents / 100).toFixed(0)} €`;
}

interface KpiTileProps {
  label: string;
  value: string;
}

function KpiTile({ label, value }: KpiTileProps) {
  return (
    <Surface variant="muted" className="flex-1 rounded-2xl p-3 gap-1">
      <Text variant="muted" className="text-xs">{label}</Text>
      <Text className="text-xl font-bold">{value}</Text>
    </Surface>
  );
}

export default function TourDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const onContrast = useOnContrastColor();
  const fg = useForegroundColor();
  const { data, isError, refetch } = useTour(id);

  useEffect(() => {
    if (data?.tour.status === 'draft') {
      router.replace(`/tour-new/draft?id=${data.tour.id}` as never);
    }
  }, [data?.tour.status, data?.tour.id, router]);

  const deleteMutation = useDeleteTour();
  const { data: clients = [] } = useClients('all');
  const { data: base } = useBaseAddress();
  const [paymentSheet, setPaymentSheet] = useState<{ stopId: string; payment: Payment } | null>(null);

  const clientsById = useMemo(() => new globalThis.Map(clients.map((c) => [c.id, c])), [clients]);

  const arrivals = useMemo(() => {
    if (!data || !base || data.stops.length === 0) return null;
    const distanceKm = (from: string, to: string): number => {
      const get = (key: string) =>
        key === 'BASE'
          ? { lat: base.lat, lon: base.lon }
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
    return estimateTourArrivals({
      departureTime: data.tour.departureTime ?? '08:00',
      stops: data.stops.map((s) => ({
        clientId: s.clientId,
        plannedServices: s.plannedServices,
      })),
      travelMinutesBetween: (from, to) => Math.round(distanceKm(from, to) * 1.5),
    });
  }, [data, base, clientsById]);

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  if (!data) return <Surface className="flex-1" />;
  if (data.tour.status === 'draft') return <Surface className="flex-1" />;  // redirect in flight
  const { tour, stops } = data;
  if (tour.scheduledDate == null || tour.departureTime == null) {
    return <Surface className="flex-1" />;  // defensive: should not happen for non-draft
  }
  const scheduledDate: string = tour.scheduledDate;
  const departureTime: string = tour.departureTime;

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
          {format(parseISO(`${scheduledDate}T${departureTime}:00`), 'PPPp', { locale: fr })}
        </Text>

        {/* KPI row */}
        <TourKpiRow tourId={tour.id} />

        {/* Payment KPIs — completed tours only */}
        {tour.status === 'completed' ? (() => {
          const kpis = computeTourPaymentKpis({ stops });
          return (
            <View className="flex-row gap-2">
              <KpiTile label={t('payments.kpi_collected')} value={formatEur(kpis.collectedCents)} />
              {kpis.outstandingCents > 0 ? (
                <KpiTile label={t('payments.kpi_outstanding')} value={formatEur(kpis.outstandingCents)} />
              ) : null}
            </View>
          );
        })() : null}

        {/* Service aggregation */}
        <ServiceAggregationSummary tourId={tour.id} />

        {/* Map with route geometry if present */}
        {base && stops.length > 0 && arrivals ? (() => {
          const previewStops: PreviewStop[] = stops
            .map((s, i): PreviewStop | null => {
              const c = clientsById.get(s.clientId);
              if (c?.latitude == null || c?.longitude == null) return null;
              return {
                id: s.id,
                client: { ...c, latitude: c.latitude, longitude: c.longitude },
                arrivalTime:
                  s.arrivalMinutes != null
                    ? minutesToTime(s.arrivalMinutes, departureTime)
                    : arrivals[i]?.arrivalTime,
              };
            })
            .filter((x): x is PreviewStop => x !== null);
          if (previewStops.length === 0) return null;
          return (
            <TourMapPreview
              base={{ lat: base.lat, lon: base.lon }}
              stops={previewStops}
            />
          );
        })() : null}

        {/* Stops list */}
        <View className="gap-2">
          <Text className="text-sm font-medium">{t('tours.stops_section')}</Text>
          {stops.map((stop, i) => (
            <TourStopRow
              key={stop.id}
              stop={stop}
              client={clientsById.get(stop.clientId)}
              departureTime={departureTime}
              showPaymentBadge={tour.status === 'completed'}
              fallbackArrivalTime={arrivals?.[i]?.arrivalTime}
              fallbackDepartureTime={arrivals?.[i]?.departureTime}
              onPress={tour.status === 'completed'
                ? () => setPaymentSheet({ stopId: stop.id, payment: stop.payment })
                : undefined}
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

      <StopPaymentSheet
        visible={paymentSheet !== null}
        stopId={paymentSheet?.stopId ?? null}
        tourId={tour.id}
        initial={paymentSheet?.payment ?? null}
        onClose={() => setPaymentSheet(null)}
      />
    </Surface>
  );
}
