import { fetchDistanceMatrix } from '@/infra/services/ors-routing';

jest.mock('@/infra/config/env', () => ({
  env: {
    supabaseUrl: 'https://test.supabase.co',
    supabaseAnonKey: 'anon-key',
    maptilerApiKey: 'maptiler-key',
    orsBaseUrl: 'https://test.supabase.co/functions/v1/ors-proxy',
  },
}));

jest.mock('@/infra/services/supabase', () => ({
  supabase: {
    auth: {
      getSession: () => Promise.resolve({ data: { session: { access_token: 'token' } } }),
    },
  },
}));

describe('fetchDistanceMatrix', () => {
  beforeEach(() => {
    jest.spyOn(global, 'fetch').mockImplementation(
      async () =>
        new Response(
          JSON.stringify({
            distances: [
              [0, 12000, 25000],
              [12500, 0, 18000],
              [26000, 18500, 0],
            ],
            durations: [
              [0, 900, 1800],
              [950, 0, 1200],
              [1900, 1250, 0],
            ],
          }),
          { status: 200 }
        )
    );
  });

  afterEach(() => jest.restoreAllMocks());

  it('parses meters → km, seconds → minutes; produces N*(N-1) pairs', async () => {
    const result = await fetchDistanceMatrix([
      { id: 'BASE', lat: 48.0, lon: -3.0 },
      { id: 'c1', lat: 48.1, lon: -3.0 },
      { id: 'c2', lat: 48.2, lon: -3.0 },
    ]);
    expect(result).toHaveLength(6);
    const baseToC1 = result.find((r) => r.fromId === 'BASE' && r.toId === 'c1');
    expect(baseToC1?.distanceKm).toBe(12);
    expect(baseToC1?.durationMinutes).toBe(15);
  });
});
