import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useQueryClient } from '@tanstack/react-query';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ThemedSwitch } from '@/ui/primitives/themed-switch';
import { useToggleWaiting } from '@/state/queries/clients';
import {
  useManualHistoryByClient,
  useDeleteManualHistoryEntry,
} from '@/state/queries/history';
import { useAllSettings } from '@/state/queries/settings';
import { useStatusRegistry } from '@/state/queries/statuses';
import type { Client } from '@/domain/models/client';
import type { ClientStatus } from '@/domain/use-cases/client-status';
import { haptics } from '@/ui/motion/haptics';
import { mutationErrorToast } from '@/ui/components/error-toast';

interface Props {
  client: Client;
  status: ClientStatus;
}

export function ClientStatusActionsCard({ client, status }: Props) {
  const { t } = useTranslation();
  const toggleWaiting = useToggleWaiting();
  const deleteManualEntry = useDeleteManualHistoryEntry();
  const { data: settings } = useAllSettings();
  const { data: manualEntries = [] } = useManualHistoryByClient(client.id);
  const { data: registry } = useStatusRegistry();
  const qc = useQueryClient();
  const waitingLabel = registry?.bySystemKey('waiting').label ?? t('clients.is_waiting_label');

  const onReset = () => {
    const seasonStart = settings?.season_started_at ?? new Date().getFullYear() + '-01-01';
    const toDelete = manualEntries.filter((e) => e.date >= seasonStart && e.services.length === 0);
    Promise.all(
      toDelete.map((e) =>
        new Promise<void>((resolve, reject) =>
          deleteManualEntry.mutate(
            { id: e.id, clientId: client.id },
            { onSuccess: () => resolve(), onError: reject }
          )
        )
      )
    )
      .then(() => {
        void haptics.success();
        void qc.invalidateQueries({ queryKey: ['clients', 'statusMap'] });
      })
      .catch((err) => {
        mutationErrorToast(t('clients.reset_status_failed'), err);
      });
  };

  // Statuses where this card has nothing useful to offer
  if (status === 'scheduled' || status === 'noAnimals' || status === 'banned') {
    return null;
  }

  const showWaitingToggle = status === 'default' || status === 'waiting';
  const showReset = status === 'done';

  return (
    <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-3">
      <Text className="font-semibold">{t('clients.actions_title')}</Text>

      {showWaitingToggle ? (
        <View className="flex-row items-center justify-between">
          <Text>{waitingLabel}</Text>
          <ThemedSwitch
            value={client.isWaiting}
            onValueChange={(v) => toggleWaiting.mutate({ id: client.id, isWaiting: v })}
            disabled={toggleWaiting.isPending}
          />
        </View>
      ) : null}

      {showReset ? (
        <Button variant="ghost" onPress={onReset} loading={deleteManualEntry.isPending}>
          {t('clients.reset_status')}
        </Button>
      ) : null}
    </Surface>
  );
}
