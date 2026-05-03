import { useState, useMemo } from 'react';
import { View, Platform } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { GripVertical, Trash2, Plus } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { DraggableList } from '@/ui/components/draggable-list';
import { useClients } from '@/state/queries/clients';
import { haversineDistanceKm } from '@/lib/haversine-distance';
import { estimateTourArrivals } from '@/domain/use-cases/estimate-tour-arrivals';
import { splitTravelCost } from '@/domain/use-cases/cost-split-calculator';
import { useAnimalCategories } from '@/state/queries/species';
import { useBaseAddress } from '@/state/queries/settings';
import type { TourStatus } from '@/domain/models/tour';

export interface DraftStop {
  clientId: string;
  prestations: { prestationId: string; animalCounts: { categoryId: string; count: number }[] }[];
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
  }) => void;
  onAddClients: () => void;
  onRemoveStop: (clientId: string) => void;
  onReorderStops: (next: DraftStop[]) => void;
}

const PRICE_PER_BRACKET = 8;
const BRACKET_KM = 10;

export function TourDraftEditor({
  initialStops, initialDate, initialTime,
  saving, onSubmit, onAddClients, onRemoveStop, onReorderStops,
}: Props) {
  const { t } = useTranslation();
  const today = new Date();
  const [date, setDate] = useState<Date>(initialDate ? parseISO(initialDate) : today);
  const [time, setTime] = useState(initialTime ?? '08:00');
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);

  const { data: clients = [] } = useClients('all');
  const { data: categories = [] } = useAnimalCategories();
  const { data: base } = useBaseAddress();

  const clientsById = useMemo(() => new globalThis.Map(clients.map((c) => [c.id, c])), [clients]);
  const categoryMinutes = useMemo(
    () => new globalThis.Map(categories.map((c) => [c.id, c.averageMinutesPerUnit])),
    [categories]
  );

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
          animalCounts: s.prestations.flatMap((p) => p.animalCounts),
        })),
        travelMinutesBetween: minutesBetween,
        categoryMinutes,
      }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [initialStops, time, base, clients, categories]
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

  const split = useMemo(
    () =>
      splitTravelCost({
        totalDistanceKm,
        stopCount: initialStops.length,
        pricePerBracket: PRICE_PER_BRACKET,
        bracketSizeKm: BRACKET_KM,
      }),
    [totalDistanceKm, initialStops.length]
  );

  const submit = (status: TourStatus) => {
    if (initialStops.length === 0) return;
    onSubmit({
      scheduledDate: format(date, 'yyyy-MM-dd'),
      departureTime: time,
      status,
      stops: initialStops,
      totalDistanceKm,
      totalMinutes,
    });
  };

  const Header = (
    <View style={{ gap: 16, paddingTop: 16, paddingBottom: 8 }}>
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
          <Text className="font-semibold">
            {Math.floor(totalMinutes / 60)}h {String(totalMinutes % 60).padStart(2, '0')}
          </Text>
        </View>
        <View className="flex-row justify-between mt-1">
          <Text variant="muted">{t('tours.total_cost')}</Text>
          <Text className="font-semibold">{split.totalEuros} €</Text>
        </View>
      </Surface>

      <View className="flex-row items-center justify-between">
        <Text className="text-sm font-medium">{t('tours.stops_section')}</Text>
        <Button size="sm" variant="ghost" onPress={onAddClients}>
          <Plus size={14} />
          <Text className="font-semibold text-sm">{t('tours.add_stops')}</Text>
        </Button>
      </View>
      <Text variant="muted" className="text-xs">{t('tours.reorder_hint')}</Text>
    </View>
  );

  const Footer = (
    <View style={{ gap: 8, paddingTop: 16, paddingBottom: 32 }}>
      <Button
        onPress={() => submit('draft')}
        loading={saving}
        disabled={initialStops.length === 0 || saving}
        variant="secondary"
      >
        {t('tours.save_draft')}
      </Button>
      <Button
        onPress={() => submit('planned')}
        loading={saving}
        disabled={initialStops.length === 0 || saving}
      >
        {t('tours.save_planned')}
      </Button>
    </View>
  );

  return (
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
          <Surface variant="muted" className="flex-row items-center rounded-2xl px-3 py-3 gap-3 mb-2">
            <PressScale onPressIn={drag}>
              <GripVertical size={20} color="#5C4E40" />
            </PressScale>
            <View className="flex-1">
              <Text className="font-semibold">{client?.displayName ?? item.clientId}</Text>
              {arr ? (
                <Text variant="muted" className="text-xs mt-0.5">
                  {t('tours.stop_arrival')} {arr.arrivalTime} · {arr.estimatedMinutes} min · {share} €
                </Text>
              ) : null}
            </View>
            <PressScale onPress={() => onRemoveStop(item.clientId)}>
              <Trash2 size={16} color="#B23832" />
            </PressScale>
          </Surface>
        );
      }}
    />
  );
}
