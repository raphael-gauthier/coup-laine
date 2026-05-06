import { useMemo, useState } from 'react';
import { Modal, TouchableOpacity, View, ScrollView } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import {
  Ban,
  ChevronRight,
  MoreVertical,
  Pencil,
  Search,
  Trash2,
} from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ErrorState } from '@/ui/components/error-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { confirm, ConfirmTypedDialog } from '@/ui/components/confirm-dialog';
import { ClientKpiRow } from '@/ui/components/client-kpi-row';
import { ClientStatusBadge } from '@/ui/components/client-status-badge';
import { ClientContactCard } from '@/ui/components/client-contact-card';
import { PlannedTourCard } from '@/ui/components/planned-tour-card';
import { ClientAnimalsSection } from '@/ui/components/client-animals-section';
import { ClientStatusActionsCard } from '@/ui/components/client-status-actions-card';
import { LastInterventionsList } from '@/ui/components/last-interventions-list';
import { ClientOutstandingCard } from '@/ui/components/client-outstanding-card';
import { StopPaymentSheet } from '@/ui/components/stop-payment-sheet';
import { ManualEntryPaymentSheet } from '@/ui/components/manual-entry-payment-sheet';
import { PressScale } from '@/ui/motion/press-scale';
import {
  useClient,
  useClientStatusMap,
  useAnonymizeClient,
  useToggleBanned,
} from '@/state/queries/clients';
import { useNextPlannedTourForClient, useTours } from '@/state/queries/tours';
import { useManualHistoryByClient } from '@/state/queries/history';
import { useProximityStore } from '@/state/stores/proximity-store';
import { haptics } from '@/ui/motion/haptics';
import { mutationErrorToast, successToast } from '@/ui/components/error-toast';
import { useDangerColor, useForegroundColor, useMutedForegroundColor, useWaitingColor } from '@/ui/theme/colors';
import { computeClientOutstanding } from '@/domain/use-cases/compute-client-outstanding';
import type { TourStop } from '@/domain/models/tour-stop';
import type { Payment } from '@/domain/models/payment';

