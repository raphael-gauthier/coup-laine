import { useMemo, useState } from 'react';
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
import { OffPlanServicePicker } from '@/ui/components/off-plan-service-picker';
import { confirm } from '@/ui/components/confirm-dialog';
import { useTour, useCompleteWithBilan } from '@/state/queries/tours';
import { useClients } from '@/state/queries/clients';
import { useAnimalCategories, useSpecies } from '@/state/queries/species';
import { haptics } from '@/ui/motion/haptics';
import { mutationErrorToast } from '@/ui/components/error-toast';
import type { TourStopService } from '@/domain/models/tour-stop-service';
import type { Service } from '@/domain/models/service';
import type { Payment } from '@/domain/models/payment';
import { useOnContrastColor } from '@/ui/theme/colors';
import { formatMinutes } from '@/lib/format-minutes';
import { cn } from '@/lib/cn';

function formatEur(cents: number): string {
  return `${(cents / 100).toFixed(0)} €`;
}

function formatDeltaEur(cents: number): string {
  if (cents === 0) return '0 €';
  const sign = cents > 0 ? '+' : '−';
  return `${sign}${(Math.abs(cents) / 100).toFixed(0)} €`;
}

interface KpiTileProps {
  label: string;
  value: string;
  valueClassName?: string;
}

function KpiTile({ label, value, valueClassName }: KpiTileProps) {
  return (
    <Surface variant="muted" className="flex-1 rounded-2xl p-3 gap-1">
      <Text variant="muted" className="text-xs">{label}</Text>
      <Text className={cn('text-xl font-bold', valueClassName)}>{value}</Text>
    </Surface>
  );
}

