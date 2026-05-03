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
  /** Optional: caller can supply a road-distance lookup (e.g., ORS matrix). Falls back to haversine. */
  distanceKm?: (fromAnchorId: string, toClientId: string) => number | null;
}

export interface NearbyClient {
  id: string;
  distanceKm: number;
  isEstimate: boolean;
}

export function findClientsNearAnchors({ anchors, radiusKm, clients, distanceKm }: Input): NearbyClient[] {
  if (radiusKm <= 0) throw new Error('radiusKm must be positive');
  const anchorIds = new Set(anchors.map((a) => a.id));

  const result: NearbyClient[] = [];
  for (const c of clients) {
    if (anchorIds.has(c.id)) continue;
    if (c.lat == null || c.lon == null) continue;

    let minDistance = Infinity;
    let minIsEstimate = false;
    for (const a of anchors) {
      let d: number | null = distanceKm ? distanceKm(a.id, c.id) : null;
      let isEst = false;
      if (d == null) {
        d = haversineDistanceKm({ lat: a.lat, lon: a.lon }, { lat: c.lat, lon: c.lon });
        isEst = true;
      }
      if (d < minDistance) {
        minDistance = d;
        minIsEstimate = isEst;
      }
    }
    if (minDistance <= radiusKm) {
      result.push({ id: c.id, distanceKm: minDistance, isEstimate: minIsEstimate });
    }
  }
  return result.sort((a, b) => a.distanceKm - b.distanceKm);
}
