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
}

export interface NearbyClient {
  id: string;
  distanceKm: number;
}

export function findNearbyClients({ pivot, radiusKm, clients }: Input): NearbyClient[] {
  if (radiusKm <= 0) {
    throw new Error('radiusKm must be positive');
  }
  const result: NearbyClient[] = [];
  for (const c of clients) {
    if (c.id === pivot.id) continue;
    if (c.lat == null || c.lon == null) continue;
    const distanceKm = haversineDistanceKm(
      { lat: pivot.lat, lon: pivot.lon },
      { lat: c.lat, lon: c.lon }
    );
    if (distanceKm <= radiusKm) {
      result.push({ id: c.id, distanceKm });
    }
  }
  return result.sort((a, b) => a.distanceKm - b.distanceKm);
}
