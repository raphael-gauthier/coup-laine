import { useState, useMemo } from 'react';
import { View, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { ArrowLeft, Mail } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { useSendOtp, useVerifyOtp, type OtpKind } from '@/state/queries/auth';
import { haptics } from '@/ui/motion/haptics';
import { resolveFirstSignIn } from '@/state/onboarding/first-sign-in-resolver';
import { successToast } from '@/ui/components/error-toast';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function LoginScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [emailTouched, setEmailTouched] = useState(false);
  const [code, setCode] = useState('');
  const [codeTouched, setCodeTouched] = useState(false);
  const [otpKind, setOtpKind] = useState<OtpKind | null>(null);

  const sendOtp = useSendOtp();
  const verifyOtp = useVerifyOtp();

  const emailError = useMemo(() => {
    if (email.trim().length === 0) return t('auth.errors.email_required');
    if (!EMAIL_REGEX.test(email.trim())) return t('auth.errors.email_invalid');
    return null;
  }, [email, t]);

  const codeError = useMemo(() => {
    if (code.length !== 6) return t('auth.errors.code_invalid_length');
    return null;
  }, [code, t]);

  const onSendCode = () => {
    setEmailTouched(true);
    if (emailError) return;
    sendOtp.mutate(email.trim(), {
      onSuccess: (result) => {
        void haptics.success();
        setOtpKind(result.kind);
        setCode('');
        setCodeTouched(false);
      },
    });
  };

  const onVerify = () => {
    setCodeTouched(true);
    if (codeError || !otpKind) return;
    verifyOtp.mutate(
      { email: email.trim(), token: code, kind: otpKind },
      {
        onSuccess: async (session) => {
          successToast(
            t('auth.signed_in_title'),
            t('auth.signed_in_message', { email: session.user.email ?? email.trim() }),
          );
          try {
            const result = await resolveFirstSignIn(session.user.id);
            if (result === 'choice') {
              router.replace('/onboarding/restore-prompt' as never);
              return;
            }
          } catch {
            // Resolver failure is non-fatal — fall through to default route.
          }
          router.replace('/(tabs)/clients' as never);
        },
      },
    );
  };

  const onChangeEmail = () => {
    setOtpKind(null);
    setCode('');
    setCodeTouched(false);
  };

  const codeStep = otpKind != null;

  return (
    <Surface className="flex-1">
      <ScrollView contentContainerStyle={{ flexGrow: 1, padding: 24, gap: 24 }}>
        <PressScale onPress={() => router.back()}>
          <ArrowLeft size={28} color="#1C1612" />
        </PressScale>

        <View className="items-center gap-3 mt-8">
          <Mail size={48} color="#A1602F" />
          <Text className="text-2xl font-bold text-center">
            {codeStep ? t('auth.code_sent_title') : t('auth.login_title')}
          </Text>
          <Text variant="muted" className="text-center">
            {codeStep ? t('auth.code_sent_message') : t('auth.login_message')}
          </Text>
        </View>

        {codeStep ? (
          <>
            <View className="gap-2">
              <Text className="text-sm font-medium">{t('auth.code_label')}</Text>
              <Input
                value={code}
                onChangeText={(v) => setCode(v.replace(/\D/g, '').slice(0, 6))}
                onBlur={() => setCodeTouched(true)}
                keyboardType="number-pad"
                autoComplete="one-time-code"
                textContentType="oneTimeCode"
                placeholder={t('auth.code_placeholder')}
                maxLength={6}
              />
              {codeTouched && codeError ? (
                <Text className="text-sm text-danger dark:text-danger-dark">{codeError}</Text>
              ) : null}
            </View>

            <View style={{ flex: 1 }} />

            <Button onPress={onVerify} loading={verifyOtp.isPending} disabled={!!codeError || verifyOtp.isPending}>
              {verifyOtp.isPending ? t('auth.verifying') : t('auth.verify_cta')}
            </Button>
            <Button variant="secondary" onPress={() => onSendCode()} loading={sendOtp.isPending} disabled={sendOtp.isPending}>
              {t('auth.resend_cta')}
            </Button>
            <Button variant="ghost" onPress={onChangeEmail} disabled={sendOtp.isPending || verifyOtp.isPending}>
              {t('auth.change_email_cta')}
            </Button>
          </>
        ) : (
          <>
            <View className="gap-2">
              <Text className="text-sm font-medium">{t('auth.email')}</Text>
              <Input
                value={email}
                onChangeText={setEmail}
                onBlur={() => setEmailTouched(true)}
                keyboardType="email-address"
                autoCapitalize="none"
                placeholder={t('auth.email_placeholder')}
              />
              {emailTouched && emailError ? (
                <Text className="text-sm text-danger dark:text-danger-dark">{emailError}</Text>
              ) : null}
            </View>

            <View style={{ flex: 1 }} />

            <Button onPress={onSendCode} loading={sendOtp.isPending} disabled={!!emailError || sendOtp.isPending}>
              {t('auth.send_code_cta')}
            </Button>
          </>
        )}
      </ScrollView>
    </Surface>
  );
}
