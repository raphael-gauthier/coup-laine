import { View } from 'react-native';
import { Marker } from '@maplibre/maplibre-react-native';
import { Home } from 'lucide-react-native';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';

interface Props {
  lat: number;
  lon: number;
  onPress?: () => void;
}

const ICON_COLOR = { light: '#A1602F', dark: '#C68A58' };

export function BasePin({ lat, lon, onPress }: Props) {
  const scheme = useResolvedColorScheme();

  return (
    <Marker
      id="base-pin"
      lngLat={[lon, lat]}
      anchor="bottom"
      onPress={onPress}
    >
      <View
        className="rounded-full p-2 bg-background dark:bg-background-dark"
        style={{ shadowColor: '#000', shadowOpacity: 0.2, shadowRadius: 4, shadowOffset: { width: 0, height: 2 }, elevation: 4 }}
      >
        <Home size={18} color={ICON_COLOR[scheme]} />
      </View>
    </Marker>
  );
}
