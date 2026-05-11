import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { TUTORIAL_KEYS } from '@/domain/tutorial/keys';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ScreenHeader } from '@/ui/components/screen-header';
import { useResetTutorials, useTutorialProgress } from '@/state/queries/tutorial';
import { confirm } from '@/ui/components/confirm-dialog';
import { successToast, mutationErrorToast } from '@/ui/components/error-toast';

const TOTAL_TUTORIALS = Object.values(TUTORIAL_KEYS).length;

export default function HelpSettingsScreen() {
  const { t } = useTranslation();
  const { data } = useTutorialProgress();
  const reset = useResetTutorials();

  const seen = data?.count ?? 0;

  const handleReplay = async () => {
    const ok = await confirm({
      title: t('settings.help.replay_confirm_title'),
      message: t('settings.help.replay_confirm_body'),
      confirmLabel: t('common.confirm'),
      cancelLabel: t('common.cancel'),
    });
    if (!ok) return;
    try {
      await reset.mutateAsync();
      successToast(t('settings.help.replay_success'));
    } catch (err) {
      mutationErrorToast(t('common.error_generic'), err);
    }
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('settings.help.screen_title')} />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 32, gap: 16 }}>
        <Text>{t('settings.help.intro')}</Text>

        <View className="gap-2">
          <Text variant="muted" className="text-sm">
            {t('settings.help.counter', { seen, total: TOTAL_TUTORIALS })}
          </Text>
          <Button variant="secondary" onPress={handleReplay} disabled={reset.isPending}>
            {t('settings.help.replay_cta')}
          </Button>
        </View>
      </ScrollView>
    </Surface>
  );
}
