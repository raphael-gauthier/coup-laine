import { View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { useToggleWaiting } from '@/state/queries/clients';
import { useUpsertManualHistoryEntry, useManualHistoryByClient } from '@/state/queries/history';
import { useAllSettings } from '@/state/queries/settings';
import { useDeleteManualHistoryEntry } from '@/state/queries/history';
import type { Client } from '@/domain/models/client';
import { haptics } from '@/ui/motion/haptics';
import { errorToast } from '@/ui/components/error-toast';
import { useQueryClient } from '@tanstack/react-query';
import { clientsKeys } from '@/state/queries/clients';

interface Props {
  client: Client;
}

export function ClientStatusActionsCard({ client }: Props) {
  const { t } = useTranslation();
  const toggleWaiting = useToggleWaiting();
  const addManualEntry = useUpsertManualHistoryEntry();
  const deleteManualEntry = useDeleteManualHistoryEntry();
  const { data: settings } = useAllSettings();
  const { data: manualEntries = [] } = useManualHistoryByClient(client.id);
  const qc = useQueryClient();

  // "Mark done" — add an empty manual history entry for today
  const onMarkDone = () => {
    const today = new Date().toISOString().slice(0, 10);
    addManualEntry.mutate(
      { clientId: client.id, date: today, notes: null, prestations: [] },
      {
        onSuccess: () => {
          void haptics.success();
          // Invalidate statusMap so it recomputes
          void qc.invalidateQueries({ queryKey: ['clients', 'statusMap'] });
        },
        onError: (err) => {
          errorToast(t('clients.mark_done_failed'), err instanceof Error ? err.message : undefined);
        },
      }
    );
  };

  // "Reset" — delete manual entries from >= seasonStartedAt
  const onReset = () => {
    const seasonStart = settings?.season_started_at ?? new Date().getFullYear() + '-01-01';
    const toDelete = manualEntries.filter((e) => e.date >= seasonStart && e.prestations.length === 0);
    Promise.all(
      toDelete.map((e) =>
        new Promise<void>((resolve, reject) =>
          deleteManualEntry.mutate(
            { id: e.id, clientId: client.id },
            { onSuccess: () => resolve(), onError: reject }
          )
        )
      )
    ).then(() => {
      void haptics.success();
      void qc.invalidateQueries({ queryKey: ['clients', 'statusMap'] });
    }).catch((err) => {
      errorToast(t('clients.reset_status_failed'), err instanceof Error ? err.message : undefined);
    });
  };

  // Toggle banned — use upsertClient via toggleWaiting analog
  // Note: there's no direct toggleBanned in queries; we use the waiting toggle pattern
  // For banned we'll show a UI note — this is a TODO per plan §4.5
  // The waiting toggle is available

  return (
    <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-3">
      <Text className="font-semibold">{t('clients.actions_title')}</Text>

      <View className="flex-row items-center justify-between">
        <Text className="text-sm">{t('clients.mark_waiting')}</Text>
        <Button
          size="sm"
          variant={client.isWaiting ? 'primary' : 'secondary'}
          onPress={() => toggleWaiting.mutate({ id: client.id, isWaiting: !client.isWaiting })}
          loading={toggleWaiting.isPending}
        >
          {client.isWaiting ? t('clients.unmark_waiting') : t('clients.mark_waiting')}
        </Button>
      </View>

      <Button
        variant="secondary"
        onPress={onMarkDone}
        loading={addManualEntry.isPending}
      >
        {t('clients.mark_done')}
      </Button>

      <Button
        variant="ghost"
        onPress={onReset}
        loading={deleteManualEntry.isPending}
      >
        {t('clients.reset_status')}
      </Button>
    </Surface>
  );
}
