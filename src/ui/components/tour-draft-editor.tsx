import { useState, useMemo } from 'react';
import { View, Platform, StyleSheet } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { GripVertical, Trash2, Plus, ChevronRight, AlertTriangle } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { formatMinutes } from '@/lib/format-minutes';
import { DraggableList } from '@/ui/components/draggable-list';
import { ServicePickerSheet } from '@/ui/components/service-picker-sheet';
import { confirm } from '@/ui/components/confirm-dialog';
import { Map } from '@/ui/components/map';
import { ClientPin } from '@/ui/components/client-pin';
import { BasePin } from '@/ui/components/base-pin';
import { TourRoutePolyline } from '@/ui/components/tour-route-polyline';
import { useClients } from '@/state/queries/clients';
import { haversineDistanceKm } from '@/lib/haversine-distance';
import { estimateTourArrivals } from '@/domain/use-cases/estimate-tour-arrivals';
import { splitTravelCost } from '@/domain/use-cases/cost-split-calculator';
import { useBaseAddress, useAllSettings } from '@/state/queries/settings';
import { useForegroundColor } from '@/ui/theme/colors';
import type { TourStatus } from '@/domain/models/tour';
import type { TourStopService } from '@/domain/models/tour-stop-service';

export interface DraftStop {
  clientId: string;
  clientNameSnapshot?: string | null;
  plannedServices: TourStopService[];
  notes: string | null;
}

interface Props {
  initialStops: DraftStop[];
  initialDate?: string;
  initialTime?: string;
  initialId?: string;
  saving?: boolean;
  onSubmit: (input: {
    scheduledDate: string;
    departureTime: string;
    status: TourStatus;
    stops: DraftStop[];
    totalDistanceKm: number;
    totalMinutes: number;
    totalTravelFeeCents: number;
    feeShareCentsByClient: Record<string, number>;
  }) => void;
  onAddClients: () => void;
  onRemoveStop: (clientId: string) => void;
  onReorderStops: (next: DraftStop[]) => void;
  onUpdateStopServices?: (clientId: string, prests: TourStopService[]) => void;
}

const DEFAULT_BRACKET_KM = 10;
const DEFAULT_FEE_PER_BRACKET = 8;

