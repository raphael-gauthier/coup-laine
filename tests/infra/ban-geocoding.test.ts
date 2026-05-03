import { searchAddresses } from '@/infra/services/ban-geocoding';
import banFixture from './_fixtures/ban-search.json';

function mockFetchOk(body: unknown) {
  return jest.spyOn(global, 'fetch').mockResolvedValueOnce(
    new Response(JSON.stringify(body), { status: 200 })
  );
}

function mockFetchError() {
  return jest.spyOn(global, 'fetch').mockRejectedValueOnce(new TypeError('Network error'));
}

afterEach(() => jest.restoreAllMocks());

describe('searchAddresses', () => {
  it('returns parsed BAN results', async () => {
    mockFetchOk(banFixture);
    const r = await searchAddresses('tonte');
    expect(r).toHaveLength(2);
    expect(r[0]).toMatchObject({
      label: '1 Rue de la Tonte 29000 Quimper',
      city: 'Quimper',
      postcode: '29000',
      lat: 48.0019,
      lon: -4.0975,
    });
  });

  it('returns empty array for empty query', async () => {
    expect(await searchAddresses('')).toEqual([]);
  });

  it('returns empty array on network error', async () => {
    mockFetchError();
    expect(await searchAddresses('foo')).toEqual([]);
  });
});
