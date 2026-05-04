import 'react-native-get-random-values';
import '../global.css';
import '@/i18n';
import { DarkTheme, DefaultTheme, ThemeProvider as NavThemeProvider } from '@react-navigation/native';
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

export const unstable_settings = {
  anchor: 'index',
};

const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000, retry: 1 } },
});

function App() {
  const isDark = useResolvedColorScheme() === 'dark';

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
        <StatusBar style="auto" translucent={false} backgroundColor={isDark ? '#16120F' : '#FAF6F0'} />
      </NavThemeProvider>
    </GestureHandlerRootView>
  );
}

export default function RootLayout() {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    bootstrapDatabase()
      .then(() => setReady(true))
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
}
