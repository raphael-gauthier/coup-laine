import { useEffect, useMemo, useState } from 'react';
import { ScrollView, View, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { AlertCircle, Check, Inbox, X } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { Slider } from '@/ui/primitives/slider';
import { ScreenHeader } from '@/ui/components/screen-header';
import { EmptyState } from '@/ui/components/empty-state';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';
import { cn } from '@/lib/cn';
import { useClients, useWaitingCommunes } from '@/state/queries/clients';
import { useAllSettings, useBaseAddress } from '@/state/queries/settings';
import { useResolveDistanceMatrix } from '@/state/queries/distance-matrix';
import { useTourDraftStore } from '@/state/stores/tour-draft-store';
import { computeCommuneAnchor } from '@/domain/use-cases/compute-commune-anchor';
import { findWaitingClientsInRadius } from '@/domain/use-cases/find-waiting-clients-in-radius';
import { optimizeTourOrder } from '@/domain/use-cases/tour-order-optimizer';
import { useMutedForegroundColor, useOnContrastColor } from '@/ui/theme/colors';
import type { MatrixCoord } from '@/infra/services/ors-routing';

const MIN_RADIUS_KM = 1;
const MAX_RADIUS_KM = 50;
const DEFAULT_RADIUS_KM = 10;

export default function OptimizedConfigScreen() {
  const { t } = useTranslation();
  const router = useRouter();

  const setOrder = useTourDraftStore((s) => s.setOrder);
  const reset = useTourDraftStore((s) => s.reset);

  const { data: communes = [], isLoading: loadingCommunes } = useWaitingCommunes();
  const { data: allClients = [] } = useClients('all');
  const { data: waitingClients = [] } = useClients('waiting');
  const { data: base } = useBaseAddress();
  const { data: settings } = useAllSettings();
  const resolve = useResolveDistanceMatrix();

  const defaultRadius = settings?.proximity_radius_km != null
    ? parseInt(settings.proximity_radius_km, 10)
    : DEFAULT_RADIUS_KM;

  const [commune, setCommune] = useState<string | null>(null);
  const [radius, setRadius] = useState(defaultRadius);
  const [unchecked, setUnchecked] = useState<Set<string>>(new Set());
  const [proposing, setProposing] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const mutedFg = useMutedForegroundColor();
  const onContrast = useOnContrastColor();

  // Sync slider default once settings have loaded.
  useEffect(() => {
    if (settings?.proximity_radius_km != null) {
      setRadius(parseInt(settings.proximity_radius_km, 10));
    }
  }, [settings?.proximity_radius_km]);

  const anchor = useMemo(
    () => (commune ? computeCommuneAnchor(commune, allClients) : null),
    [commune, allClients],
  );

  const inRadius = useMemo(() => {
    if (!anchor) return [];
    return findWaitingClientsInRadius(anchor, waitingClients, radius);
  }, [anchor, waitingClients, radius]);

  // Reset selection when commune or radius changes (everything pre-checked).
  useEffect(() => {
    setUnchecked(new Set());
  }, [commune, radius]);

  const clientsById = useMemo(
    () => new Map(waitingClients.map((c) => [c.id, c])),
    [waitingClients],
  );

  const selectedCount = inRadius.length - unchecked.size;
  const allSelected = unchecked.size === 0;

  const toggleClient = (id: string) => {
    void haptics.selection();
    setUnchecked((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const toggleAll = () => {
    void haptics.selection();
    setUnchecked((prev) =>
      prev.size === 0 ? new Set(inRadius.map((c) => c.id)) : new Set(),
    );
  };

  const onContinue = async () => {
    if (!commune || !base) return;
    const selected = inRadius.filter((c) => !unchecked.has(c.id));
    if (selected.length === 0) {
      void haptics.error();
      setErrorMsg(t('tours.optimized_propose_empty'));
      return;
    }
    setProposing(true);
    setErrorMsg(null);
    void haptics.selection();
    try {
      const coords: MatrixCoord[] = [
        { id: 'BASE', lat: base.lat, lon: base.lon },
        ...selected.map((s) => {
          const c = clientsById.get(s.id)!;
          return { id: c.id, lat: c.latitude!, lon: c.longitude! };
        }),
      ];
      const result = await resolve.mutateAsync(coords);
      const distanceKm = (from: string, to: string) =>
        result.matrix.get(`${from}-${to}`)?.distanceKm ?? 0;
      const ordered = optimizeTourOrder({
        stopIds: selected.map((s) => s.id),
        distanceKm,
      });
      reset();
      setOrder(ordered);
      router.push('/(tabs)/tours/new/draft' as never);
    } catch (err) {
      void haptics.error();
      setErrorMsg(
        err instanceof Error ? err.message : t('tours.optimized_propose_failed'),
      );
    } finally {
      setProposing(false);
    }
  };

  if (loadingCommunes) {
    return (
      <Surface className="flex-1">
        <ScreenHeader title={t('tours.create_optimized')} />
        <View className="flex-1 items-center justify-center">
          <ActivityIndicator />
        </View>
      </Surface>
    );
  }

  if (communes.length === 0) {
    return (
      <Surface className="flex-1">
        <ScreenHeader title={t('tours.create_optimized')} />
        <EmptyState
          icon={<Inbox size={48} color={mutedFg} />}
          title={t('tours.optimized_empty_title')}
          message={t('tours.optimized_empty_body')}
        />
      </Surface>
    );
  }

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('tours.create_optimized')} />

      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 32, gap: 16 }}>
        {/* Commune section */}
        <View className="gap-2">
          <Text className="text-sm font-semibold uppercase tracking-widest text-muted-foreground dark:text-muted-dark-foreground">
            {t('tours.optimized_commune_title')}
          </Text>
          {communes.map((c) => {
            const selected = commune === c.city;
            return (
              <PressScale
                key={c.city}
                onPress={() => {
                  void haptics.selection();
                  setCommune(selected ? null : c.city);
                }}
                accessibilityLabel={c.city}
              >
                <Surface
                  variant={selected ? 'primary' : 'muted'}
                  className="flex-row items-center rounded-2xl px-4 py-3 gap-3"
                >
                  <View className="flex-1">
                    <Text
                      className={cn(
                        'font-semibold',
                        selected && 'text-primary-foreground dark:text-primary-dark-foreground'
                      )}
                    >
                      {c.city}
                    </Text>
                    <Text
                      className={cn(
                        'text-xs mt-0.5',
                        selected
                          ? 'text-primary-foreground dark:text-primary-dark-foreground opacity-80'
                          : 'text-muted-foreground dark:text-muted-dark-foreground'
                      )}
                    >
                      {t('tours.optimized_commune_option', { count: c.count })}
                    </Text>
                  </View>
                  {selected ? <Check size={20} color={onContrast} /> : null}
                </Surface>
              </PressScale>
            );
          })}
        </View>

        {/* Radius section */}
        {commune ? (
          <View className="gap-3">
            <Text className="text-sm font-semibold uppercase tracking-widest text-muted-foreground dark:text-muted-dark-foreground">
              {t('tours.optimized_radius_title')}
            </Text>
            <Surface variant="muted" className="rounded-2xl px-4 py-4 gap-2">
              <Text className="text-3xl font-bold">
                {t('tours.optimized_radius_value', { value: radius })}
              </Text>
              <Slider
                value={radius}
                onChange={setRadius}
                min={MIN_RADIUS_KM}
                max={MAX_RADIUS_KM}
                step={1}
                formatValue={(v) => t('tours.optimized_radius_value', { value: v })}
              />
            </Surface>
          </View>
        ) : null}

        {/* Clients in radius section */}
        {commune ? (
          <View className="gap-2">
            <View className="flex-row items-center justify-between">
              <Text className="text-sm font-semibold uppercase tracking-widest text-muted-foreground dark:text-muted-dark-foreground">
                {t('tours.optimized_clients_title')}
              </Text>
              {inRadius.length > 0 ? (
                <PressScale onPress={toggleAll} accessibilityLabel={allSelected ? t('tours.optimized_deselect_all') : t('tours.optimized_select_all')}>
                  <Text className="text-sm font-semibold text-primary dark:text-primary-dark">
                    {allSelected ? t('tours.optimized_deselect_all') : t('tours.optimized_select_all')}
                  </Text>
                </PressScale>
              ) : null}
            </View>
            {inRadius.length === 0 ? (
              <Surface variant="muted" className="rounded-2xl px-4 py-6 items-center">
                <Text variant="muted" className="text-sm text-center">
                  {t('tours.optimized_no_clients_in_radius')}
                </Text>
              </Surface>
            ) : (
              <>
                <Text variant="muted" className="text-xs">
                  {t('tours.optimized_clients_count', { count: inRadius.length, radius })}
                </Text>
                {inRadius.map((entry) => {
                  const client = clientsById.get(entry.id);
                  if (!client) return null;
                  const isPicked = !unchecked.has(entry.id);
                  return (
                    <PressScale
                      key={entry.id}
                      onPress={() => toggleClient(entry.id)}
                      accessibilityLabel={client.displayName}
                    >
                      <Surface
                        variant="muted"
                        className={cn(
                          'flex-row items-center rounded-2xl px-4 py-3 gap-3',
                          isPicked && 'border-2 border-primary dark:border-primary-dark',
                        )}
                      >
                        <View
                          className={cn(
                            'w-6 h-6 rounded-full items-center justify-center',
                            isPicked ? 'bg-primary dark:bg-primary-dark' : 'bg-background dark:bg-background-dark',
                          )}
                        >
                          {isPicked ? <Check size={14} color={onContrast} /> : null}
                        </View>
                        <View className="flex-1">
                          <Text className="font-semibold">{client.displayName}</Text>
                          {client.addressCity ? (
                            <Text variant="muted" className="text-sm mt-0.5">
                              {client.addressCity}
                            </Text>
                          ) : null}
                        </View>
                        <Text variant="muted" className="text-sm">
                          {t('tours.optimized_distance', { value: entry.distanceKm.toFixed(1).replace('.', ',') })}
                        </Text>
                      </Surface>
                    </PressScale>
                  );
                })}
              </>
            )}
          </View>
        ) : null}
      </ScrollView>

      {/* Footer */}
      <View className="px-4 pt-3 pb-6 border-t border-border dark:border-border-dark gap-2">
        {errorMsg ? (
          <Surface
            variant="danger"
            className="flex-row items-start gap-2 rounded-2xl px-3 py-2"
          >
            <AlertCircle size={16} color={onContrast} />
            <Text variant="onDanger" className="flex-1 text-sm">
              {errorMsg}
            </Text>
            <PressScale
              onPress={() => setErrorMsg(null)}
              className="p-0.5"
              accessibilityLabel={t('common.dismiss')}
            >
              <X size={16} color={onContrast} />
            </PressScale>
          </Surface>
        ) : null}
        <Button
          onPress={onContinue}
          disabled={!commune || selectedCount === 0 || proposing}
          loading={proposing}
        >
          {t('tours.optimized_continue', { count: selectedCount })}
        </Button>
      </View>
    </Surface>
  );
}
