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

interface PairResult {
  forward: { distanceKm: number; durationMinutes: number };
  reverse: { distanceKm: number; durationMinutes: number };
}

/**
 * Fetch BASE↔client road distances. Returns both directions.
 * Throws on network/ORS error so the caller can mark as failed.
 */
export async function fetchPairFromBase(
  base: { lat: number; lon: number },
  client: { lat: number; lon: number },
  options: { signal?: AbortSignal } = {}
): Promise<PairResult> {
  const matrix = await fetchDistanceMatrix(
    [
      { id: 'BASE', lat: base.lat, lon: base.lon },
      { id: 'CLIENT', lat: client.lat, lon: client.lon },
    ],
    options
  );
  const forward = matrix.find((r) => r.fromId === 'BASE' && r.toId === 'CLIENT');
  const reverse = matrix.find((r) => r.fromId === 'CLIENT' && r.toId === 'BASE');
  if (!forward || !reverse) throw new Error('Incomplete matrix response');
  return {
    forward: { distanceKm: forward.distanceKm, durationMinutes: forward.durationMinutes },
    reverse: { distanceKm: reverse.distanceKm, durationMinutes: reverse.durationMinutes },
  };
}

export async function fetchRouteGeometry(
  coords: MatrixCoord[],
  options: { signal?: AbortSignal } = {}
): Promise<LineString | null> {
  if (coords.length < 2) return null;
  // Edge fn proxy path: POST /ors-proxy/v2/directions/driving-car/geojson
  const url = `${env.orsBaseUrl}/v2/directions/driving-car/geojson`;
  const headers = await authHeaders();
  if (__DEV__) {
     
    console.log('[ors] fetchRouteGeometry', {
      url,
      hasAuth: 'Authorization' in headers,
      coordsCount: coords.length,
    });
  }
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...headers,
      },
      body: JSON.stringify({ coordinates: coords.map((c) => [c.lon, c.lat]) }),
      signal: options.signal,
    });
    if (!response.ok) {
      if (__DEV__) {
        const text = await response.text().catch(() => '<no body>');
         
        console.warn('[ors] fetchRouteGeometry not ok', response.status, text.slice(0, 500));
      }
      return null;
    }
    const json = (await response.json()) as { features?: Feature<LineString>[] };
    return json.features?.[0]?.geometry ?? null;
  } catch (err) {
    if (__DEV__) {
       
      console.warn('[ors] fetchRouteGeometry threw', err instanceof Error ? err.message : String(err));
    }
    return null;
  }
}
