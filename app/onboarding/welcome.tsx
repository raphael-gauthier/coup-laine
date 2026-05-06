import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import * as WebBrowser from 'expo-web-browser';
import { ArrowRight, Scissors } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { useOnContrastColor, usePrimaryColor } from '@/ui/theme/colors';
import { LEGAL_URLS } from '@/infra/config/legal-urls';

export default function WelcomeScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const onContrast = useOnContrastColor();
  const primary = usePrimaryColor();

  const openPrivacy = async () => {
    await WebBrowser.openBrowserAsync(LEGAL_URLS.privacyPolicy);
  };

  return (
    <Surface className="flex-1 items-center justify-center px-8">
      <View className="items-center gap-6 max-w-sm">
        <Scissors size={64} color={primary} />
        <Text className="text-4xl font-bold text-center">{t('onboarding.welcome.title')}</Text>
        <Text variant="muted" className="text-center text-base">
          {t('onboarding.welcome.message')}
        </Text>
        <Button
          onPress={() => router.push('/onboarding/base' as never)}
          className="mt-4"
          accessibilityLabel={t('onboarding.welcome.cta')}
        >
          <Text variant="onPrimary" className="font-semibold">{t('onboarding.welcome.cta')}</Text>
          <ArrowRight size={18} color={onContrast} />
        </Button>

        <Surface variant="muted" className="rounded-2xl px-4 py-3 mt-4">
          <Text variant="muted" className="text-xs text-center">
            {t('onboarding.welcome.privacy_intro')}
          </Text>
          <PressScale onPress={openPrivacy} accessibilityLabel={t('onboarding.welcome.privacy_link')}>
            <Text className="text-xs text-center mt-2 underline">
              {t('onboarding.welcome.privacy_link')}
            </Text>
          </PressScale>
        </Surface>
      </View>
    </Surface>
  );
}