export default function ClientDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const fg = useForegroundColor();
  const mutedFg = useMutedForegroundColor();
  const waiting = useWaitingColor();
  const danger = useDangerColor();
  const { data: client, isError, refetch } = useClient(id);
  const { data: plannedTour } = useNextPlannedTourForClient(id);
  const { data: statusMap } = useClientStatusMap();
  const setPivotId = useProximityStore((s) => s.setPivotId);
  const anonymizeMutation = useAnonymizeClient();
  const toggleBanned = useToggleBanned();
  const [menuOpen, setMenuOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const { data: tours = [] } = useTours('completed');
  const { data: manualEntries = [] } = useManualHistoryByClient(id);

  const unpaidStops = useMemo(() => {
    const out: { stop: TourStop; tourId: string; scheduledDate: string }[] = [];
    for (const { tour, stops } of tours) {
      for (const s of stops) {
        if (s.clientId !== id) continue;
        if (!s.completedAt) continue;
        if (s.payment.isPaid) continue;
        out.push({ stop: s, tourId: tour.id, scheduledDate: tour.scheduledDate });
      }
    }
    return out;
  }, [tours, id]);

  const unpaidEntries = useMemo(
    () => manualEntries.filter((e) => !e.payment.isPaid),
    [manualEntries]
  );

  const outstanding = useMemo(
    () => computeClientOutstanding({
      completedStops: unpaidStops.map((u) => u.stop),
      manualEntries: unpaidEntries,
    }),
    [unpaidStops, unpaidEntries]
  );

  const [stopSheet, setStopSheet] = useState<{ stopId: string; tourId: string; payment: Payment } | null>(null);
  const [entrySheet, setEntrySheet] = useState<{ entryId: string; clientId: string; payment: Payment } | null>(null);

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  if (!client) return <Surface className="flex-1" />;

  if (client.anonymizedAt) {
    // Defensive : a deep link landed on an anonymized client. Redirect to the list.
    setTimeout(() => {
      successToast(t('clients.anonymized_redirect_toast'));
      router.back();
    }, 0);
    return <Surface className="flex-1" />;
  }

  const status = statusMap?.get(client.id) ?? 'default';

  const onDelete = () => {
    setMenuOpen(false);
    setDeleteDialogOpen(true);
  };

  const handleDeleteConfirmed = () => {
    setDeleteDialogOpen(false);
    anonymizeMutation.mutate(client.id, {
      onSuccess: () => {
        void haptics.success();
        router.back();
      },
      onError: (err) => {
        mutationErrorToast(t('clients.delete_failed_title'), err);
      },
    });
  };

  const onToggleBanned = async () => {
    setMenuOpen(false);
    if (!client.isBanned) {
      const ok = await confirm({
        title: t('clients.ban_confirm_title'),
        message: t('clients.ban_confirm_message'),
        confirmLabel: t('clients.ban'),
        cancelLabel: t('common.cancel'),
        destructive: true,
      });
      if (!ok) return;
    }
    toggleBanned.mutate({ id: client.id, isBanned: !client.isBanned });
  };

  const onFindNearby = () => {
    void haptics.selection();
    setPivotId(client.id);
    router.push('/(tabs)/proximity');
  };

  const showFindNearby = client.isWaiting && !plannedTour && client.latitude != null;

  return (
    <Surface className="flex-1">
      <ScreenHeader
        title={t('clients.detail_title')}
        rightSlot={
          <View className="flex-row gap-2">
            <Button
              size="sm"
              variant="ghost"
              onPress={() => router.push(`/(tabs)/clients/${client.id}/edit`)}
              accessibilityLabel={t('common.edit')}
            >
              <Pencil size={16} color={fg} />
            </Button>
            <Button
              size="sm"
              variant="ghost"
              onPress={() => {
                void haptics.selection();
                setMenuOpen(true);
              }}
              accessibilityLabel={t('clients.more_actions')}
            >
              <MoreVertical size={18} color={fg} />
            </Button>
          </View>
        }
      />

      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 32, gap: 16 }}>
        <Text className="text-2xl font-bold">{client.displayName}</Text>

        <ClientStatusBadge clientId={client.id} />

        <ClientContactCard client={client} />

        <ClientKpiRow clientId={client.id} />

        {outstanding.unpaidCount > 0 ? (
          <ClientOutstandingCard
            unpaidStops={unpaidStops}
            unpaidEntries={unpaidEntries}
            totalCents={outstanding.unpaidCents}
            count={outstanding.unpaidCount}
            onTapStop={(s) => setStopSheet({ stopId: s.stop.id, tourId: s.tourId, payment: s.stop.payment })}
            onTapEntry={(e) => setEntrySheet({ entryId: e.id, clientId: id, payment: e.payment })}
          />
        ) : null}

        <PlannedTourCard clientId={client.id} />

        {showFindNearby ? (
          <PressScale onPress={onFindNearby} accessibilityLabel={t('clients.find_nearby_cta')}>
            <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
              <Search size={18} color={waiting} />
              <View className="flex-1">
                <Text className="text-sm font-medium">{t('clients.find_nearby_cta')}</Text>
              </View>
              <ChevronRight size={16} color={mutedFg} />
            </Surface>
          </PressScale>
        ) : null}

        <ClientAnimalsSection client={client} />

        <ClientStatusActionsCard client={client} status={status} />

        <LastInterventionsList clientId={client.id} />
      </ScrollView>

      <StopPaymentSheet
        visible={stopSheet !== null}
        stopId={stopSheet?.stopId ?? null}
        tourId={stopSheet?.tourId ?? ''}
        initial={stopSheet?.payment ?? null}
        onClose={() => setStopSheet(null)}
      />
      <ManualEntryPaymentSheet
        visible={entrySheet !== null}
        entryId={entrySheet?.entryId ?? null}
        clientId={entrySheet?.clientId ?? ''}
        initial={entrySheet?.payment ?? null}
        onClose={() => setEntrySheet(null)}
      />

      <Modal
        visible={menuOpen}
        animationType="fade"
        transparent
        presentationStyle="overFullScreen"
        onRequestClose={() => setMenuOpen(false)}
      >
        <TouchableOpacity
          style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
          onPress={() => setMenuOpen(false)}
          activeOpacity={1}
        />
        <Surface className="rounded-t-3xl px-4 pt-3 pb-8">
          <View className="self-center w-10 h-1 rounded-full bg-foreground/20 dark:bg-foreground-dark/20 mb-3" />
          <View className="gap-1">
            <PressScale
              onPress={onToggleBanned}
              accessibilityLabel={client.isBanned ? t('clients.unban') : t('clients.ban')}
            >
              <View className="flex-row items-center gap-3 px-2 py-3">
                <Ban size={20} color={fg} />
                <Text className="flex-1 text-base">
                  {client.isBanned ? t('clients.unban') : t('clients.ban')}
                </Text>
              </View>
            </PressScale>
            <PressScale onPress={onDelete} accessibilityLabel={t('clients.delete')}>
              <View className="flex-row items-center gap-3 px-2 py-3">
                <Trash2 size={20} color={danger} />
                <Text className="flex-1 text-base" style={{ color: danger }}>
                  {t('clients.delete')}
                </Text>
              </View>
            </PressScale>
          </View>
        </Surface>
      </Modal>

      <ConfirmTypedDialog
        visible={deleteDialogOpen}
        title={t('clients.delete_confirm_title')}
        message={t('clients.delete_confirm_message')}
        typedConfirmation={t('clients.delete_typed_word')}
        confirmLabel={t('clients.delete_cta_confirm')}
        cancelLabel={t('common.cancel')}
        onConfirm={handleDeleteConfirmed}
        onCancel={() => setDeleteDialogOpen(false)}
      />
    </Surface>
  );
}
