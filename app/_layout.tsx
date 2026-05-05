import 'react-native-get-random-values';
import '../global.css';
import '@/i18n';
import {
  DarkTheme,
  DefaultTheme,
  ThemeProvider as NavThemeProvider,
} from '@react-navigation/native';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import * as NavigationBar from 'expo-navigation-bar';
import { ActivityIndicator, LogBox, Platform, View } from 'react-native';
import { useEffect, useState } from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider, useResolvedColorScheme } from '@/ui/theme/theme-provider';
import { ToastContainer } from '@/ui/components/toast';
import { bootstrapDatabase } from '@/infra/db/bootstrap';
import { ensureAnonymousSession } from '@/infra/services/ensure-session';
import { useAutoBackup } from '@/state/hooks/use-auto-backup';
import * as Sentry from '@sentry/react-native';

// MapTiler styles include a fake "attribution" vector source with no tiles —
// MapLibre warns "source must have tiles" but the map still renders correctly.
// Silence the cosmetic warning so it doesn't crowd the dev logs.
LogBox.ignoreLogs(['source must have tiles']);

// Keys whose values are PII or domain data that must never reach Sentry.
const PII_KEYS = new Set([
  'email',
  'phone',
  'phones',
  'address',
  'addressLabel',
  'latitude',
  'longitude',
  'displayName',
  'notes',
]);

function scrubPii<T>(value: T, depth = 0): T {
  if (depth > 6 || value == null) return value;
  if (Array.isArray(value)) return value.map((v) => scrubPii(v, depth + 1)) as unknown as T;
  if (typeof value !== 'object') return value;
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
    if (PII_KEYS.has(k) || k.startsWith('client')) {
      out[k] = '[scrubbed]';
    } else {
      out[k] = scrubPii(v, depth + 1);
    }
  }
  return out as T;
}

Sentry.init({
  dsn: 'https://c73c08e2338f9626e0a374a9f92eecfc@o4511336006352896.ingest.de.sentry.io/4511336009302096',
  sendDefaultPii: false,
  enableLogs: __DEV__,
  beforeSend(event) {
    if (event.user) event.user = { id: event.user.id };
    if (event.contexts) event.contexts = scrubPii(event.contexts);
    if (event.extra) event.extra = scrubPii(event.extra);
    if (event.tags) event.tags = scrubPii(event.tags);
    return event;
  },
  beforeBreadcrumb(breadcrumb) {
    if (breadcrumb.data) breadcrumb.data = scrubPii(breadcrumb.data);
    return breadcrumb;
  },
});

export const unstable_settings = {
  anchor: 'index',
};

const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000, retry: 1 } },
});

function App() {
  const isDark = useResolvedColorScheme() === 'dark';

  useAutoBackup();

  useEffect(() => {
    if (Platform.OS === 'android') {
      void NavigationBar.setVisibilityAsync('hidden');
    }
  }, []);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <NavThemeProvider value={isDark ? DarkTheme : DefaultTheme}>
        <Stack screenOptions={{ headerShown: false }}>
          <Stack.Screen name="index" />
          <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
          <Stack.Screen name="onboarding" options={{ headerShown: false, animation: 'fade' }} />
          <Stack.Screen name="auth" options={{ headerShown: false, presentation: 'modal' }} />
        </Stack>
        <ToastContainer />
        <StatusBar
          style="auto"
          translucent={false}
          backgroundColor={isDark ? '#16120F' : '#FAF6F0'}
        />
      </NavThemeProvider>
    </GestureHandlerRootView>
  );
}

export default Sentry.wrap(function RootLayout() {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    bootstrapDatabase()
      .then(() => {
        // Ensure a Supabase session exists (anonymous fallback) so authenticated
        // edge functions like ors-proxy work out of the box. Mirrors the Flutter
        // bootstrap which calls signInAnonymously() when currentSession is null.
        // Don't await — the session can hydrate in the background while the UI
        // mounts; ORS calls are best-effort and already fall back to straight
        // lines if no session is ready.
        void ensureAnonymousSession();
        setReady(true);
      })
      .catch((err) => {
        console.error('DB bootstrap failed', err);
      });
  }, []);

  if (!ready) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator />
      </View>
    );
  }

  return (
    <SafeAreaProvider>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider>
          <App />
        </ThemeProvider>
      </QueryClientProvider>
    </SafeAreaProvider>
  );
});