export default function CompleteTourScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const onContrast = useOnContrastColor();
  const { data, isError, refetch } = useTour(id);
  const { data: clients = [] } = useClients('all');
  const { data: categories = [] } = useAnimalCategories();
  const { data: speciesList = [] } = useSpecies();
  const complete = useCompleteWithBilan();

  const clientsById = useMemo(() => new globalThis.Map(clients.map((c) => [c.id, c])), [clients]);
  const categoriesById = useMemo(() => new globalThis.Map(categories.map((c) => [c.id, c])), [categories]);
  const speciesById = useMemo(() => new globalThis.Map(speciesList.map((s) => [s.id, s])), [speciesList]);

  const [perStopActuals, setPerStopActuals] = useState<Record<string, TourStopService[]>>({});
  const [perStopNotes, setPerStopNotes] = useState<Record<string, string>>({});
  const [perStopPayments, setPerStopPayments] = useState<Record<string, Payment>>({});
  const [perStopPaymentErrors, setPerStopPaymentErrors] = useState<Record<string, string | null>>({});
  const [offPlanForStopId, setOffPlanForStopId] = useState<string | null>(null);

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  if (!data) return <Surface className="flex-1" />;

  const { tour, stops } = data;

  const getActuals = (stopId: string, defaultPrests: TourStopService[]) =>
    perStopActuals[stopId] ?? defaultPrests;

  const setActuals = (stopId: string, prests: TourStopService[]) =>
    setPerStopActuals((prev) => ({ ...prev, [stopId]: prests }));

  const getNote = (stopId: string) => perStopNotes[stopId] ?? '';

  const setNote = (stopId: string, note: string) =>
    setPerStopNotes((prev) => ({ ...prev, [stopId]: note }));

  const getPayment = (stopId: string, defaultPayment: Payment) =>
    perStopPayments[stopId] ?? defaultPayment;

  const setPayment = (stopId: string, p: Payment) =>
    setPerStopPayments((prev) => ({ ...prev, [stopId]: p }));

  const buildServiceFromCatalog = (svc: Service): TourStopService => {
    const category = svc.categoryId ? categoriesById.get(svc.categoryId) : null;
    const sp = category ? speciesById.get(category.speciesId) : null;
    return {
      serviceId: svc.id,
      qty: 1,
      nameSnapshot: svc.label,
      priceCentsSnapshot: svc.priceCents ?? 0,
      minutesSnapshot: svc.minutes,
      categoryIdSnapshot: svc.categoryId,
      categoryNameSnapshot: category?.label ?? null,
      speciesNameSnapshot: sp?.label ?? null,
    };
  };

  const onPickOffPlan = (svc: Service) => {
    if (!offPlanForStopId) return;
    const stop = stops.find((s) => s.id === offPlanForStopId);
    if (!stop) return;
    const current = getActuals(offPlanForStopId, stop.plannedServices);
    setActuals(offPlanForStopId, [...current, buildServiceFromCatalog(svc)]);
    setOffPlanForStopId(null);
  };

  // Live totals from current draft.
  const feeCents = tour.totalTravelFeeCents ?? 0;
  let actualMinutes = 0;
  let actualRevenueCents = 0;
  let plannedRevenueCents = 0;
  let stopsValidated = 0;

  for (const stop of stops) {
    const actuals = getActuals(stop.id, stop.plannedServices);
    let stopHasAny = false;
    for (const a of actuals) {
      if (a.qty <= 0) continue;
      stopHasAny = true;
      actualMinutes += a.qty * a.minutesSnapshot;
      actualRevenueCents += a.qty * a.priceCentsSnapshot;
    }
    if (stopHasAny) stopsValidated += 1;
    for (const p of stop.plannedServices) {
      plannedRevenueCents += p.qty * p.priceCentsSnapshot;
    }
  }

  const totalActualRevenue = actualRevenueCents + feeCents;
  const deltaCents = actualRevenueCents - plannedRevenueCents;

  const onConfirm = async () => {
    // Validate: stops with services AND isPaid=true must have a methodId
    const errors: Record<string, string | null> = {};
    let hasError = false;
    for (const stop of stops) {
      const actuals = getActuals(stop.id, stop.plannedServices);
      const stopHasAny = actuals.some((a) => a.qty > 0);
      if (!stopHasAny) continue;
      const p = getPayment(stop.id, stop.payment);
      if (p.isPaid && !p.methodId) {
        errors[stop.id] = t('payments.method_required');
        hasError = true;
      }
    }
    if (hasError) {
      setPerStopPaymentErrors(errors);
      void haptics.error();
      return;
    }
    setPerStopPaymentErrors({});

    const ok = await confirm({
      title: t('tours.bilan_confirm_title'),
      message: t('tours.bilan_confirm_body'),
      confirmLabel: t('tours.complete_confirm_yes'),
      cancelLabel: t('common.cancel'),
      destructive: true,
    });
    if (!ok) return;

    const actualsMap = new Map<string, TourStopService[]>();
    const notesMap = new Map<string, string | null>();
    const paymentsMap = new Map<string, Payment>();
    for (const stop of stops) {
      actualsMap.set(stop.id, getActuals(stop.id, stop.plannedServices));
      const trimmed = getNote(stop.id).trim();
      notesMap.set(stop.id, trimmed.length === 0 ? null : trimmed);
      paymentsMap.set(stop.id, getPayment(stop.id, stop.payment));
    }
    complete.mutate(
      {
        tourId: tour.id,
        perStopActuals: actualsMap,
        perStopNotes: notesMap,
        perStopPayments: paymentsMap,
        completedAt: new Date().toISOString(),
      },
      {
        onSuccess: () => {
          void haptics.success();
          router.replace(`/(tabs)/tours/${tour.id}` as never);
        },
        onError: (err) => {
          mutationErrorToast(t('tours.save_failed_title'), err);
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

        <View className="gap-2">
          <View className="flex-row gap-2">
            <KpiTile
              label={t('tours.bilan_kpi_stops_validated')}
              value={`${stopsValidated}/${stops.length}`}
            />
            <KpiTile
              label={t('tours.bilan_kpi_actual_revenue')}
              value={formatEur(totalActualRevenue)}
            />
          </View>
          <View className="flex-row gap-2">
            <KpiTile
              label={t('tours.bilan_kpi_actual_duration')}
              value={formatMinutes(actualMinutes)}
            />
            <KpiTile
              label={t('tours.bilan_kpi_delta')}
              value={formatDeltaEur(deltaCents)}
              valueClassName={
                deltaCents === 0
                  ? undefined
                  : deltaCents > 0
                    ? 'text-primary dark:text-primary-dark'
                    : 'text-danger dark:text-danger-dark'
              }
            />
          </View>
        </View>

        {stops.map((stop) => (
          <StopCompletionEditor
            key={stop.id}
            stop={stop}
            client={clientsById.get(stop.clientId)}
            actuals={getActuals(stop.id, stop.plannedServices)}
            note={getNote(stop.id)}
            onChangeActuals={(next) => setActuals(stop.id, next)}
            onChangeNote={(next) => setNote(stop.id, next)}
            onAddOffPlan={() => setOffPlanForStopId(stop.id)}
            payment={getPayment(stop.id, stop.payment)}
            paymentError={perStopPaymentErrors[stop.id] ?? null}
            onChangePayment={(next) => setPayment(stop.id, next)}
          />
        ))}

        <Button
          onPress={onConfirm}
          loading={complete.isPending}
          accessibilityLabel={t('tours.complete_confirm_yes')}
        >
          <CircleCheck size={18} color={onContrast} />
          <Text variant="onPrimary" className="font-semibold">{t('tours.complete_confirm_yes')}</Text>
        </Button>
      </ScrollView>

      <OffPlanServicePicker
        visible={offPlanForStopId !== null}
        excludedServiceIds={
          offPlanForStopId
            ? getActuals(
                offPlanForStopId,
                stops.find((s) => s.id === offPlanForStopId)?.plannedServices ?? []
              ).map((a) => a.serviceId)
            : []
        }
        onPick={onPickOffPlan}
        onClose={() => setOffPlanForStopId(null)}
      />
    </Surface>
  );
}
