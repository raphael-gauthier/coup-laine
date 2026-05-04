import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { ManualHistoryForm } from '@/ui/components/manual-history-form';
import { useUpsertManualHistoryEntry } from '@/state/queries/history';
import { haptics } from '@/ui/motion/haptics';

export default function NewManualHistoryScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const upsert = useUpsertManualHistoryEntry();
  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ presentation: 'modal' }} />
      <ScreenHeader title={t('history.manual.new_title')} />
      <ManualHistoryForm
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
