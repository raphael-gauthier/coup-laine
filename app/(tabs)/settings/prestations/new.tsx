import { Stack, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { PrestationForm } from '@/ui/components/prestation-form';
import { useUpsertPrestation } from '@/state/queries/catalogs';
import { haptics } from '@/ui/motion/haptics';

export default function NewPrestationScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const upsert = useUpsertPrestation();

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ title: t('catalogs.prestations.new_title'), presentation: 'modal' }} />
      <PrestationForm
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
