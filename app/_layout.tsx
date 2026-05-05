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

// MapTiler styles include a fake "attribution" vector source with no tiles —
// MapLibre warns "source must have tiles" but the map still renders correctly.
// Silence the cosmetic warning so it doesn't crowd the dev logs.
LogBox.ignoreLogs(['source must have tiles']);
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider, useResolvedColorScheme } from '@/ui/theme/theme-provider';
import { ToastContainer } from '@/ui/components/toast';
import { bootstrapDatabase } from '@/infra/db/bootstrap';
import { ensureAnonymousSession } from '@/infra/services/ensure-session';
import { useAutoBackup } from '@/state/hooks/use-auto-backup';
import * as Sentry from '@sentry/react-native';

Sentry.init({
  dsn: 'https://c73c08e2338f9626e0a374a9f92eecfc@o4511336006352896.ingest.de.sentry.io/4511336009302096',

  // Adds more context data to events (IP address, cookies, user, etc.)
  // For more information, visit: https://docs.sentry.io/platforms/react-native/data-management/data-collected/
  sendDefaultPii: true,

  // Enable Logs
  enableLogs: true,

  // uncomment the line below to enable Spotlight (https://spotlightjs.com)
  // spotlight: __DEV__,
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
