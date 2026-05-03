import { View } from 'react-native';
import { Marker } from '@maplibre/maplibre-react-native';
import { cn } from '@/lib/cn';
import type { Client } from '@/domain/models/client';
import { useClientStatusMap } from '@/state/queries/clients';
import { clientStatusColor } from '@/lib/client-status-color';
import { animalsTotal } from '@/lib/animals-total';
import { useAllSettings } from '@/state/queries/settings';
import { Text } from '@/ui/primitives/text';

interface Props {
  client: Client & { latitude: number; longitude: number };
  onPress: () => void;
}

export function ClientPin({ client, onPress }: Props) {
  const { data: statusMap } = useClientStatusMap();
  const { data: settings } = useAllSettings();
  const status = statusMap?.get(client.id) ?? 'default';
  const colors = clientStatusColor(status, settings as Record<string, string | null>);
  const total = animalsTotal(client.animalCounts);

  return (
    <Marker
      id={`pin-${client.id}`}
      lngLat={[client.longitude, client.latitude]}
      anchor="bottom"
      onPress={onPress}
    >
      {colors.bgHex ? (
        <View
          style={{
            width: 28,
            height: 28,
            borderRadius: 14,
            borderWidth: 2,
            borderColor: '#FAF6F0',
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor: colors.bgHex,
          }}
        >
          <Text className="text-xs font-bold" style={{ color: '#FFFFFF' }} allowFontScaling={false}>
            {total}
          </Text>
        </View>
      ) : (
        <View
          className={cn(
            'w-7 h-7 rounded-full border-2 border-background dark:border-background-dark items-center justify-center',
            colors.bgClass
          )}
        >
          <Text className="text-xs font-bold text-white" allowFontScaling={false}>
            {total}
          </Text>
        </View>
      )}
    </Marker>
  );
}
