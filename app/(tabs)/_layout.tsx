import { Tabs } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Users, Route, Search, Map, Settings } from 'lucide-react-native';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';

const TAB_THEME = {
  light: {
    background: '#FAF6F0',
    border: '#DCD0C0',
    active: '#A1602F',
    inactive: '#5C4E40',
  },
  dark: {
    background: '#16120F',
    border: '#3C322A',
    active: '#C68A58',
    inactive: '#B4A490',
  },
} as const;

export default function TabsLayout() {
  const { t } = useTranslation();
  const scheme = useResolvedColorScheme();
  const c = TAB_THEME[scheme];

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        animation: 'shift',
        tabBarActiveTintColor: c.active,
        tabBarInactiveTintColor: c.inactive,
        tabBarStyle: {
          backgroundColor: c.background,
          borderTopColor: c.border,
          paddingHorizontal: 8,
          paddingBottom: 12,
          height: 72,
        },
        tabBarLabelStyle: { fontWeight: '600' },
      }}
    >
      <Tabs.Screen
        name="clients"
        options={{
          title: t('tabs.clients'),
          tabBarIcon: ({ color, size }) => <Users color={color} size={size} />,
        }}
      />
      <Tabs.Screen
        name="tours"
        options={{
          title: t('tabs.tours'),
          tabBarIcon: ({ color, size }) => <Route color={color} size={size} />,
        }}
      />
      <Tabs.Screen
        name="proximity"
        options={{
          title: t('tabs.proximity'),
          tabBarIcon: ({ color, size }) => <Search color={color} size={size} />,
        }}
      />
      <Tabs.Screen
        name="map/index"
        options={{
          title: t('tabs.map'),
          tabBarIcon: ({ color, size }) => <Map color={color} size={size} />,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: t('tabs.settings'),
          tabBarIcon: ({ color, size }) => <Settings color={color} size={size} />,
        }}
      />
    </Tabs>
  );
}
