import { Tabs } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Users, Route, Search, Map, Settings } from 'lucide-react-native';

export default function TabsLayout() {
  const { t } = useTranslation();
  return (
    <Tabs screenOptions={{ headerShown: false, animation: 'shift' }}>
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
