import { createTestDb } from './_helpers/test-db';
import { DistanceMatrixRepository } from '@/data/repositories/distance-matrix-repository';

describe('DistanceMatrixRepository', () => {
  it('upserts and reads pairs', async () => {
    const { db, close } = createTestDb();
    const repo = new DistanceMatrixRepository(db);
    await repo.upsert({ fromId: 'BASE', toId: 'c1', distanceKm: 12.4, durationMinutes: 18, fetchedAt: '2026-05-03T12:00:00Z' });
    const r = await repo.byPair('BASE', 'c1');
    expect(r?.distanceKm).toBe(12.4);
    close();
  });

  it('deletes entries older than a date', async () => {
    const { db, close } = createTestDb();
    const repo = new DistanceMatrixRepository(db);
    await repo.upsert({ fromId: 'BASE', toId: 'a', distanceKm: 1, durationMinutes: 1, fetchedAt: '2026-01-01T00:00:00Z' });
    await repo.upsert({ fromId: 'BASE', toId: 'b', distanceKm: 1, durationMinutes: 1, fetchedAt: '2026-04-01T00:00:00Z' });
    await repo.deleteOlderThan('2026-03-01T00:00:00Z');
    expect(await repo.byPair('BASE', 'a')).toBeNull();
    expect(await repo.byPair('BASE', 'b')).not.toBeNull();
    close();
  });
});
