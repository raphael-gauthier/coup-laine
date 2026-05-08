import { createTestDb } from './_helpers/test-db';
import { StatusRepository } from '@/data/repositories/status-repository';

describe('StatusRepository', () => {
  it('lists 6 system rows after migration, ordered by sortOrder', async () => {
    const { db, close } = createTestDb();
    const repo = new StatusRepository(db);
    const rows = await repo.list();
    expect(rows.map((r) => r.systemKey)).toEqual([
      'default', 'waiting', 'scheduled', 'done', 'noAnimals', 'banned',
    ]);
    close();
  });

  it('createManual assigns sortOrder = max + 10', async () => {
    const { db, close } = createTestDb();
    const repo = new StatusRepository(db);
    const m = await repo.createManual({
      label: 'VIP', colorLight: '#FF0000', colorDark: '#FFAAAA',
    });
    expect(m.kind).toBe('manual');
    expect(m.sortOrder).toBe(70);
    close();
  });

  it('update changes label and colors', async () => {
    const { db, close } = createTestDb();
    const repo = new StatusRepository(db);
    const m = await repo.createManual({
      label: 'A', colorLight: '#000000', colorDark: '#FFFFFF',
    });
    const after = await repo.update(m.id, { label: 'B', colorLight: '#111111' });
    expect(after.label).toBe('B');
    expect(after.colorLight).toBe('#111111');
    expect(after.colorDark).toBe('#FFFFFF');
    close();
  });

  it('deleteManual throws on system row', async () => {
    const { db, close } = createTestDb();
    const repo = new StatusRepository(db);
    const sys = (await repo.list()).find((r) => r.systemKey === 'waiting')!;
    await expect(repo.deleteManual(sys.id)).rejects.toThrow();
    close();
  });

  it('deleteManual removes manual row', async () => {
    const { db, close } = createTestDb();
    const repo = new StatusRepository(db);
    const m = await repo.createManual({ label: 'X', colorLight: '#000000', colorDark: '#FFFFFF' });
    await repo.deleteManual(m.id);
    expect(await repo.byId(m.id)).toBeNull();
    close();
  });

  it('countClientsUsing returns 0 when nobody references it', async () => {
    const { db, close } = createTestDb();
    const repo = new StatusRepository(db);
    const m = await repo.createManual({ label: 'X', colorLight: '#000000', colorDark: '#FFFFFF' });
    expect(await repo.countClientsUsing(m.id)).toBe(0);
    close();
  });
});
