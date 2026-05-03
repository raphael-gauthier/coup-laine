import { useState, useMemo } from 'react';
import { View, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { ArrowLeft, Mail, Check } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { useSignInOtp } from '@/state/queries/auth';
import { haptics } from '@/ui/motion/haptics';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function LoginScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [touched, setTouched] = useState(false);
  const [sent, setSent] = useState(false);
  const signIn = useSignInOtp();

  const error = useMemo(() => {
    if (email.trim().length === 0) return t('auth.errors.email_required');
    if (!EMAIL_REGEX.test(email.trim())) return t('auth.errors.email_invalid');
    return null;
  }, [email, t]);

  const onSubmit = () => {
    setTouched(true);
    if (error) return;
    signIn.mutate(email.trim(), {
      onSuccess: () => {
        void haptics.success();
        setSent(true);
      },
    });
  };

  return (
    <Surface className="flex-1">
      <ScrollView contentContainerStyle={{ flexGrow: 1, padding: 24, gap: 24 }}>
        <PressScale onPress={() => router.back()}>
          <ArrowLeft size={28} color="#1C1612" />
        </PressScale>

        {sent ? (
          <View className="items-center gap-4 mt-12">
            <Check size={64} color="#547A46" />
            <Text className="text-2xl font-bold text-center">{t('auth.link_sent_title')}</Text>
            <Text variant="muted" className="text-center">{t('auth.link_sent_message')}</Text>
          </View>
        ) : (
          <>
            <View className="items-center gap-3 mt-8">
              <Mail size={48} color="#A1602F" />
              <Text className="text-2xl font-bold text-center">{t('auth.login_title')}</Text>
              <Text variant="muted" className="text-center">{t('auth.login_message')}</Text>
            </View>

            <View className="gap-2">
              <Text className="text-sm font-medium">{t('auth.email')}</Text>
              <Input
                value={email}
                onChangeText={setEmail}
                onBlur={() => setTouched(true)}
                keyboardType="email-address"
                autoCapitalize="none"
                placeholder={t('auth.email_placeholder')}
              />
              {touched && error ? (
                <Text className="text-sm text-danger dark:text-danger-dark">{error}</Text>
              ) : null}
            </View>

            <View style={{ flex: 1 }} />

            <Button onPress={onSubmit} loading={signIn.isPending} disabled={!!error || signIn.isPending}>
              {t('auth.send_link_cta')}
            </Button>
          </>
        )}
      </ScrollView>
    </Surface>
  );
}
