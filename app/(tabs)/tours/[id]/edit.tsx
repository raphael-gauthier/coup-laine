import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { TourDraftEditor } from '@/ui/components/tour-draft-editor';
import { ErrorState } from '@/ui/components/error-state';
import { useTour, useUpsertTour } from '@/state/queries/tours';
import { useBaseAddress } from '@/state/queries/settings';
import { errorToast } from '@/ui/components/error-toast';
import { haptics } from '@/ui/motion/haptics';
import { useTourDraftStore } from '@/state/stores/tour-draft-store';

export default function EditTourScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const { data, isError, refetch } = useTour(id);
  const upsert = useUpsertTour();
  const { data: base } = useBaseAddress();
  const setOrder = useTourDraftStore((s) => s.setOrder);
  const picked = useTourDraftStore((s) => s.pickedClientIds);
  const toggle = useTourDraftStore((s) => s.toggle);

  // Hydrate draft store with this tour's stops on first load.
  useEffect(() => {
    if (data) {
      setOrder(data.stops.map((s) => s.clientId));
    }
    return () => {
      useTourDraftStore.getState().reset();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data?.tour.id]);

  const stops = useMemo(
    () =>
      picked.map((cid) => {
        const original = data?.stops.find((s) => s.clientId === cid);
        return {
          clientId: cid,
          plannedPrestations: original?.plannedPrestations ?? [],
          notes: original?.notes ?? null,
        };
      }),
    [picked, data]
  );

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  if (!data) return <Surface className="flex-1" />;

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('tours.edit_title')} />
      <TourDraftEditor
        initialId={data.tour.id}
        initialDate={data.tour.scheduledDate}
        initialTime={data.tour.departureTime}
        initialStops={stops}
        saving={upsert.isPending}
        onAddClients={() => router.push('/(tabs)/tours/new/pick-clients' as never)}
        onRemoveStop={toggle}
        onReorderStops={(next) => setOrder(next.map((s) => s.clientId))}
        onSubmit={(input) => {
          if (!base) {
            errorToast('Base manquante', 'Configure ton adresse de domicile.');
            return;
          }
          upsert.mutate(
            {
              id: data.tour.id,
              ...input,
              baseLat: base.lat,
              baseLng: base.lon,
              stops: input.stops.map((s) => ({
                clientId: s.clientId,
                clientNameSnapshot: s.clientNameSnapshot ?? null,
                plannedPrestations: s.plannedPrestations,
                arrivalMinutes: null,
                estimatedMinutes: null,
                notes: s.notes,
              })),
            },
            {
              onSuccess: () => {
                void haptics.success();
                router.back();
              },
              onError: (err) => {
                errorToast(t('tours.save_failed_title'), err instanceof Error ? err.message : undefined);
              },
            }
          );
        }}
      />
    </Surface>
  );
}
