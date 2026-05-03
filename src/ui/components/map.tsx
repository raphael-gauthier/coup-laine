import { forwardRef, useImperativeHandle, useRef } from 'react';
import { StyleSheet } from 'react-native';
import {
  Map as MapLibreMap,
  Camera,
  type CameraRef,
} from '@maplibre/maplibre-react-native';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';
import { styleForScheme } from '@/ui/theme/map-style';
import type { ReactNode } from 'react';

export interface MapHandle {
  flyTo: (lon: number, lat: number, zoom?: number) => void;
}

interface Props {
  initialCenter?: { lat: number; lon: number };
  initialZoom?: number;
  onPress?: (lon: number, lat: number) => void;
  children?: ReactNode;
}

const FALLBACK_CENTER = { lat: 48.0, lon: -3.0 };
const FALLBACK_ZOOM = 9;

export const Map = forwardRef<MapHandle, Props>(function Map(
  { initialCenter, initialZoom, onPress, children },
  ref
) {
  const scheme = useResolvedColorScheme();
  const cameraRef = useRef<CameraRef>(null);
  const center = initialCenter ?? FALLBACK_CENTER;
  const zoom = initialZoom ?? FALLBACK_ZOOM;

  useImperativeHandle(ref, () => ({
    flyTo(lon, lat, z = 12) {
      cameraRef.current?.flyTo({
        center: [lon, lat],
        zoom: z,
        duration: 600,
      });
    },
  }));

  return (
    <MapLibreMap
      style={styles.map}
      mapStyle={styleForScheme(scheme)}
      onPress={(event) => {
        const [lon, lat] = event.nativeEvent.lngLat;
        onPress?.(lon, lat);
      }}
    >
      <Camera
        ref={cameraRef}
        initialViewState={{
          center: [center.lon, center.lat],
          zoom,
        }}
      />
      {children}
    </MapLibreMap>
  );
});

const styles = StyleSheet.create({
  map: { flex: 1 },
});
