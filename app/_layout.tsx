import '../global.css';
import '@/i18n';
import { DarkTheme, DefaultTheme, ThemeProvider as NavThemeProvider } from '@react-navigation/native';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider, useResolvedColorScheme } from '@/ui/theme/theme-provider';
import { lightTheme, darkTheme } from '@/ui/theme/tokens';

export const unstable_settings = {
  anchor: 'index',
};

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      retry: 1,
    },
  },
});

function App() {
  const isDark = useResolvedColorScheme() === 'dark';
  return (
    <GestureHandlerRootView style={[{ flex: 1 }, isDark ? darkTheme : lightTheme]}>
      <NavThemeProvider value={isDark ? DarkTheme : DefaultTheme}>
        <Stack screenOptions={{ headerShown: false }}>
          <Stack.Screen name="index" />
          <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        </Stack>
        <StatusBar style="auto" />
      </NavThemeProvider>
    </GestureHandlerRootView>
  );
}

export default function RootLayout() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <App />
      </ThemeProvider>
    </QueryClientProvider>
  );
}
