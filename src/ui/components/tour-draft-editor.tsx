import { useState, useMemo } from 'react';
import { TextInput, View, Platform } from 'react-native';
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
import { ScheduleTourSheet } from '@/ui/components/schedule-tour-sheet';
import { confirm } from '@/ui/components/confirm-dialog';
import { TourMapPreview, type PreviewStop } from '@/ui/components/tour-map-preview';
import { useClients } from '@/state/queries/clients';
import { haversineDistanceKm } from '@/lib/haversine-distance';
import { estimateTourArrivals } from '@/domain/use-cases/estimate-tour-arrivals';
import { computeClientTravelFee } from '@/domain/use-cases/compute-client-travel-fee';
import { useBaseAddress, useAllSettings } from '@/state/queries/settings';
import { useForegroundColor, useOnContrastColor } from '@/ui/theme/colors';
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
  initialDate?: string | null;
  initialTime?: string | null;
  initialTitle?: string | null;
  initialId?: string;
  tourStatus?: TourStatus;            // 'draft' | 'planned' | 'completed' — default 'draft'
  saving?: boolean;
  onSaveDraft?: (input: {
    title: string | null;
    stops: DraftStop[];
    totalDistanceKm: number;
    totalMinutes: number;
  }) => void;
  onSchedule: (input: {
    title: string | null;
    scheduledDate: string;
    departureTime: string;
    stops: DraftStop[];
    totalDistanceKm: number;
    totalMinutes: number;
  }) => void;
  onDelete?: () => void;             // visible only when status='draft' AND initialId is present
  onAddClients: () => void;
  onRemoveStop: (clientId: string) => void;
  onReorderStops: (next: DraftStop[]) => void;
  onUpdateStopServices?: (clientId: string, prests: TourStopService[]) => void;
}

const DEFAULT_BRACKET_KM = 10;
const DEFAULT_FEE_PER_BRACKET = 8;

