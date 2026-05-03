import { Stack, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { ClientForm } from '@/ui/components/client-form';
import { useUpsertClient } from '@/state/queries/clients';
import { haptics } from '@/ui/motion/haptics';

export default function NewClientScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const upsert = useUpsertClient();

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ title: t('clients.new_title'), presentation: 'modal' }} />
      <ClientForm
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
