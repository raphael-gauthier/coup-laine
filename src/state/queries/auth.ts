import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';
import { supabase } from '@/infra/services/supabase';
import { errorToast, mutationErrorToast } from '@/ui/components/error-toast';
import { wipeLocalDatabase } from '@/infra/db/wipe';
import { bootstrapDatabase } from '@/infra/db/bootstrap';
import i18n from '@/i18n';
import type { Session } from '@supabase/supabase-js';

export const authKeys = {
  session: ['auth', 'session'] as const,
};

export function useSession() {
  const qc = useQueryClient();

  useEffect(() => {
    const { data: subscription } = supabase.auth.onAuthStateChange((_event, session) => {
      qc.setQueryData(authKeys.session, session);
    });
    return () => {
      subscription.subscription.unsubscribe();
    };
  }, [qc]);

  return useQuery<Session | null>({
    queryKey: authKeys.session,
    queryFn: async () => {
      const { data } = await supabase.auth.getSession();
      return data.session;
    },
    staleTime: Infinity,
  });
}

export type OtpKind = 'email' | 'email_change';

export interface SendOtpResult {
  /** Which verifyOtp `type` the caller must use to confirm the code. */
  kind: OtpKind;
}

/**
 * Sends a 6-digit OTP code by email. If the current Supabase session is
 * anonymous, the code links the new email to that anonymous user (preserving
 * the user id and any cloud data). Otherwise it triggers a normal sign-in /
 * sign-up flow.
 */
export function useSendOtp() {
  return useMutation<SendOtpResult, Error, string>({
    mutationFn: async (email) => {
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user.is_anonymous) {
        const { error } = await supabase.auth.updateUser({ email });
        if (!error) return { kind: 'email_change' };
        // Email already belongs to an existing account: drop the anonymous
        // session and send a regular sign-in OTP to that account instead.
        const conflict = error.code === 'email_exists' || error.status === 422;
        if (!conflict) throw error;
        await supabase.auth.signOut();
        const { error: otpError } = await supabase.auth.signInWithOtp({ email });
        if (otpError) throw otpError;
        errorToast(
          i18n.t('auth.errors.email_already_used_title'),
          i18n.t('auth.errors.email_already_used_message'),
        );
        return { kind: 'email' };
      }
      const { error } = await supabase.auth.signInWithOtp({ email });
      if (error) throw error;
      return { kind: 'email' };
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('auth.errors.send_failed_title'), err);
    },
  });
}

export interface VerifyOtpInput {
  email: string;
  token: string;
  kind: OtpKind;
}

export function useVerifyOtp() {
  return useMutation<Session, Error, VerifyOtpInput>({
    mutationFn: async ({ email, token, kind }) => {
      const { data, error } = await supabase.auth.verifyOtp({ email, token, type: kind });
      if (error) throw error;
      if (!data.session) throw new Error('No session returned after OTP verification');
      return data.session;
    },
    onError: (err) => {
      mutationErrorToast(
        i18n.t('auth.errors.code_invalid_title'),
        err,
        i18n.t('auth.errors.code_invalid_message'),
      );
    },
  });
}

export function useSignOut() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      // Privacy: erase the previous user's local data before the next account
      // signs in on this device. Re-bootstrap so default catalog seeds exist.
      await wipeLocalDatabase();
      await bootstrapDatabase();
    },
    onSuccess: () => {
      qc.clear();
      qc.setQueryData(authKeys.session, null);
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('auth.errors.signout_failed_title'), err);
    },
  });
}
