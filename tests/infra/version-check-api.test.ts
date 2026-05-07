import { fetchVersionConfig } from '@/infra/services/version-check-api';

jest.mock('@/infra/config/env', () => ({
  env: {
    supabaseUrl: 'https://test.supabase.co',
    supabaseAnonKey: 'anon-key',
    maptilerApiKey: 'maptiler-key',
    orsBaseUrl: 'https://test.supabase.co/functions/v1/ors-proxy',
  },
}));

describe('fetchVersionConfig', () => {
  afterEach(() => jest.restoreAllMocks());

  it('passes platform query param and parses 200 payload', async () => {
    const fetchSpy = jest.spyOn(global, 'fetch').mockImplementation(
      async () =>
        new Response(
          JSON.stringify({
            platform: 'ios',
            latestVersion: '0.11.0',
            minSupportedVersion: '0.10.0',
            securityFlag: false,
            releaseNotesFr: '- Notes',
            storeUrl: 'https://apps.apple.com/app/id123',
          }),
          { status: 200, headers: { 'Content-Type': 'application/json' } },
        ),
    );

    const result = await fetchVersionConfig('ios');
    expect(result).toEqual({
      platform: 'ios',
      latestVersion: '0.11.0',
      minSupportedVersion: '0.10.0',
      securityFlag: false,
      releaseNotesFr: '- Notes',
      storeUrl: 'https://apps.apple.com/app/id123',
    });

    const calledUrl = fetchSpy.mock.calls[0]?.[0];
    expect(String(calledUrl)).toBe(
      'https://test.supabase.co/functions/v1/version-check?platform=ios',
    );
  });

  it('returns null on 404', async () => {
    jest.spyOn(global, 'fetch').mockImplementation(
      async () => new Response(JSON.stringify({ error: 'Platform not configured' }), { status: 404 }),
    );
    expect(await fetchVersionConfig('android')).toBeNull();
  });

  it('throws on 500', async () => {
    jest.spyOn(global, 'fetch').mockImplementation(
      async () => new Response('boom', { status: 500 }),
    );
    await expect(fetchVersionConfig('ios')).rejects.toThrow(/500/);
  });

  it('throws when JSON shape is invalid', async () => {
    jest.spyOn(global, 'fetch').mockImplementation(
      async () => new Response(JSON.stringify({ hello: 'world' }), { status: 200 }),
    );
    await expect(fetchVersionConfig('ios')).rejects.toThrow(/invalid/i);
  });
});
