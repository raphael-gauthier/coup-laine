import { GeoJSONSource, Layer } from '@maplibre/maplibre-react-native';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';

interface Props {
  centerLat: number;
  centerLon: number;
  radiusKm: number;
}

function makeCircleGeoJson(centerLat: number, centerLon: number, radiusKm: number) {
  const points = 64;
  const coords: [number, number][] = [];
  const earthRadiusKm = 6371;
  const radiusRad = radiusKm / earthRadiusKm;
  const latRad = (centerLat * Math.PI) / 180;
  const lonRad = (centerLon * Math.PI) / 180;

  for (let i = 0; i <= points; i++) {
    const bearing = (i * 2 * Math.PI) / points;
    const lat = Math.asin(
      Math.sin(latRad) * Math.cos(radiusRad) +
        Math.cos(latRad) * Math.sin(radiusRad) * Math.cos(bearing)
    );
    const lon =
      lonRad +
      Math.atan2(
        Math.sin(bearing) * Math.sin(radiusRad) * Math.cos(latRad),
        Math.cos(radiusRad) - Math.sin(latRad) * Math.sin(lat)
      );
    coords.push([(lon * 180) / Math.PI, (lat * 180) / Math.PI]);
  }
  return {
    type: 'Feature' as const,
    geometry: { type: 'Polygon' as const, coordinates: [coords] },
    properties: {},
  };
}

const COLORS = {
  light: { fill: '#A1602F', opacity: 0.15, line: '#A1602F' },
  dark: { fill: '#C68A58', opacity: 0.2, line: '#C68A58' },
};

export function ProximityCircle({ centerLat, centerLon, radiusKm }: Props) {
  const scheme = useResolvedColorScheme();
  const c = COLORS[scheme];
  const feature = makeCircleGeoJson(centerLat, centerLon, radiusKm);

  return (
    <GeoJSONSource id="proximity-circle" data={feature}>
      <Layer
        id="proximity-circle-fill"
        type="fill"
        paint={{ 'fill-color': c.fill, 'fill-opacity': c.opacity }}
      />
      <Layer
        id="proximity-circle-line"
        type="line"
        paint={{ 'line-color': c.line, 'line-width': 1.5, 'line-opacity': 0.6 }}
      />
    </GeoJSONSource>
  );
}
