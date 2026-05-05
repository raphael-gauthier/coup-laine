import { haversineDistanceKm } from '@/lib/haversine-distance';
import type { Coordinates } from '@/domain/models/coordinates';

interface ClientLite {
  id: string;
  latitude: number | null;
  longitude: number | null;
}

export interface ClientInRadius {
  id: string;
  distanceKm: number;
}

export function findWaitingClientsInRadius(
  anchor: Coordinates,
  clients: ClientLite[],
  radiusKm: number,
): ClientInRadius[] {
  const out: ClientInRadius[] = [];
  for (const c of clients) {
    if (c.latitude == null || c.longitude == null) continue;
    const distanceKm = haversineDistanceKm(anchor, { lat: c.latitude, lon: c.longitude });
    if (distanceKm > radiusKm) continue;
    out.push({ id: c.id, distanceKm });
  }
  out.sort((a, b) => a.distanceKm - b.distanceKm);
  return out;
}
