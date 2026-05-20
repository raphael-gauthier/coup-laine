import { Stack, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { StatusForm } from '@/ui/components/status-form';
import { mutationErrorToast } from '@/ui/components/error-toast';
import { useCreateManualStatus } from '@/state/queries/statuses';
import { haptics } from '@/ui/motion/haptics';

export default function NewStatusScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const create = useCreateManualStatus();

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ presentation: 'modal' }} />
      <ScreenHeader title={t('statuses.create_title')} />
      <StatusForm
        saving={create.isPending}
        onCancel={() => router.back()}
        onSubmit={(v) =>
          create.mutate(
            { label: v.label, colorLight: v.colorLight, colorDark: v.colorDark },
            {
              onSuccess: () => { void haptics.success(); router.back(); },
              onError: (err) => mutationErrorToast(t('statuses.save_failed'), err),
            },
          )
        }
      />
    </Surface>
  );
}
