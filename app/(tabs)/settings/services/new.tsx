import { Stack, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { ServiceForm } from '@/ui/components/service-form';
import { useUpsertService } from '@/state/queries/catalogs';
import { haptics } from '@/ui/motion/haptics';

export default function NewServiceScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const upsert = useUpsertService();

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ presentation: 'modal' }} />
      <ScreenHeader title={t('catalogs.services.new_title')} />
      <ServiceForm
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
