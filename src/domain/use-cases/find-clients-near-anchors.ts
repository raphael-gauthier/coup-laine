import { haversineDistanceKm } from '@/lib/haversine-distance';

interface Anchor {
  id: string;
  lat: number;
  lon: number;
}

interface ClientPoint {
  id: string;
  lat: number | null;
  lon: number | null;
}

interface Input {
  anchors: Anchor[];
  radiusKm: number;
  clients: ClientPoint[];
}

export interface NearbyClient {
  id: string;
  distanceKm: number;
}

export function findClientsNearAnchors({ anchors, radiusKm, clients }: Input): NearbyClient[] {
  if (radiusKm <= 0) throw new Error('radiusKm must be positive');
  const anchorIds = new Set(anchors.map((a) => a.id));

  const result: NearbyClient[] = [];
  for (const c of clients) {
    if (anchorIds.has(c.id)) continue;
    if (c.lat == null || c.lon == null) continue;

    let minDistance = Infinity;
    for (const a of anchors) {
      const d = haversineDistanceKm({ lat: a.lat, lon: a.lon }, { lat: c.lat, lon: c.lon });
      if (d < minDistance) minDistance = d;
    }
    if (minDistance <= radiusKm) {
      result.push({ id: c.id, distanceKm: minDistance });
    }
  }
  return result.sort((a, b) => a.distanceKm - b.distanceKm);
}
