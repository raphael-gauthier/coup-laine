import { useRef, useMemo } from 'react';
import { View } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { MapPinOff } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Map, type MapHandle } from '@/ui/components/map';
import { ClientPin } from '@/ui/components/client-pin';
import { EmptyState } from '@/ui/components/empty-state';
import { ErrorState } from '@/ui/components/error-state';
import { useClients } from '@/state/queries/clients';
import { useBaseAddress } from '@/state/queries/settings';

export default function MapScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const mapRef = useRef<MapHandle>(null);
  const { data: clients = [], isError, refetch } = useClients('all');
  const { data: base } = useBaseAddress();

  const geocoded = useMemo(
    () => clients.filter((c) => c.latitude != null && c.longitude != null),
    [clients]
  );

  const initialCenter = base ? { lat: base.lat, lon: base.lon } : undefined;

  if (isError) return <ErrorState onRetry={() => refetch()} />;

  if (clients.length === 0) {
    return (
      <Surface className="flex-1">
        <Stack.Screen options={{ title: t('map.title') }} />
        <EmptyState
          icon={<MapPinOff size={48} color="#5C4E40" />}
          title={t('map.empty_title')}
          message={t('map.empty_message')}
        />
      </Surface>
    );
  }

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ title: t('map.title') }} />
      <View className="flex-1">
        <Map ref={mapRef} initialCenter={initialCenter} initialZoom={10}>
          {geocoded.map((client) => (
            <ClientPin
              key={client.id}
              client={client as typeof client & { latitude: number; longitude: number }}
              onPress={() => router.push(`/(tabs)/clients/${client.id}`)}
            />
          ))}
        </Map>
      </View>
    </Surface>
  );
}
