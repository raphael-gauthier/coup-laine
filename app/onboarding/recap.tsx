import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { CheckCircle } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { useBaseAddress, useMarkOnboardingComplete } from '@/state/queries/settings';
import { useSpecies } from '@/state/queries/species';
import { haptics } from '@/ui/motion/haptics';
import { mutationErrorToast } from '@/ui/components/error-toast';

export default function OnboardingRecapScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const { data: base } = useBaseAddress();
  const { data: speciesList = [] } = useSpecies();
  const markComplete = useMarkOnboardingComplete();

  const onLaunch = () => {
    markComplete.mutate(undefined, {
      onSuccess: () => {
        void haptics.success();
        router.replace('/(tabs)/clients' as never);
      },
      onError: (err) => {
        mutationErrorToast(t('onboarding.recap.launch_failed'), err);
      },
    });
  };

  return (
    <Surface className="flex-1 items-center justify-center px-8">
      <View className="items-center gap-6 max-w-sm w-full">
        <CheckCircle size={64} color="#A1602F" />
        <Text className="text-2xl font-bold text-center">{t('onboarding.recap.title')}</Text>
        <Text variant="muted" className="text-center">{t('onboarding.recap.message')}</Text>

        <Surface variant="muted" className="rounded-2xl px-4 py-3 w-full gap-2">
          <View className="flex-row justify-between">
            <Text variant="muted" className="text-sm">{t('onboarding.recap.address_label')}</Text>
            <Text className="text-sm font-medium flex-1 text-right ml-4">
              {base?.label ?? '—'}
            </Text>
          </View>
          <View className="flex-row justify-between">
            <Text variant="muted" className="text-sm">{t('onboarding.recap.species_label')}</Text>
            <Text className="text-sm font-medium">
              {t('onboarding.recap.species_count', { count: speciesList.length })}
            </Text>
          </View>
        </Surface>

        <Button
          className="w-full mt-2"
          onPress={onLaunch}
          disabled={markComplete.isPending}
          loading={markComplete.isPending}
        >
          <Text variant="onPrimary" className="font-semibold">{t('onboarding.recap.cta')}</Text>
        </Button>
      </View>
    </Surface>
  );
}
