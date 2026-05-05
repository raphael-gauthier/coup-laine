import * as Sentry from '@sentry/react-native';
import { supabase } from './supabase';

let inFlight: Promise<void> | null = null;

/**
 * Make sure the Supabase client has a session (anonymous if no real user has
 * signed in). Mirrors the Flutter behaviour where the SDK auto-creates an
 * anonymous session, which is required for our authenticated edge functions
 * (ors-proxy, etc.). Idempotent and de-duped — concurrent callers share a
 * single in-flight promise.
 */
export async function ensureAnonymousSession(): Promise<void> {
  if (inFlight) return inFlight;
  inFlight = (async () => {
    try {
      const { data } = await supabase.auth.getSession();
      if (data.session) return;
      const { error } = await supabase.auth.signInAnonymously();
      if (error) {
        if (__DEV__) {
          // eslint-disable-next-line no-console
          console.warn('[auth] anonymous sign-in failed', error.message);
        }
        Sentry.captureException(error, { tags: { context: 'ensureAnonymousSession' } });
      }
    } finally {
      inFlight = null;
    }
  })();
  return inFlight;
}
