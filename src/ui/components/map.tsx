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

export interface MapBounds {
  ne: [number, number]; // [lon, lat]
  sw: [number, number]; // [lon, lat]
  padding?: number; // points; applied to all sides
}

export interface MapHandle {
  flyTo: (lon: number, lat: number, zoom?: number) => void;
  fitBounds: (bounds: MapBounds, animationDuration?: number) => void;
}

interface Props {
  initialCenter?: { lat: number; lon: number };
  initialZoom?: number;
  bounds?: MapBounds;
  interactive?: boolean;
  onPress?: (lon: number, lat: number) => void;
  children?: ReactNode;
}

const FALLBACK_CENTER = { lat: 48.0, lon: -3.0 };
const FALLBACK_ZOOM = 9;

function toLngLatBounds(b: MapBounds): [number, number, number, number] {
  return [b.sw[0], b.sw[1], b.ne[0], b.ne[1]];
}

function toViewPadding(padding: number) {
  return { top: padding, right: padding, bottom: padding, left: padding };
}

export const Map = forwardRef<MapHandle, Props>(function Map(
  { initialCenter, initialZoom, bounds, interactive = true, onPress, children },
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
    fitBounds(b, animationDuration = 600) {
      cameraRef.current?.fitBounds(toLngLatBounds(b), {
        padding: toViewPadding(b.padding ?? 40),
        duration: animationDuration,
      });
    },
  }));

  const initialViewState = bounds
    ? {
        bounds: toLngLatBounds(bounds),
        padding: toViewPadding(bounds.padding ?? 40),
      }
    : { center: [center.lon, center.lat] as [number, number], zoom };

  return (
    <MapLibreMap
      style={styles.map}
      mapStyle={styleForScheme(scheme)}
      dragPan={interactive}
      touchZoom={interactive}
      touchRotate={interactive}
      touchPitch={interactive}
      doubleTapZoom={interactive}
      doubleTapHoldZoom={interactive}
      attribution={interactive}
      logo={false}
      compass={false}
      onPress={(event) => {
        if (!interactive) return;
        const [lon, lat] = event.nativeEvent.lngLat;
        onPress?.(lon, lat);
      }}
    >
      <Camera ref={cameraRef} initialViewState={initialViewState} />
      {children}
    </MapLibreMap>
  );
});

const styles = StyleSheet.create({
  map: { flex: 1 },
});
