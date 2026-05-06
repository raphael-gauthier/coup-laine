import { useEffect, useMemo } from 'react';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { TourDraftEditor } from '@/ui/components/tour-draft-editor';
import { useTourDraftStore } from '@/state/stores/tour-draft-store';
import { useUpsertTour } from '@/state/queries/tours';
import { useBaseAddress } from '@/state/queries/settings';
import { errorToast, mutationErrorToast } from '@/ui/components/error-toast';
import { haptics } from '@/ui/motion/haptics';

export default function NewTourDraftScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const picked = useTourDraftStore((s) => s.pickedClientIds);
  const servicesByClient = useTourDraftStore((s) => s.servicesByClient);
  const setOrder = useTourDraftStore((s) => s.setOrder);
  const reset = useTourDraftStore((s) => s.reset);
  const toggle = useTourDraftStore((s) => s.toggle);
  const setStopServices = useTourDraftStore((s) => s.setStopServices);
  const upsert = useUpsertTour();
  const { data: base } = useBaseAddress();

  const stops = useMemo(
    () => picked.map((id) => ({
      clientId: id,
      plannedServices: servicesByClient[id] ?? [],
      notes: null,
    })),
    [picked, servicesByClient]
  );

  useEffect(() => {
    if (picked.length === 0) {
      router.push('/(tabs)/tours/new/pick-clients' as never);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('tours.new_title')} />
      <TourDraftEditor
        initialStops={stops}
        saving={upsert.isPending}
        onAddClients={() => router.push('/(tabs)/tours/new/pick-clients' as never)}
        onRemoveStop={toggle}
        onReorderStops={(next) => setOrder(next.map((s) => s.clientId))}
        onUpdateStopServices={setStopServices}
        onSubmit={(input) => {
          if (!base) {
            errorToast(t('tours.errors.base_missing_title'), t('tours.errors.base_missing_message'));
            return;
          }
          upsert.mutate(
            {
              ...input,
              baseLat: base.lat,
              baseLng: base.lon,
              stops: input.stops.map((s) => ({
                clientId: s.clientId,
                clientNameSnapshot: s.clientNameSnapshot ?? null,
                plannedServices: s.plannedServices,
                arrivalMinutes: null,
                estimatedMinutes: null,
                notes: s.notes,
              })),
            },
            {
              onSuccess: () => {
                void haptics.success();
                reset();
                router.replace('/(tabs)/tours' as never);
              },
              onError: (err) => {
                mutationErrorToast(t('tours.save_failed_title'), err);
              },
            }
          );
        }}
      />
    </Surface>
  );
}
