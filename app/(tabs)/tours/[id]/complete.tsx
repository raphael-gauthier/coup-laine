import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { CircleCheck } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ErrorState } from '@/ui/components/error-state';
import { confirm } from '@/ui/components/confirm-dialog';
import { useTour, useCompleteTour } from '@/state/queries/tours';
import { useClients } from '@/state/queries/clients';
import { haptics } from '@/ui/motion/haptics';

export default function CompleteTourScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const { data, isError, refetch } = useTour(id);
  const { data: clients = [] } = useClients('all');
  const complete = useCompleteTour();

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  if (!data) return <Surface className="flex-1" />;

  const { tour, stops } = data;
  const clientsById = new globalThis.Map(clients.map((c) => [c.id, c]));

  const onConfirm = async () => {
    const ok = await confirm({
      title: t('tours.complete_confirm_title'),
      message: t('tours.complete_confirm_message'),
      confirmLabel: t('tours.complete_confirm_yes'),
      cancelLabel: t('common.cancel'),
    });
    if (!ok) return;
    complete.mutate(
      { tourId: tour.id, completedAt: new Date().toISOString() },
      {
        onSuccess: () => {
          void haptics.success();
          router.replace(`/(tabs)/tours/${tour.id}` as never);
        },
      }
    );
  };

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ title: t('tours.complete_title') }} />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 32, gap: 16 }}>
        <Text className="text-2xl font-bold">
          {format(parseISO(`${tour.scheduledDate}T${tour.departureTime}:00`), 'PPP', { locale: fr })}
        </Text>
        <Text variant="muted">{t('tours.complete_confirm_message')}</Text>

        <View className="gap-2">
          {stops.map((s) => (
            <Surface key={s.id} variant="muted" className="rounded-2xl px-4 py-3">
              <Text className="font-semibold">{clientsById.get(s.clientId)?.displayName ?? s.clientId}</Text>
            </Surface>
          ))}
        </View>

        <Button onPress={onConfirm} loading={complete.isPending}>
          <CircleCheck size={18} color="white" />
          <Text variant="onPrimary" className="font-semibold">{t('tours.complete_confirm_yes')}</Text>
        </Button>
      </ScrollView>
    </Surface>
  );
}
