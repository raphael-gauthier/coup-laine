import { createTestDb } from './_helpers/test-db';
import { SettingsRepository } from '@/data/repositories/settings-repository';

describe('SettingsRepository', () => {
  it('get returns null for unknown keys', async () => {
    const { db, close } = createTestDb();
    const repo = new SettingsRepository(db);
    expect(await repo.get('unknown')).toBeNull();
    close();
  });

  it('set then get returns value', async () => {
    const { db, close } = createTestDb();
    const repo = new SettingsRepository(db);
    await repo.set('theme_mode', 'dark');
    expect(await repo.get('theme_mode')).toBe('dark');
    close();
  });

  it('set overwrites existing value', async () => {
    const { db, close } = createTestDb();
    const repo = new SettingsRepository(db);
    await repo.set('theme_mode', 'light');
    await repo.set('theme_mode', 'dark');
    expect(await repo.get('theme_mode')).toBe('dark');
    close();
  });

  it('getAll returns a map of all settings', async () => {
    const { db, close } = createTestDb();
    const repo = new SettingsRepository(db);
    await repo.set('a', '1');
    await repo.set('b', '2');
    const all = await repo.getAll();
    expect(all).toEqual({ a: '1', b: '2' });
    close();
  });
});
