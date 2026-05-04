import { useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { ClientForm } from '@/ui/components/client-form';
import { ErrorState } from '@/ui/components/error-state';
import { useClient, useUpsertClient } from '@/state/queries/clients';
import { haptics } from '@/ui/motion/haptics';
import { errorToast } from '@/ui/components/error-toast';

export default function EditClientScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const { data: client, isError, refetch } = useClient(id);
  const upsert = useUpsertClient();

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  if (!client) return <Surface className="flex-1" />;

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('clients.edit_title')} />
      <ClientForm
        initial={client}
        saving={upsert.isPending}
        onCancel={() => router.back()}
        onSubmit={(input) =>
          upsert.mutate(input, {
            onSuccess: () => {
              void haptics.success();
              router.back();
            },
            onError: (err) => {
              errorToast(t('clients.save_failed_title'), err instanceof Error ? err.message : undefined);
            },
          })
        }
      />
    </Surface>
  );
}
