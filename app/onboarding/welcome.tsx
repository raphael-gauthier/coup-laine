import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { ArrowRight, Scissors } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';

export default function WelcomeScreen() {
  const { t } = useTranslation();
  const router = useRouter();

  return (
    <Surface className="flex-1 items-center justify-center px-8">
      <View className="items-center gap-6 max-w-sm">
        <Scissors size={64} color="#A1602F" />
        <Text className="text-4xl font-bold text-center">{t('onboarding.welcome.title')}</Text>
        <Text variant="muted" className="text-center text-base">
          {t('onboarding.welcome.message')}
        </Text>
        <Button onPress={() => router.push('/onboarding/base' as never)} className="mt-4">
          <Text variant="onPrimary" className="font-semibold">{t('onboarding.welcome.cta')}</Text>
          <ArrowRight size={18} color="white" />
        </Button>
      </View>
    </Surface>
  );
}
