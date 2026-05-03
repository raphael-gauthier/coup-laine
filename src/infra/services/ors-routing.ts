import { env } from '@/infra/config/env';
import { supabase } from '@/infra/services/supabase';
import type { Feature, LineString } from 'geojson';

export interface MatrixCoord {
  id: string;
  lat: number;
  lon: number;
}

export interface MatrixResult {
  fromId: string;
  toId: string;
  distanceKm: number;
  durationMinutes: number;
}

async function authHeaders(): Promise<Record<string, string>> {
  const { data } = await supabase.auth.getSession();
  const token = data.session?.access_token;
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export async function fetchDistanceMatrix(
  coords: MatrixCoord[],
  options: { signal?: AbortSignal } = {}
): Promise<MatrixResult[]> {
  // Edge fn is a transparent proxy: POST /ors-proxy/v2/matrix/driving-car
  const url = `${env.orsBaseUrl}/v2/matrix/driving-car`;
  const body = {
    locations: coords.map((c) => [c.lon, c.lat]),
    metrics: ['distance', 'duration'],
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(await authHeaders()),
    },
    body: JSON.stringify(body),
    signal: options.signal,
  });

  if (!response.ok) {
    throw new Error(`ORS error: ${response.status}`);
  }

  const json = (await response.json()) as {
    distances: number[][];
    durations: number[][];
  };

  const result: MatrixResult[] = [];
  for (let i = 0; i < coords.length; i++) {
    for (let j = 0; j < coords.length; j++) {
      if (i === j) continue;
      result.push({
        fromId: coords[i]!.id,
        toId: coords[j]!.id,
        distanceKm: (json.distances[i]?.[j] ?? 0) / 1000,
        durationMinutes: Math.round((json.durations[i]?.[j] ?? 0) / 60),
      });
    }
  }
  return result;
}

export async function fetchRouteGeometry(
  coords: MatrixCoord[],
  options: { signal?: AbortSignal } = {}
): Promise<LineString | null> {
  if (coords.length < 2) return null;
  // Edge fn proxy path: POST /ors-proxy/v2/directions/driving-car/geojson
  const url = `${env.orsBaseUrl}/v2/directions/driving-car/geojson`;
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(await authHeaders()),
      },
      body: JSON.stringify({ coordinates: coords.map((c) => [c.lon, c.lat]) }),
      signal: options.signal,
    });
    if (!response.ok) return null;
    const json = (await response.json()) as { features?: Feature<LineString>[] };
    return json.features?.[0]?.geometry ?? null;
  } catch {
    return null;
  }
}