export function TourDraftEditor({
  initialStops, initialDate, initialTime,
  saving, onSubmit, onAddClients, onRemoveStop, onReorderStops, onUpdateStopServices,
}: Props) {
  const { t } = useTranslation();
  const today = new Date();
  const [date, setDate] = useState<Date>(initialDate ? parseISO(initialDate) : today);
  const [time, setTime] = useState(initialTime ?? '08:00');
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);

  const { data: clients = [] } = useClients('all');
  const { data: base } = useBaseAddress();
  const { data: allSettings } = useAllSettings();
  const fg = useForegroundColor();
  const bracketKm = parseFloat(allSettings?.tour_bracket_km ?? '') || DEFAULT_BRACKET_KM;
  const feePerBracket = parseFloat(allSettings?.tour_fee_eur_per_bracket ?? '') || DEFAULT_FEE_PER_BRACKET;
  const [pickerClientId, setPickerClientId] = useState<string | null>(null);

  const clientsById = useMemo(() => new globalThis.Map(clients.map((c) => [c.id, c])), [clients]);

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

  const totalDistanceKm = useMemo(() => {
    let sum = 0;
    let prev = 'BASE';
    for (const s of initialStops) {
      sum += distanceKm(prev, s.clientId);
      prev = s.clientId;
    }
    sum += distanceKm(prev, 'BASE');
    return sum;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [initialStops, base, clients]);

  const arrivals = useMemo(
    () =>
      estimateTourArrivals({
        departureTime: time,
        stops: initialStops.map((s) => ({
          clientId: s.clientId,
          plannedServices: s.plannedServices,
        })),
        travelMinutesBetween: minutesBetween,
      }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [initialStops, time, base, clients]
  );

  const totalMinutes = useMemo(() => {
    let sum = 0;
    for (const a of arrivals) sum += a.estimatedMinutes;
    let prev = 'BASE';
    for (const s of initialStops) {
      sum += minutesBetween(prev, s.clientId);
      prev = s.clientId;
    }
    sum += minutesBetween(prev, 'BASE');
    return sum;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [initialStops, arrivals]);

  const split = useMemo(() => {
    const baseToStopDistancesKm = initialStops.map((s) => distanceKm('BASE', s.clientId));
    const interStopDistancesKm = initialStops.slice(1).map((s, i) =>
      distanceKm(initialStops[i]!.clientId, s.clientId)
    );
    return splitTravelCost({
      baseToStopDistancesKm,
      interStopDistancesKm,
      pricePerBracket: feePerBracket,
      bracketSizeKm: bracketKm,
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [initialStops, base, clients, bracketKm, feePerBracket]);

  const submit = async () => {
    if (initialStops.length === 0) return;
    const stopsWithoutServices = initialStops.filter((s) => s.plannedServices.length === 0);
    if (stopsWithoutServices.length > 0) {
      const ok = await confirm({
        title: t('tours.no_service_warning_title'),
        message: t('tours.no_service_warning_message', { count: stopsWithoutServices.length }),
        confirmLabel: t('tours.no_service_warning_continue'),
        cancelLabel: t('common.cancel'),
      });
      if (!ok) return;
    }
    const feeShareCentsByClient: Record<string, number> = {};
    initialStops.forEach((s, i) => {
      feeShareCentsByClient[s.clientId] = Math.round((split.perStop[i] ?? 0) * 100);
    });
    onSubmit({
      scheduledDate: format(date, 'yyyy-MM-dd'),
      departureTime: time,
      status: 'planned',
      stops: initialStops.map((s) => ({
        ...s,
        clientNameSnapshot: clientsById.get(s.clientId)?.displayName ?? null,
      })),
      totalDistanceKm,
      totalMinutes,
      totalTravelFeeCents: Math.round(split.totalEuros * 100),
      feeShareCentsByClient,
    });
  };

  const routeCoords = useMemo(() => {
    if (!base) return [];
    const stopsWithCoords = initialStops
      .map((s) => {
        const c = clientsById.get(s.clientId);
        if (c?.latitude == null || c?.longitude == null) return null;
        return { id: s.clientId, lat: c.latitude, lon: c.longitude };
      })
      .filter((x): x is { id: string; lat: number; lon: number } => x !== null);
    if (stopsWithCoords.length === 0) return [];
    return [
      { id: 'BASE', lat: base.lat, lon: base.lon },
      ...stopsWithCoords,
      { id: 'BASE-end', lat: base.lat, lon: base.lon },
    ];
  }, [base, initialStops, clientsById]);

  const Header = (
    <View style={{ gap: 16, paddingTop: 16, paddingBottom: 8 }}>
      {base && routeCoords.length > 0 ? (
        <View style={styles.mapContainer}>
          <Map initialCenter={{ lat: base.lat, lon: base.lon }} initialZoom={9}>
            <TourRoutePolyline coords={routeCoords} />
            {initialStops.map((s) => {
              const c = clientsById.get(s.clientId);
              if (c?.latitude == null || c?.longitude == null) return null;
              return (
                <ClientPin
                  key={s.clientId}
                  client={{ ...c, latitude: c.latitude, longitude: c.longitude }}
                  onPress={() => {}}
                />
              );
            })}
            <BasePin lat={base.lat} lon={base.lon} />
          </Map>
        </View>
      ) : null}

      <View className="gap-2">
        <Text className="text-sm font-medium">{t('tours.scheduled_date')}</Text>
        <PressScale onPress={() => setShowDatePicker(true)}>
          <Surface variant="muted" className="rounded-2xl px-4 py-3">
            <Text>{format(date, 'PPPP', { locale: fr })}</Text>
          </Surface>
        </PressScale>
        {showDatePicker && (
          <DateTimePicker
            value={date}
            mode="date"
            onChange={(_, d) => {
              setShowDatePicker(Platform.OS === 'ios');
              if (d) setDate(d);
            }}
          />
        )}
      </View>

      <View className="gap-2">
        <Text className="text-sm font-medium">{t('tours.departure_time')}</Text>
        <PressScale onPress={() => setShowTimePicker(true)}>
          <Surface variant="muted" className="rounded-2xl px-4 py-3">
            <Text>{time}</Text>
          </Surface>
        </PressScale>
        {showTimePicker && (
          <DateTimePicker
            value={(() => {
              const [h, m] = time.split(':').map(Number);
              const d = new Date();
              d.setHours(h ?? 0, m ?? 0, 0, 0);
              return d;
            })()}
            mode="time"
            is24Hour
            onChange={(_, d) => {
              setShowTimePicker(Platform.OS === 'ios');
              if (d) setTime(format(d, 'HH:mm'));
            }}
          />
        )}
      </View>

      <Surface variant="muted" className="rounded-2xl px-4 py-3">
        <View className="flex-row justify-between">
          <Text variant="muted">{t('tours.total_distance')}</Text>
          <Text className="font-semibold">{totalDistanceKm.toFixed(1)} km</Text>
        </View>
        <View className="flex-row justify-between mt-1">
          <Text variant="muted">{t('tours.total_duration')}</Text>
          <Text className="font-semibold">{formatMinutes(totalMinutes)}</Text>
        </View>
        <View className="flex-row justify-between mt-1">
          <Text variant="muted">{t('tours.total_cost')}</Text>
          <Text className="font-semibold">{split.totalEuros} €</Text>
        </View>
      </Surface>

      <View className="flex-row items-center justify-between">
        <Text className="text-sm font-medium">{t('tours.stops_section')}</Text>
        <Button size="sm" variant="ghost" onPress={onAddClients}>
          <Plus size={14} color={fg} />
          <Text className="font-semibold text-sm">{t('tours.add_stops')}</Text>
        </Button>
      </View>
      <Text variant="muted" className="text-xs">{t('tours.reorder_hint')}</Text>
    </View>
  );

  const Footer = (
    <View style={{ gap: 8, paddingTop: 16, paddingBottom: 16 }}>
      <Button
        onPress={() => void submit()}
        loading={saving}
        disabled={initialStops.length === 0 || saving}
      >
        {t('common.save')}
      </Button>
    </View>
  );

  const pickerStop = pickerClientId ? initialStops.find((s) => s.clientId === pickerClientId) : null;
  const pickerClient = pickerClientId ? clientsById.get(pickerClientId) : null;

  return (
    <>
    <DraggableList
      data={initialStops}
      keyExtractor={(s) => s.clientId}
      onReorder={onReorderStops}
      ListHeaderComponent={Header}
      ListFooterComponent={Footer}
      contentContainerStyle={{ paddingHorizontal: 16 }}
      renderItem={({ item, index, drag }) => {
        const client = clientsById.get(item.clientId);
        const arr = arrivals[index];
        const share = split.perStop[index] ?? 0;
        return (
          <Surface variant="muted" className="rounded-2xl px-3 py-3 mb-2">
            <View className="flex-row items-center gap-3">
              <PressScale onPressIn={drag}>
                <GripVertical size={20} color="#5C4E40" />
              </PressScale>
              <PressScale className="flex-1" onPress={() => setPickerClientId(item.clientId)}>
                <View className="flex-row items-center gap-2">
                  <View className="flex-1 gap-1">
                    <Text className="font-semibold">{client?.displayName ?? item.clientId}</Text>
                    {arr ? (
                      <Text variant="muted" className="text-xs">
                        {t('tours.stop_arrival')} {arr.arrivalTime} · {formatMinutes(arr.estimatedMinutes)} · {share} €
                      </Text>
                    ) : null}
                    {item.plannedServices.length > 0 ? (() => {
                      const totalMinutes = item.plannedServices.reduce(
                        (sum, p) => sum + p.qty * p.minutesSnapshot,
                        0
                      );
                      const totalCents = item.plannedServices.reduce(
                        (sum, p) => sum + p.qty * p.priceCentsSnapshot,
                        0
                      );
                      return (
                        <Text variant="muted" className="text-xs">
                          {t('tours.stop_summary', {
                            count: item.plannedServices.length,
                            duration: formatMinutes(totalMinutes),
                            amount: `${(totalCents / 100).toFixed(2)} €`,
                          })}
                        </Text>
                      );
                    })() : (
                      <View className="flex-row items-center gap-2">
                        <AlertTriangle size={14} color="#B23832" />
                        <Text className="text-xs text-danger dark:text-danger-dark font-medium">
                          {t('tours.stop_no_service')}
                        </Text>
                      </View>
                    )}
                  </View>
                  <ChevronRight size={18} color="#5C4E40" />
                </View>
              </PressScale>
              <PressScale onPress={() => onRemoveStop(item.clientId)}>
                <Trash2 size={16} color="#B23832" />
              </PressScale>
            </View>
          </Surface>
        );
      }}
    />
    {pickerClientId && pickerClient ? (
      <ServicePickerSheet
        key={pickerClientId}
        visible
        clientAnimalCounts={pickerClient.animalCounts}
        initialSelection={pickerStop?.plannedServices ?? []}
        onConfirm={(services) => {
          if (onUpdateStopServices) {
            onUpdateStopServices(pickerClientId, services);
          }
          setPickerClientId(null);
        }}
        onClose={() => setPickerClientId(null)}
      />
    ) : null}
    </>
  );
}

const styles = StyleSheet.create({
  mapContainer: {
    height: 200,
    borderRadius: 16,
    overflow: 'hidden',
  },
});
