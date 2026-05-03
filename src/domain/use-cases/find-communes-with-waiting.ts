interface ClientLite {
  id: string;
  isWaiting: boolean;
  addressCity: string | null;
}

export interface CommuneCount {
  city: string;
  count: number;
}

export function findCommunesWithWaiting(clients: ClientLite[]): CommuneCount[] {
  const counts = new Map<string, number>();
  for (const c of clients) {
    if (!c.isWaiting || !c.addressCity) continue;
    counts.set(c.addressCity, (counts.get(c.addressCity) ?? 0) + 1);
  }
  return [...counts.entries()]
    .map(([city, count]) => ({ city, count }))
    .sort((a, b) => b.count - a.count || a.city.localeCompare(b.city, 'fr'));
}
