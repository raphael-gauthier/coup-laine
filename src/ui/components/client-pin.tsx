import { View } from 'react-native';
import { Marker } from '@maplibre/maplibre-react-native';
import { cn } from '@/lib/cn';
import type { Client } from '@/domain/models/client';
import { computeClientStatus } from '@/domain/use-cases/client-status';
import { clientStatusColor } from '@/lib/client-status-color';

interface Props {
  client: Client & { latitude: number; longitude: number };
  onPress: () => void;
  today?: string;
}

export function ClientPin({ client, onPress, today }: Props) {
  const status = computeClientStatus({
    isWaiting: client.isWaiting,
    lastShearingDate: client.lastShearingDate,
    today: today ?? new Date().toISOString().slice(0, 10),
  });
  const colors = clientStatusColor(status);

  return (
    <Marker
      id={`pin-${client.id}`}
      lngLat={[client.longitude, client.latitude]}
      anchor="bottom"
      onPress={onPress}
    >
      <View
        className={cn(
          'w-6 h-6 rounded-full border-2 border-background dark:border-background-dark',
          colors.bgClass
        )}
      />
    </Marker>
  );
}
