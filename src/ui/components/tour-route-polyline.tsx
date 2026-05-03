import { useEffect, useState } from 'react';
import { GeoJSONSource, Layer } from '@maplibre/maplibre-react-native';
import type { Feature, LineString } from 'geojson';
import { fetchRouteGeometry, type MatrixCoord } from '@/infra/services/ors-routing';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';

interface Props {
  coords: MatrixCoord[];
}

const COLORS = {
  light: '#A1602F',
  dark: '#C68A58',
};

export function TourRoutePolyline({ coords }: Props) {
  const scheme = useResolvedColorScheme();
  const [geometry, setGeometry] = useState<LineString | null>(null);

  useEffect(() => {
    if (coords.length < 2) {
      setGeometry(null);
      return;
    }
    let cancelled = false;
    void fetchRouteGeometry(coords).then((g) => {
      if (!cancelled) setGeometry(g);
    });
    return () => {
      cancelled = true;
    };
  }, [coords]);

  if (!geometry) return null;

  const feature: Feature<LineString> = {
    type: 'Feature',
    geometry,
    properties: {},
  };

  return (
    <GeoJSONSource id="tour-route" data={feature}>
      <Layer
        id="tour-route-line"
        type="line"
        paint={{
          'line-color': COLORS[scheme],
          'line-width': 3,
          'line-opacity': 0.8,
        }}
      />
    </GeoJSONSource>
  );
}
