import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';
import { supabase } from '@/infra/services/supabase';
import { errorToast } from '@/ui/components/error-toast';
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

export function useSignInOtp() {
  return useMutation({
    mutationFn: async (email: string) => {
      const { error } = await supabase.auth.signInWithOtp({
        email,
        options: { emailRedirectTo: 'coupelaine://auth/callback' },
      });
      if (error) throw error;
    },
    onError: (err) => {
      errorToast('Envoi impossible', err instanceof Error ? err.message : undefined);
    },
  });
}

export function useSignOut() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
    },
    onSuccess: () => {
      qc.setQueryData(authKeys.session, null);
    },
    onError: (err) => {
      errorToast('Déconnexion impossible', err instanceof Error ? err.message : undefined);
    },
  });
}
