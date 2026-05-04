import { useState } from 'react';
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
import { useBaseAddress } from '@/state/queries/settings';
import { useResolveDistanceMatrix } from '@/state/queries/distance-matrix';
import { useTourDraftStore } from '@/state/stores/tour-draft-store';
import { proposeOptimizedTour } from '@/domain/use-cases/propose-optimized-tour';
import type { MatrixCoord } from '@/infra/services/ors-routing';

const MIN_HOURS = 5;
const MAX_HOURS = 10;
const STEP_MIN = 30;

export default function OptimizedConfigScreen() {
  const { t } = useTranslation();
  const router = useRouter();

  const setOrder = useTourDraftStore((s) => s.setOrder);
  const reset = useTourDraftStore((s) => s.reset);
  const setOptimizedConfig = useTourDraftStore((s) => s.setOptimizedConfig);

  const { data: communes = [], isLoading: loadingCommunes } = useWaitingCommunes();
  const { data: waitingClients = [] } = useClients('waiting');
  const { data: base } = useBaseAddress();
  const resolve = useResolveDistanceMatrix();

  const [commune, setCommune] = useState<string | null>(null);
  const [targetMinutes, setTargetMinutes] = useState(8 * 60);
  const [proposing, setProposing] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const onPropose = async () => {
    if (!commune || !base) return;
    setProposing(true);
    setErrorMsg(null);
    void haptics.selection();
    try {
      const eligible = waitingClients.filter(
        (c) => c.latitude != null && c.longitude != null
      );
      if (eligible.length === 0) {
        void haptics.error();
        setErrorMsg(t('tours.optimized_propose_failed'));
        return;
      }
      const coords: MatrixCoord[] = [
        { id: 'BASE', lat: base.lat, lon: base.lon },
        ...eligible.map((c) => ({ id: c.id, lat: c.latitude!, lon: c.longitude! })),
      ];
      const result = await resolve.mutateAsync(coords);
      const distanceKm = (from: string, to: string) =>
        result.matrix.get(`${from}-${to}`)?.distanceKm ?? 0;
      const travelMinutesBetween = (from: string, to: string) =>
        result.matrix.get(`${from}-${to}`)?.durationMinutes ?? 0;

      const proposal = proposeOptimizedTour({
        communeName: commune,
        targetMinutes,
        waitingClients: eligible,
        distanceKm,
        travelMinutesBetween,
      });

      if (proposal.selectedClientIds.length === 0) {
        void haptics.error();
        setErrorMsg(t('tours.optimized_propose_empty'));
        return;
      }

      reset();
      setOptimizedConfig({ targetMinutes, commune });
      setOrder(proposal.selectedClientIds);
      router.push('/(tabs)/tours/new/draft' as never);
    } catch (err) {
      void haptics.error();
      setErrorMsg(
        err instanceof Error ? err.message : t('tours.optimized_propose_failed')
      );
    } finally {
      setProposing(false);
    }
  };

  const formatHours = (m: number) => `${(m / 60).toFixed(1).replace('.', ',')} h`;

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
          icon={<Inbox size={48} color="#5C4E40" />}
          title={t('tours.optimized_empty_title')}
          message={t('tours.optimized_empty_body')}
        />
      </Surface>
    );
  }

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('tours.create_optimized')} />

      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 16, gap: 16 }}>
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
                  {selected ? <Check size={20} color="#FFFFFF" /> : null}
                </Surface>
              </PressScale>
            );
          })}
        </View>

        {/* Duration section */}
        <View className="gap-3">
          <Text className="text-sm font-semibold uppercase tracking-widest text-muted-foreground dark:text-muted-dark-foreground">
            {t('tours.optimized_duration_title')}
          </Text>
          <Surface variant="muted" className="rounded-2xl px-4 py-4 gap-2">
            <Text className="text-3xl font-bold">{formatHours(targetMinutes)}</Text>
            <Slider
              value={targetMinutes}
              onChange={setTargetMinutes}
              min={MIN_HOURS * 60}
              max={MAX_HOURS * 60}
              step={STEP_MIN}
              formatValue={formatHours}
            />
          </Surface>
        </View>
      </ScrollView>

      {/* Footer */}
      <View className="px-4 pt-3 pb-6 border-t border-border dark:border-border-dark gap-2">
        {errorMsg ? (
          <Surface
            variant="danger"
            className="flex-row items-start gap-2 rounded-2xl px-3 py-2"
          >
            <AlertCircle size={16} color="#FFFFFF" />
            <Text variant="onDanger" className="flex-1 text-sm">
              {errorMsg}
            </Text>
            <PressScale onPress={() => setErrorMsg(null)} className="p-0.5">
              <X size={16} color="#FFFFFF" />
            </PressScale>
          </Surface>
        ) : null}
        <Button
          onPress={onPropose}
          disabled={!commune || proposing}
          loading={proposing}
        >
          {t('tours.optimized_propose')}
        </Button>
      </View>
    </Surface>
  );
}
