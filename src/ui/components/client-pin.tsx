import { View } from 'react-native';
import { Marker } from '@maplibre/maplibre-react-native';
import type { Client } from '@/domain/models/client';
import { useDisplayedStatusMap } from '@/state/queries/clients';
import { animalsTotal } from '@/lib/animals-total';
import { Text } from '@/ui/primitives/text';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';

interface Props {
  client: Client & { latitude: number; longitude: number };
  onPress: () => void;
}

export function ClientPin({ client, onPress }: Props) {
  const { data: map } = useDisplayedStatusMap();
  const scheme = useResolvedColorScheme();
  const status = map?.get(client.id);
  const hex = status ? (scheme === 'dark' ? status.colorDark : status.colorLight) : '#94A3B8';
  const total = animalsTotal(client.animalCounts);

  return (
    <Marker
      id={`pin-${client.id}`}
      lngLat={[client.longitude, client.latitude]}
      anchor="bottom"
      onPress={onPress}
    >
      <View
        style={{
          width: 28,
          height: 28,
          borderRadius: 14,
          borderWidth: 2,
          borderColor: '#FAF6F0',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: hex,
        }}
      >
        <Text className="text-xs font-bold" style={{ color: '#FFFFFF' }} allowFontScaling={false}>
          {total}
        </Text>
      </View>
    </Marker>
  );
}
