import { useLocalSearchParams, useRouter } from 'expo-router';
import { View } from 'react-native';
import { Trash2 } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { ManualHistoryForm } from '@/ui/components/manual-history-form';
import { Button } from '@/ui/primitives/button';
import { ErrorState } from '@/ui/components/error-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { confirm } from '@/ui/components/confirm-dialog';
import {
  useUpsertManualHistoryEntry,
  useDeleteManualHistoryEntry,
  useManualHistoryByClient,
} from '@/state/queries/history';
import { haptics } from '@/ui/motion/haptics';
import { useOnContrastColor } from '@/ui/theme/colors';

export default function EditManualHistoryScreen() {
  const { id, entryId } = useLocalSearchParams<{ id: string; entryId: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const onContrast = useOnContrastColor();
  const upsert = useUpsertManualHistoryEntry();
  const del = useDeleteManualHistoryEntry();
  const { data: entries = [], isError, refetch } = useManualHistoryByClient(id);

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  const entry = entries.find((e) => e.id === entryId);
  if (!entry) return <Surface className="flex-1" />;

  const onDelete = async () => {
    const ok = await confirm({
      title: t('history.manual.delete_confirm_title'),
      message: t('history.manual.delete_confirm_message'),
      confirmLabel: t('history.manual.delete'),
      cancelLabel: t('common.cancel'),
      destructive: true,
    });
    if (!ok) return;
    del.mutate(
      { id: entry.id, clientId: id },
      {
        onSuccess: () => { void haptics.success(); router.back(); },
      }
    );
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader
        title={t('history.manual.edit_title')}
        rightSlot={
          <View className="flex-row gap-2">
            <Button size="sm" variant="danger" onPress={onDelete} accessibilityLabel={t('history.manual.delete')}>
              <Trash2 size={16} color={onContrast} />
            </Button>
          </View>
        }
      />
      <ManualHistoryForm
        initial={entry}
        clientId={id}
        saving={upsert.isPending}
        onCancel={() => router.back()}
        onSubmit={(input) =>
          upsert.mutate(input, {
            onSuccess: () => { void haptics.success(); router.back(); },
          })
        }
      />
    </Surface>
  );
}
