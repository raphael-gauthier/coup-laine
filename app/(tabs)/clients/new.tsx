import { Stack, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { ClientForm } from '@/ui/components/client-form';
import { useUpsertClient } from '@/state/queries/clients';
import { haptics } from '@/ui/motion/haptics';
import { mutationErrorToast } from '@/ui/components/error-toast';

export default function NewClientScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const upsert = useUpsertClient();

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ presentation: 'modal' }} />
      <ScreenHeader title={t('clients.new_title')} />

      <ClientForm
        saving={upsert.isPending}
        onCancel={() => router.back()}
        onSubmit={(input) =>
          upsert.mutate(input, {
            onSuccess: (client) => {
              void haptics.success();
              router.replace({
                pathname: '/(tabs)/clients/[id]',
                params: { id: client.id, justCreated: '1' },
              });
            },
            onError: (err) => {
              mutationErrorToast(t('clients.save_failed_title'), err);
            },
          })
        }
      />
    </Surface>
  );
}
