import { useEffect, useMemo, useState } from 'react';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { TourDraftEditor } from '@/ui/components/tour-draft-editor';
import { useTourDraftStore } from '@/state/stores/tour-draft-store';
import {
  useSaveDraft,
  useScheduleTour,
  useDeleteTour,
  useTour,
} from '@/state/queries/tours';
import { useBaseAddress } from '@/state/queries/settings';
import { errorToast, mutationErrorToast } from '@/ui/components/error-toast';
import { haptics } from '@/ui/motion/haptics';

export default function NewTourDraftScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id?: string }>();

  const picked = useTourDraftStore((s) => s.pickedClientIds);
  const servicesByClient = useTourDraftStore((s) => s.servicesByClient);
  const setOrder = useTourDraftStore((s) => s.setOrder);
  const reset = useTourDraftStore((s) => s.reset);
  const toggle = useTourDraftStore((s) => s.toggle);
  const setStopServices = useTourDraftStore((s) => s.setStopServices);
  const hydrateServices = useTourDraftStore((s) => s.hydrateServices);

  const { data: existing } = useTour(id);
  const saveDraft = useSaveDraft();
  const scheduleTour = useScheduleTour();
  const deleteTour = useDeleteTour();
  const { data: base } = useBaseAddress();

  const [hydrated, setHydrated] = useState(false);

  // Load existing draft into the store when arriving with ?id=...
  useEffect(() => {
    if (!id) {
      // New flow: if store empty, redirect to pick-clients
      if (picked.length === 0) {
        router.push('/tour-new/pick-clients' as never);
      }
      setHydrated(true);
      return;
    }
    if (existing && !hydrated) {
      reset();
      setOrder(existing.stops.map((s) => s.clientId));
      hydrateServices(
        existing.stops.map((s) => ({ clientId: s.clientId, services: s.plannedServices })),
      );
      setHydrated(true);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, existing?.tour.id]);

  const stops = useMemo(
    () => picked.map((cid) => ({
      clientId: cid,
      plannedServices: servicesByClient[cid] ?? [],
      notes: null,
    })),
    [picked, servicesByClient]
  );

  const tourStatus = existing?.tour.status ?? 'draft';
  const saving = saveDraft.isPending || scheduleTour.isPending;

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('tours.new_title')} />
      <TourDraftEditor
        initialId={id}
        initialDate={existing?.tour.scheduledDate ?? null}
        initialTime={existing?.tour.departureTime ?? null}
        initialTitle={existing?.tour.title ?? null}
        initialStops={stops}
        tourStatus={tourStatus}
        saving={saving}
        onAddClients={() => router.push('/tour-new/pick-clients' as never)}
        onRemoveStop={toggle}
        onReorderStops={(next) => setOrder(next.map((s) => s.clientId))}
        onUpdateStopServices={setStopServices}
        onSaveDraft={(input) => {
          if (!base) {
            errorToast(t('tours.errors.base_missing_title'), t('tours.errors.base_missing_message'));
            return;
          }
          saveDraft.mutate(
            {
              id,
              title: input.title,
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
              totalDistanceKm: input.totalDistanceKm,
              totalMinutes: input.totalMinutes,
            },
            {
              onSuccess: () => {
                void haptics.success();
                reset();
                router.replace('/(tabs)/tours?filter=draft' as never);
              },
              onError: (err) => {
                mutationErrorToast(t('tours.save_failed_title'), err);
              },
            }
          );
        }}
        onSchedule={(input) => {
          if (!base) {
            errorToast(t('tours.errors.base_missing_title'), t('tours.errors.base_missing_message'));
            return;
          }
          scheduleTour.mutate(
            {
              id,
              title: input.title,
              scheduledDate: input.scheduledDate,
              departureTime: input.departureTime,
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
              totalDistanceKm: input.totalDistanceKm,
              totalMinutes: input.totalMinutes,
            },
            {
              onSuccess: () => {
                void haptics.success();
                reset();
                router.replace('/(tabs)/tours?filter=planned' as never);
              },
              onError: (err) => {
                mutationErrorToast(t('tours.save_failed_title'), err);
              },
            }
          );
        }}
        onDelete={id ? () => {
          deleteTour.mutate(id, {
            onSuccess: () => {
              void haptics.success();
              reset();
              router.replace('/(tabs)/tours?filter=draft' as never);
            },
            onError: (err) => {
              mutationErrorToast(t('tours.delete_failed_title'), err);
            },
          });
        } : undefined}
      />
    </Surface>
  );
}
