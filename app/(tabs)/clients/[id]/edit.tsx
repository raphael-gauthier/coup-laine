import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { ClientForm } from '@/ui/components/client-form';
import { ErrorState } from '@/ui/components/error-state';
import { useClient, useUpsertClient } from '@/state/queries/clients';
import { haptics } from '@/ui/motion/haptics';

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
      <Stack.Screen options={{ title: t('clients.edit_title') }} />
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
          })
        }
      />
    </Surface>
  );
}
