import type { MapBounds } from './map';

interface Coord {
  lat: number;
  lon: number;
}

const SINGLE_POINT_DELTA = 0.01;

export function computeBounds(coords: Coord[], padding = 40): MapBounds | null {
  if (coords.length === 0) return null;

  let minLat = coords[0]!.lat;
  let maxLat = coords[0]!.lat;
  let minLon = coords[0]!.lon;
  let maxLon = coords[0]!.lon;

  for (const c of coords) {
    if (c.lat < minLat) minLat = c.lat;
    if (c.lat > maxLat) maxLat = c.lat;
    if (c.lon < minLon) minLon = c.lon;
    if (c.lon > maxLon) maxLon = c.lon;
  }

  if (minLat === maxLat && minLon === maxLon) {
    minLat -= SINGLE_POINT_DELTA;
    maxLat += SINGLE_POINT_DELTA;
    minLon -= SINGLE_POINT_DELTA;
    maxLon += SINGLE_POINT_DELTA;
  }

  return {
    ne: [maxLon, maxLat],
    sw: [minLon, minLat],
    padding,
  };
}
