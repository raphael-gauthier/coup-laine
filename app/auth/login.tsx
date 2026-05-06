import { useState } from 'react';
import { View, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import type { TFunction } from 'i18next';
import { ArrowLeft, Mail } from 'lucide-react-native';
import * as WebBrowser from 'expo-web-browser';
import { LEGAL_URLS } from '@/infra/config/legal-urls';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { FormField } from '@/ui/components/form-field';
import { RHFTextField } from '@/ui/components/rhf-text-field';
import { useSendOtp, useVerifyOtp, type OtpKind } from '@/state/queries/auth';
import { haptics } from '@/ui/motion/haptics';
import { useForegroundColor, usePrimaryColor } from '@/ui/theme/colors';
import { resolveFirstSignIn } from '@/state/onboarding/first-sign-in-resolver';
import { successToast } from '@/ui/components/error-toast';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

interface EmailFormValues {
  email: string;
}

interface CodeFormValues {
  code: string;
}

function makeEmailSchema(t: TFunction) {
  return z.object({
    email: z
      .string()
      .trim()
      .min(1, t('auth.errors.email_required'))
      .regex(EMAIL_REGEX, t('auth.errors.email_invalid')),
  });
}

function makeCodeSchema(t: TFunction) {
  return z.object({
    code: z.string().length(6, t('auth.errors.code_invalid_length')),
  });
}

export default function LoginScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const [otpKind, setOtpKind] = useState<OtpKind | null>(null);

  const sendOtp = useSendOtp();
  const verifyOtp = useVerifyOtp();
  const fg = useForegroundColor();
  const primary = usePrimaryColor();

  const emailForm = useForm<EmailFormValues>({
    defaultValues: { email: '' },
    resolver: zodResolver(makeEmailSchema(t)),
    mode: 'onTouched',
  });

  const codeForm = useForm<CodeFormValues>({
    defaultValues: { code: '' },
    resolver: zodResolver(makeCodeSchema(t)),
    mode: 'onTouched',
  });

  const emailValid = (values: EmailFormValues) => {
    sendOtp.mutate(values.email.trim(), {
      onSuccess: (result) => {
        void haptics.success();
        setOtpKind(result.kind);
        codeForm.reset({ code: '' });
      },
    });
  };

  const emailInvalid = () => {
    void haptics.error();
  };

  const codeValid = (values: CodeFormValues) => {
    if (!otpKind) return;
    const emailValue = emailForm.getValues('email').trim();
    verifyOtp.mutate(
      { email: emailValue, token: values.code, kind: otpKind },
      {
        onSuccess: async (session) => {
          successToast(
            t('auth.signed_in_title'),
            t('auth.signed_in_message', { email: session.user.email ?? emailValue }),
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

  const codeInvalid = () => {
    void haptics.error();
  };

  const onChangeEmail = () => {
    setOtpKind(null);
    emailForm.reset({ email: '' });
    codeForm.reset({ code: '' });
  };

  const codeStep = otpKind != null;

  const openTerms = () => WebBrowser.openBrowserAsync(LEGAL_URLS.terms);
  const openPrivacy = () => WebBrowser.openBrowserAsync(LEGAL_URLS.privacyPolicy);

  return (
    <Surface className="flex-1">
      <ScrollView contentContainerStyle={{ flexGrow: 1, padding: 24, gap: 24 }}>
        <PressScale onPress={() => router.back()} accessibilityLabel={t('common.back')}>
          <ArrowLeft size={28} color={fg} />
        </PressScale>

        <View className="items-center gap-3 mt-8">
          <Mail size={48} color={primary} />
          <Text className="text-2xl font-bold text-center">
            {codeStep ? t('auth.code_sent_title') : t('auth.login_title')}
          </Text>
          <Text variant="muted" className="text-center">
            {codeStep ? t('auth.code_sent_message') : t('auth.login_message')}
          </Text>
        </View>

        {codeStep ? (
          <>
            <Controller
              control={codeForm.control}
              name="code"
              render={({ field, fieldState }) => (
                <FormField label={t('auth.code_label')} error={fieldState.error?.message}>
                  <Input
                    value={field.value}
                    onChangeText={(v) => field.onChange(v.replace(/\D/g, '').slice(0, 6))}
                    onBlur={field.onBlur}
                    keyboardType="number-pad"
                    autoComplete="one-time-code"
                    textContentType="oneTimeCode"
                    placeholder={t('auth.code_placeholder')}
                    maxLength={6}
                    accessibilityLabel={t('auth.code_label')}
                  />
                </FormField>
              )}
            />

            <View style={{ flex: 1 }} />

            <Button onPress={codeForm.handleSubmit(codeValid, codeInvalid)} loading={verifyOtp.isPending}>
              {verifyOtp.isPending ? t('auth.verifying') : t('auth.verify_cta')}
            </Button>
            <Button
              variant="secondary"
              onPress={emailForm.handleSubmit(emailValid, emailInvalid)}
              loading={sendOtp.isPending}
            >
              {t('auth.resend_cta')}
            </Button>
            <Button variant="ghost" onPress={onChangeEmail} disabled={sendOtp.isPending || verifyOtp.isPending}>
              {t('auth.change_email_cta')}
            </Button>
          </>
        ) : (
          <>
            <RHFTextField
              control={emailForm.control}
              name="email"
              label={t('auth.email')}
              keyboardType="email-address"
              autoCapitalize="none"
              placeholder={t('auth.email_placeholder')}
            />

            <View style={{ flex: 1 }} />

            <Button onPress={emailForm.handleSubmit(emailValid, emailInvalid)} loading={sendOtp.isPending}>
              {t('auth.send_code_cta')}
            </Button>
            <Surface variant="muted" className="rounded-2xl px-4 py-3 mt-2">
              <Text variant="muted" className="text-xs text-center">
                {t('auth.terms_notice')}
              </Text>
              <View className="flex-row justify-center gap-4 mt-2">
                <PressScale onPress={openTerms} accessibilityLabel={t('auth.terms_link')}>
                  <Text className="text-xs underline">{t('auth.terms_link')}</Text>
                </PressScale>
                <PressScale onPress={openPrivacy} accessibilityLabel={t('auth.privacy_link')}>
                  <Text className="text-xs underline">{t('auth.privacy_link')}</Text>
                </PressScale>
              </View>
            </Surface>
          </>
        )}
      </ScrollView>
    </Surface>
  );
}
