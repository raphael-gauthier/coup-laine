import { ActivityIndicator, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { CloudDownload } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { useBackups, useRestoreBackup } from '@/state/queries/backups';
import { haptics } from '@/ui/motion/haptics';
import { usePrimaryColor } from '@/ui/theme/colors';
import { mutationErrorToast } from '@/ui/components/error-toast';

export default function RestorePromptScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const { data: backups = [], isLoading } = useBackups();
  const restore = useRestoreBackup();
  const primary = usePrimaryColor();

  const mostRecent = backups[0];

  const onRestore = () => {
    if (!mostRecent) return;
    restore.mutate(mostRecent.name, {
      onSuccess: () => {
        void haptics.success();
        router.replace('/(tabs)/clients' as never);
      },
      onError: (err) => {
        mutationErrorToast(t('onboarding.restore_prompt.restore_failed'), err);
      },
    });
  };

  const onFresh = () => {
    router.replace('/onboarding/welcome' as never);
  };

  if (isLoading) {
    return (
      <Surface className="flex-1 items-center justify-center gap-4">
        <ActivityIndicator size="large" />
        <Text variant="muted">{t('common.loading')}</Text>
      </Surface>
    );
  }

  return (
    <Surface className="flex-1 items-center justify-center px-8">
      <View className="items-center gap-6 max-w-sm w-full">
        <CloudDownload size={64} color={primary} />
        <Text className="text-2xl font-bold text-center">{t('onboarding.restore_prompt.title')}</Text>
        <Text variant="muted" className="text-center">{t('onboarding.restore_prompt.message')}</Text>

        <Button
          className="w-full"
          onPress={onRestore}
          disabled={!mostRecent || restore.isPending}
          loading={restore.isPending}
          accessibilityLabel={t('onboarding.restore_prompt.restore_cta')}
        >
          <Text variant="onPrimary" className="font-semibold">{t('onboarding.restore_prompt.restore_cta')}</Text>
        </Button>

        <Button
          variant="secondary"
          className="w-full"
          onPress={onFresh}
          disabled={restore.isPending}
        >
          {t('onboarding.restore_prompt.fresh_cta')}
        </Button>
      </View>
    </Surface>
  );
}
