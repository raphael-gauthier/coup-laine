import type { Coordinates } from '@/domain/models/coordinates';

interface ClientLite {
  addressCity: string | null;
  latitude: number | null;
  longitude: number | null;
}

export function computeCommuneAnchor(
  communeName: string,
  clients: ClientLite[],
): Coordinates | null {
  let sumLat = 0;
  let sumLon = 0;
  let n = 0;
  for (const c of clients) {
    if (c.addressCity !== communeName) continue;
    if (c.latitude == null || c.longitude == null) continue;
    sumLat += c.latitude;
    sumLon += c.longitude;
    n += 1;
  }
  if (n === 0) return null;
  return { lat: sumLat / n, lon: sumLon / n };
}
