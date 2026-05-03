export interface BanResult {
  label: string;
  city: string | null;
  postcode: string | null;
  lat: number;
  lon: number;
}

const BASE_URL = 'https://api-adresse.data.gouv.fr/search';

export async function searchAddresses(
  query: string,
  options: { limit?: number; signal?: AbortSignal } = {}
): Promise<BanResult[]> {
  const trimmed = query.trim();
  if (trimmed.length === 0) return [];

  const params = new URLSearchParams({
    q: trimmed,
    autocomplete: '1',
    limit: String(options.limit ?? 5),
  });

  try {
    const response = await fetch(`${BASE_URL}?${params}`, { signal: options.signal });
    if (!response.ok) return [];
    const json = (await response.json()) as {
      features?: {
        geometry: { coordinates: [number, number] };
        properties: { label: string; city?: string; postcode?: string };
      }[];
    };
    return (json.features ?? []).map((f) => ({
      label: f.properties.label,
      city: f.properties.city ?? null,
      postcode: f.properties.postcode ?? null,
      lat: f.geometry.coordinates[1]!,
      lon: f.geometry.coordinates[0]!,
    }));
  } catch {
    return [];
  }
}
