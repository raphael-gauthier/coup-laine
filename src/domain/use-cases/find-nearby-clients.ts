import { haversineDistanceKm } from '@/lib/haversine-distance';

interface ClientPoint {
  id: string;
  lat: number | null;
  lon: number | null;
}

interface Pivot {
  id: string;
  lat: number;
  lon: number;
}

interface Input {
  pivot: Pivot;
  radiusKm: number;
  clients: ClientPoint[];
  /** Optional: caller can supply a road-distance lookup (e.g., ORS matrix). Falls back to haversine. */
  distanceKm?: (fromId: string, toId: string) => number | null;
}

export interface NearbyClient {
  id: string;
  distanceKm: number;
  isEstimate: boolean;
}

export function findNearbyClients({ pivot, radiusKm, clients, distanceKm }: Input): NearbyClient[] {
  if (radiusKm <= 0) {
    throw new Error('radiusKm must be positive');
  }
  const result: NearbyClient[] = [];
  for (const c of clients) {
    if (c.id === pivot.id) continue;
    if (c.lat == null || c.lon == null) continue;
    let resolved: number | null = distanceKm ? distanceKm(pivot.id, c.id) : null;
    let isEstimate = false;
    if (resolved == null) {
      resolved = haversineDistanceKm({ lat: pivot.lat, lon: pivot.lon }, { lat: c.lat, lon: c.lon });
      isEstimate = true;
    }
    if (resolved <= radiusKm) {
      result.push({ id: c.id, distanceKm: resolved, isEstimate });
    }
  }
  return result.sort((a, b) => a.distanceKm - b.distanceKm);
}