export function TourDraftEditor({
  initialStops, initialDate, initialTime, initialTitle, initialId,
  tourStatus = 'draft',
  saving, onSaveDraft, onSchedule, onDelete,
  onAddClients, onRemoveStop, onReorderStops, onUpdateStopServices,
}: Props) {
  const { t } = useTranslation();
  const [title, setTitle] = useState<string | null>(initialTitle ?? null);
  const [date, setDate] = useState<Date | null>(initialDate ? parseISO(initialDate) : null);
  const [time, setTime] = useState<string | null>(initialTime ?? null);
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [scheduleSheetVisible, setScheduleSheetVisible] = useState(false);

  const { data: clients = [] } = useClients('all');
  const { data: base } = useBaseAddress();
  const { data: allSettings } = useAllSettings();
  const fg = useForegroundColor();
  const onContrast = useOnContrastColor();
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
        departureTime: time ?? '08:00',
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

  const perStopFeeCents = useMemo(() => {
    return initialStops.map((s) =>
      computeClientTravelFee({
        distanceKm: distanceKm('BASE', s.clientId),
        bracketKm,
        feePerBracket,
      })
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [initialStops, base, clients, bracketKm, feePerBracket]);

  const totalFeeCents = useMemo(
    () => perStopFeeCents.reduce((s, c) => s + c, 0),
    [perStopFeeCents]
  );

  const submitSchedule = async (scheduledDate: string, departureTime: string) => {
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
    onSchedule({
      title,
      scheduledDate,
      departureTime,
      stops: initialStops.map((s) => ({
        ...s,
        clientNameSnapshot: clientsById.get(s.clientId)?.displayName ?? null,
      })),
      totalDistanceKm,
      totalMinutes,
    });
  };

  const submitDraft = () => {
    if (initialStops.length === 0) return;
    if (!onSaveDraft) return;
    onSaveDraft({
      title,
      stops: initialStops.map((s) => ({
        ...s,
        clientNameSnapshot: clientsById.get(s.clientId)?.displayName ?? null,
      })),
      totalDistanceKm,
      totalMinutes,
    });
  };

  const onConfirmSchedule = (input: { scheduledDate: string; departureTime: string }) => {
    setScheduleSheetVisible(false);
    void submitSchedule(input.scheduledDate, input.departureTime);
  };

  const onDeletePress = async () => {
    if (!onDelete) return;
    const ok = await confirm({
      title: t('tours.delete_draft_confirm_title'),
      message: t('tours.delete_draft_confirm_message'),
      confirmLabel: t('common.delete'),
      cancelLabel: t('common.cancel'),
      destructive: true,
    });
    if (ok) onDelete();
  };

  const previewStops = useMemo<PreviewStop[]>(() => {
    return initialStops
      .map((s, i): PreviewStop | null => {
        const c = clientsById.get(s.clientId);
        if (c?.latitude == null || c?.longitude == null) return null;
        return {
          id: s.clientId,
          client: { ...c, latitude: c.latitude, longitude: c.longitude },
          arrivalTime: arrivals[i]?.arrivalTime,
        };
      })
      .filter((x): x is PreviewStop => x !== null);
  }, [initialStops, clientsById, arrivals]);

  const Header = (
    <View style={{ gap: 16, paddingTop: 16, paddingBottom: 8 }}>
      {tourStatus === 'draft' ? (
        <View className="gap-2">
          <Text className="text-sm font-medium">{t('tours.title_label')}</Text>
          <TextInput
            value={title ?? ''}
            onChangeText={(v) => setTitle(v.length > 0 ? v : null)}
            placeholder={t('tours.title_placeholder')}
            className="rounded-2xl px-4 py-3 bg-muted dark:bg-muted-dark"
            style={{ color: fg }}
            placeholderTextColor="#5C4E40"
          />
        </View>
      ) : null}

      {base && previewStops.length > 0 ? (
        <TourMapPreview base={{ lat: base.lat, lon: base.lon }} stops={previewStops} />
      ) : null}

      {tourStatus !== 'draft' ? (
        <>
          <View className="gap-2">
            <Text className="text-sm font-medium">{t('tours.scheduled_date')}</Text>
            <PressScale
              onPress={() => setShowDatePicker(true)}
              accessibilityLabel={t('tours.scheduled_date')}
            >
              <Surface variant="muted" className="rounded-2xl px-4 py-3">
                <Text>{date ? format(date, 'PPPP', { locale: fr }) : t('tours.title_placeholder')}</Text>
              </Surface>
            </PressScale>
            {showDatePicker ? (
              <DateTimePicker
                value={date ?? new Date()}
                mode="date"
                onChange={(_, d) => {
                  setShowDatePicker(Platform.OS === 'ios');
                  if (d) setDate(d);
                }}
              />
            ) : null}
          </View>

          <View className="gap-2">
            <Text className="text-sm font-medium">{t('tours.departure_time')}</Text>
            <PressScale
              onPress={() => setShowTimePicker(true)}
              accessibilityLabel={t('tours.departure_time')}
            >
              <Surface variant="muted" className="rounded-2xl px-4 py-3">
                <Text>{time ?? t('tours.title_placeholder')}</Text>
              </Surface>
            </PressScale>
            {showTimePicker ? (
              <DateTimePicker
                value={(() => {
                  const [h, m] = (time ?? '08:00').split(':').map(Number);
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
            ) : null}
          </View>
        </>
      ) : null}

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
          <Text className="font-semibold">{(totalFeeCents / 100).toFixed(0)} €</Text>
        </View>
      </Surface>

      <View className="flex-row items-center justify-between">
        <Text className="text-sm font-medium">{t('tours.stops_section')}</Text>
        <Button
          size="sm"
          variant="ghost"
          onPress={onAddClients}
          accessibilityLabel={t('tours.add_stops')}
        >
          <Plus size={14} color={fg} />
          <Text className="font-semibold text-sm">{t('tours.add_stops')}</Text>
        </Button>
      </View>
      <Text variant="muted" className="text-xs">{t('tours.reorder_hint')}</Text>

      {tourStatus === 'draft' && initialId && onDelete ? (
        <Button
          variant="danger"
          onPress={() => void onDeletePress()}
          accessibilityLabel={t('tours.delete_draft_cta')}
        >
          <Trash2 size={16} color={onContrast} />
          <Text variant="onPrimary" className="font-semibold">{t('tours.delete_draft_cta')}</Text>
        </Button>
      ) : null}
    </View>
  );

  const pickerStop = pickerClientId ? initialStops.find((s) => s.clientId === pickerClientId) : null;
  const pickerClient = pickerClientId ? clientsById.get(pickerClientId) : null;

  return (
    <>
    <View style={{ flex: 1 }}>
    <DraggableList
      data={initialStops}
      keyExtractor={(s) => s.clientId}
      onReorder={onReorderStops}
      ListHeaderComponent={Header}
      contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 16 }}
      renderItem={({ item, index, drag }) => {
        const client = clientsById.get(item.clientId);
        const arr = arrivals[index];
        const stopFee = perStopFeeCents[index] ?? 0;
        return (
          <Surface variant="muted" className="rounded-2xl px-3 py-3 mb-2">
            <View className="flex-row items-center gap-3">
              <PressScale onPressIn={drag} accessibilityLabel={t('tours.reorder_hint')}>
                <GripVertical size={20} color="#5C4E40" />
              </PressScale>
              <PressScale
                className="flex-1"
                onPress={() => setPickerClientId(item.clientId)}
                accessibilityLabel={client?.displayName ?? item.clientId}
              >
                <View className="flex-row items-center gap-2">
                  <View className="flex-1 gap-1">
                    <Text className="font-semibold">{client?.displayName ?? item.clientId}</Text>
                    {arr ? (
                      <Text variant="muted" className="text-xs">
                        {t('tours.stop_arrival')} {arr.arrivalTime} · {formatMinutes(arr.estimatedMinutes)} · {(stopFee / 100).toFixed(0)} €
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
              <PressScale
                onPress={() => onRemoveStop(item.clientId)}
                accessibilityLabel={t('tours.remove_stop')}
              >
                <Trash2 size={16} color="#B23832" />
              </PressScale>
            </View>
          </Surface>
        );
      }}
    />
    </View>
    <View className="px-4 pt-3 pb-6 border-t border-border dark:border-border-dark bg-background dark:bg-background-dark flex-row gap-2">
      {tourStatus === 'draft' && onSaveDraft ? (
        <Button
          variant="secondary"
          className="flex-1"
          onPress={submitDraft}
          disabled={initialStops.length === 0 || saving}
          accessibilityLabel={t('tours.save_as_draft')}
        >
          <Text className="font-semibold">{t('tours.save_as_draft')}</Text>
        </Button>
      ) : null}
      <Button
        className="flex-1"
        onPress={() => setScheduleSheetVisible(true)}
        disabled={initialStops.length === 0 || saving}
        accessibilityLabel={t('tours.schedule_cta')}
      >
        <Text variant="onPrimary" className="font-semibold">{t('tours.schedule_cta')}</Text>
      </Button>
    </View>
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
    <ScheduleTourSheet
      visible={scheduleSheetVisible}
      initialDate={date}
      initialTime={time}
      onClose={() => setScheduleSheetVisible(false)}
      onConfirm={onConfirmSchedule}
    />
    </>
  );
}
