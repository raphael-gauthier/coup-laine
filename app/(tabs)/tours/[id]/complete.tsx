import { useState } from 'react';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { CircleCheck } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ErrorState } from '@/ui/components/error-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { StopCompletionEditor } from '@/ui/components/stop-completion-editor';
import { useTour, useCompleteWithBilan } from '@/state/queries/tours';
import { useClients } from '@/state/queries/clients';
import { haptics } from '@/ui/motion/haptics';
import { errorToast } from '@/ui/components/error-toast';
import type { TourStopService } from '@/domain/models/tour-stop-service';
import { useOnContrastColor } from '@/ui/theme/colors';

export default function CompleteTourScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const onContrast = useOnContrastColor();
  const { data, isError, refetch } = useTour(id);
  const { data: clients = [] } = useClients('all');
  const complete = useCompleteWithBilan();

  const clientsById = new globalThis.Map(clients.map((c) => [c.id, c]));

  const [perStopActuals, setPerStopActuals] = useState<Record<string, TourStopService[]>>({});

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  if (!data) return <Surface className="flex-1" />;

  const { tour, stops } = data;

  const getActuals = (stopId: string, defaultPrests: TourStopService[]) => {
    return perStopActuals[stopId] ?? defaultPrests;
  };

  const setActuals = (stopId: string, prests: TourStopService[]) => {
    setPerStopActuals((prev) => ({ ...prev, [stopId]: prests }));
  };

  const onConfirm = () => {
    const map = new Map<string, TourStopService[]>();
    for (const stop of stops) {
      map.set(stop.id, getActuals(stop.id, stop.plannedServices));
    }
    complete.mutate(
      { tourId: tour.id, perStopActuals: map, completedAt: new Date().toISOString() },
      {
        onSuccess: () => {
          void haptics.success();
          router.replace(`/(tabs)/tours/${tour.id}` as never);
        },
        onError: (err) => {
          errorToast(t('tours.save_failed_title'), err instanceof Error ? err.message : undefined);
        },
      }
    );
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('tours.complete_title')} />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 32, gap: 16 }}>
        <Text className="text-2xl font-bold">
          {format(parseISO(`${tour.scheduledDate}T${tour.departureTime}:00`), 'PPP', { locale: fr })}
        </Text>
        <Text variant="muted">{t('tours.bilan_intro')}</Text>

        {stops.map((stop) => (
          <StopCompletionEditor
            key={stop.id}
            stop={stop}
            client={clientsById.get(stop.clientId)}
            actuals={getActuals(stop.id, stop.plannedServices)}
            onChangeActuals={(next) => setActuals(stop.id, next)}
          />
        ))}

        <Button onPress={onConfirm} loading={complete.isPending}>
          <CircleCheck size={18} color={onContrast} />
          <Text variant="onPrimary" className="font-semibold">{t('tours.complete_confirm_yes')}</Text>
        </Button>
      </ScrollView>
    </Surface>
  );
}
