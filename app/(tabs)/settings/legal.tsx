import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import * as WebBrowser from 'expo-web-browser';
import Constants from 'expo-constants';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { ScreenHeader } from '@/ui/components/screen-header';
import { SettingsRow } from '@/ui/components/settings-row';
import { LEGAL_URLS } from '@/infra/config/legal-urls';

const APP_VERSION = Constants.expoConfig?.version ?? '0.0.0';

export default function LegalScreen() {
  const { t } = useTranslation();

  const open = async (url: string) => {
    await WebBrowser.openBrowserAsync(url);
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('settings.legal.screen_title')} />
      <ScrollView contentContainerClassName="px-4 pb-8">
        <SettingsRow
          label={t('settings.legal.legal_notices')}
          onPress={() => open(LEGAL_URLS.legalNotices)}
        />
        <SettingsRow
          label={t('settings.legal.privacy_policy')}
          onPress={() => open(LEGAL_URLS.privacyPolicy)}
        />
        <SettingsRow
          label={t('settings.legal.terms')}
          onPress={() => open(LEGAL_URLS.terms)}
        />

        <View className="mt-8 px-4">
          <Text variant="muted" className="text-xs text-center">
            {t('settings.legal.app_version', { version: APP_VERSION })}
          </Text>
        </View>
      </ScrollView>
    </Surface>
  );
}
