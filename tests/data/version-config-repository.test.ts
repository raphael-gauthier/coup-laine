import * as SecureStore from 'expo-secure-store';
import { getVersionConfig, __resetForTests } from '@/data/repositories/version-config-repository';
import * as api from '@/infra/services/version-check-api';

jest.mock('@/infra/config/env', () => ({
  env: {
    supabaseUrl: 'https://test.supabase.co',
    supabaseAnonKey: 'anon-key',
    maptilerApiKey: 'maptiler-key',
    orsBaseUrl: 'https://test.supabase.co/functions/v1/ors-proxy',
    versionCheckUrl: 'https://test.supabase.co/functions/v1/version-check',
  },
}));

jest.mock('expo-secure-store');

const FRESH_CONFIG = {
  platform: 'ios' as const,
  latestVersion: '0.11.0',
  minSupportedVersion: '0.10.0',
  securityFlag: false,
  releaseNotesFr: null,
  storeUrl: 'https://apps.apple.com/app/id123',
};

describe('versionConfigRepository', () => {
  let store: Record<string, string> = {};

  beforeEach(() => {
    store = {};
    (SecureStore.getItemAsync as jest.Mock).mockImplementation(async (k: string) => store[k] ?? null);
    (SecureStore.setItemAsync as jest.Mock).mockImplementation(async (k: string, v: string) => {
      store[k] = v;
    });
    (SecureStore.deleteItemAsync as jest.Mock).mockImplementation(async (k: string) => {
      delete store[k];
    });
    __resetForTests();
  });

  afterEach(() => jest.restoreAllMocks());

  it('fetch 200 → status fresh, cache written', async () => {
    jest.spyOn(api, 'fetchVersionConfig').mockResolvedValue(FRESH_CONFIG);
    const result = await getVersionConfig('ios');
    expect(result.status).toBe('fresh');
    expect(result.config).toEqual(FRESH_CONFIG);
    expect(store['version-gate.cache.ios']).toBeDefined();
  });

  it('fetch fails + cache exists → status stale', async () => {
    store['version-gate.cache.ios'] = JSON.stringify({ config: FRESH_CONFIG, fetchedAt: Date.now() });
    jest.spyOn(api, 'fetchVersionConfig').mockRejectedValue(new Error('boom'));
    const result = await getVersionConfig('ios');
    expect(result.status).toBe('stale');
    expect(result.config).toEqual(FRESH_CONFIG);
  });

  it('fetch fails + no cache → status unavailable', async () => {
    jest.spyOn(api, 'fetchVersionConfig').mockRejectedValue(new Error('boom'));
    const result = await getVersionConfig('ios');
    expect(result.status).toBe('unavailable');
    expect(result.config).toBeNull();
  });

  it('cache JSON corrupt → ignored, refetch tried', async () => {
    store['version-gate.cache.ios'] = '{not json';
    const apiSpy = jest.spyOn(api, 'fetchVersionConfig').mockResolvedValue(FRESH_CONFIG);
    const result = await getVersionConfig('ios');
    expect(apiSpy).toHaveBeenCalled();
    expect(result.status).toBe('fresh');
  });

  it('cache older than 24h + fetch ok → cache overwritten, status fresh', async () => {
    const stale = Date.now() - 25 * 3600 * 1000;
    store['version-gate.cache.ios'] = JSON.stringify({ config: FRESH_CONFIG, fetchedAt: stale });
    jest.spyOn(api, 'fetchVersionConfig').mockResolvedValue({ ...FRESH_CONFIG, latestVersion: '0.12.0' });
    const result = await getVersionConfig('ios');
    expect(result.status).toBe('fresh');
    expect(result.config?.latestVersion).toBe('0.12.0');
  });

  it('platform 404 → returns the cache if any, else unavailable', async () => {
    jest.spyOn(api, 'fetchVersionConfig').mockResolvedValue(null);
    const result = await getVersionConfig('ios');
    expect(result.status).toBe('unavailable');
    expect(result.config).toBeNull();
  });
});
