import { useEffect, useMemo, useState } from 'react';
import { ActivityIndicator } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { ErrorState } from '@/ui/components/error-state';
import { useTourDraftStore } from '@/state/stores/tour-draft-store';
import { useClients } from '@/state/queries/clients';
import { useBaseAddress } from '@/state/queries/settings';
import { useResolveDistanceMatrix } from '@/state/queries/distance-matrix';
import { useUpsertTour } from '@/state/queries/tours';
import { optimizeTourOrder } from '@/domain/use-cases/tour-order-optimizer';
import { TourDraftEditor } from '@/ui/components/tour-draft-editor';
import { errorToast } from '@/ui/components/error-toast';
import { haptics } from '@/ui/motion/haptics';

export default function OptimizedTourScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const picked = useTourDraftStore((s) => s.pickedClientIds);
  const setOrder = useTourDraftStore((s) => s.setOrder);
  const reset = useTourDraftStore((s) => s.reset);
  const toggle = useTourDraftStore((s) => s.toggle);
  const { data: clients = [] } = useClients('all');
  const { data: base } = useBaseAddress();
  const resolve = useResolveDistanceMatrix();
  const upsert = useUpsertTour();
  const [isEstimate, setIsEstimate] = useState(false);
  const [optimizedIds, setOptimizedIds] = useState<string[] | null>(null);
  // Signature of the picked set we last optimised for. When `picked` changes
  // (user adds/removes a client from the optimised tour), we re-run.
  const [lastOptimisedSignature, setLastOptimisedSignature] = useState<string>('');

  const clientsById = useMemo(() => new globalThis.Map(clients.map((c) => [c.id, c])), [clients]);

  const optimizedConfig = useTourDraftStore((s) => s.optimizedConfig);

  useEffect(() => {
    // If no config set yet, go to config screen first
    if (!optimizedConfig) {
      router.push('/(tabs)/tours/new/optimized-config' as never);
      return;
    }
    if (picked.length === 0) {
      router.push('/(tabs)/tours/new/pick-clients' as never);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (picked.length === 0 || !base) return;

    // Build a stable signature from the *set* of picked ids (sorted).
    // Order changes from drag-reorder don't trigger a re-fetch.
    const signature = [...picked].sort().join('|');
    if (signature === lastOptimisedSignature) return;

    const validPicked = picked.filter((id) => {
      const c = clientsById.get(id);
      return c?.latitude != null && c?.longitude != null;
    });
    if (validPicked.length === 0) return;

    const coords = [
      { id: 'BASE', lat: base.lat, lon: base.lon },
      ...validPicked.map((id) => {
        const c = clientsById.get(id)!;
        return { id, lat: c.latitude!, lon: c.longitude! };
      }),
    ];

    resolve.mutate(coords, {
      onSuccess: (result) => {
        setIsEstimate(result.source === 'haversine');
        const ordered = optimizeTourOrder({
          stopIds: validPicked,
          distanceKm: (from, to) => result.matrix.get(`${from}-${to}`)?.distanceKm ?? 0,
        });
        setOptimizedIds(ordered);
        setOrder(ordered);
        setLastOptimisedSignature(signature);
      },
      onError: (err) => {
        errorToast('Calcul impossible', err instanceof Error ? err.message : undefined);
      },
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [picked, base, clientsById]);

  if (resolve.isPending) {
    return (
      <Surface className="flex-1 items-center justify-center gap-4">
        <Stack.Screen options={{ title: t('tours.create_optimized') }} />
        <ActivityIndicator size="large" />
        <Text variant="muted">{t('tours.optimizing')}</Text>
      </Surface>
    );
  }

  if (resolve.isError) {
    return <ErrorState onRetry={() => resolve.reset()} />;
  }

  if (!optimizedIds) return <Surface className="flex-1" />;

  const stops = optimizedIds.map((id) => ({ clientId: id, plannedPrestations: [], notes: null }));

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ title: t('tours.create_optimized') }} />
      {isEstimate ? (
        <Surface variant="muted" className="mx-4 mt-3 rounded-2xl px-4 py-3">
          <Text variant="muted" className="text-sm">{t('tours.ors_unavailable')}</Text>
        </Surface>
      ) : null}
      <TourDraftEditor
        initialStops={stops}
        saving={upsert.isPending}
        onAddClients={() => router.push('/(tabs)/tours/new/pick-clients' as never)}
        onRemoveStop={toggle}
        onReorderStops={(next) => setOrder(next.map((s) => s.clientId))}
        onSubmit={(input) => {
          if (!base) return;
          upsert.mutate(
            {
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
                reset();
                router.replace('/(tabs)/tours' as never);
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
