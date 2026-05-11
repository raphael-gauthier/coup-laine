import { describe, it, expect } from '@jest/globals';
import { createTestDb } from './_helpers/test-db';
import { TutorialProgressRepository } from '@/data/repositories/tutorial-progress-repository';
import { TUTORIAL_KEYS } from '@/domain/tutorial/keys';

const NOW = '2026-05-11T10:00:00.000Z';
const LATER = '2026-05-11T11:00:00.000Z';

describe('TutorialProgressRepository', () => {
  it('list returns empty on a fresh DB', async () => {
    const { db, close } = createTestDb();
    const repo = new TutorialProgressRepository(db);
    expect(await repo.list()).toEqual([]);
    close();
  });

  it('markSeen inserts a row', async () => {
    const { db, close } = createTestDb();
    const repo = new TutorialProgressRepository(db);
    await repo.markSeen(TUTORIAL_KEYS.sheetClients, NOW);
    const rows = await repo.list();
    expect(rows).toEqual([{ key: 'sheet.clients', seenAt: NOW }]);
    close();
  });

  it('markSeen is idempotent (second call does not duplicate or update seenAt)', async () => {
    const { db, close } = createTestDb();
    const repo = new TutorialProgressRepository(db);
    await repo.markSeen(TUTORIAL_KEYS.sheetClients, NOW);
    await repo.markSeen(TUTORIAL_KEYS.sheetClients, LATER);
    const rows = await repo.list();
    expect(rows).toHaveLength(1);
    expect(rows[0]?.seenAt).toBe(NOW);
    close();
  });

  it('isSeen returns true after markSeen, false otherwise', async () => {
    const { db, close } = createTestDb();
    const repo = new TutorialProgressRepository(db);
    expect(await repo.isSeen(TUTORIAL_KEYS.sheetClients)).toBe(false);
    await repo.markSeen(TUTORIAL_KEYS.sheetClients, NOW);
    expect(await repo.isSeen(TUTORIAL_KEYS.sheetClients)).toBe(true);
    expect(await repo.isSeen(TUTORIAL_KEYS.sheetTours)).toBe(false);
    close();
  });

  it('list returns all rows', async () => {
    const { db, close } = createTestDb();
    const repo = new TutorialProgressRepository(db);
    await repo.markSeen(TUTORIAL_KEYS.sheetClients, NOW);
    await repo.markSeen(TUTORIAL_KEYS.coachmarkFirstClient, LATER);
    const rows = await repo.list();
    expect(rows.map((r) => r.key).sort()).toEqual([
      'coachmark.first_client',
      'sheet.clients',
    ]);
    close();
  });

  it('resetAll empties the table', async () => {
    const { db, close } = createTestDb();
    const repo = new TutorialProgressRepository(db);
    await repo.markSeen(TUTORIAL_KEYS.sheetClients, NOW);
    await repo.markSeen(TUTORIAL_KEYS.sheetTours, NOW);
    await repo.resetAll();
    expect(await repo.list()).toEqual([]);
    close();
  });
});
