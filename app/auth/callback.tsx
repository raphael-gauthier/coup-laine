import { useEffect } from 'react';
import { ActivityIndicator, View } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { supabase } from '@/infra/services/supabase';
import { errorToast } from '@/ui/components/error-toast';

export default function AuthCallbackScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const params = useLocalSearchParams<{
    access_token?: string;
    refresh_token?: string;
    type?: string;
  }>();

  useEffect(() => {
    (async () => {
      const access_token = typeof params.access_token === 'string' ? params.access_token : undefined;
      const refresh_token = typeof params.refresh_token === 'string' ? params.refresh_token : undefined;
      if (!access_token || !refresh_token) {
        errorToast('Lien invalide', 'Tokens manquants dans le lien magique.');
        router.replace('/(tabs)/clients' as never);
        return;
      }
      const { error } = await supabase.auth.setSession({ access_token, refresh_token });
      if (error) {
        errorToast('Connexion impossible', error.message);
      }
      router.replace('/(tabs)/clients' as never);
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <Surface className="flex-1">
      <View className="flex-1 items-center justify-center gap-4">
        <ActivityIndicator size="large" />
        <Text variant="muted">{t('auth.callback_title')}</Text>
      </View>
    </Surface>
  );
}
