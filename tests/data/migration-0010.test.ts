import Database from 'better-sqlite3';
import { drizzle } from 'drizzle-orm/better-sqlite3';
import { migrate } from 'drizzle-orm/better-sqlite3/migrator';
import path from 'node:path';
import { describe, it, expect } from '@jest/globals';
import * as schema from '@/infra/db/schema';

const MIGRATIONS_FOLDER = path.resolve(__dirname, '../../src/infra/db/migrations');

function freshDb() {
  const sqlite = new Database(':memory:');
  sqlite.pragma('journal_mode = WAL');
  return drizzle(sqlite, { schema });
}

describe('migration 0010 — tutorial_progress', () => {
  it('creates an empty tutorial_progress table on a fresh DB', async () => {
    const db = freshDb();
    migrate(db, { migrationsFolder: MIGRATIONS_FOLDER });
    const rows = await db.select().from(schema.tutorialProgress);
    expect(rows).toEqual([]);
  });

  it('accepts INSERT and enforces PK uniqueness', () => {
    const db = freshDb();
    migrate(db, { migrationsFolder: MIGRATIONS_FOLDER });
    db.insert(schema.tutorialProgress)
      .values({ key: 'sheet.clients', seenAt: '2026-05-11T10:00:00.000Z' })
      .run();
    const rows = db.select().from(schema.tutorialProgress).all();
    expect(rows).toHaveLength(1);
    expect(rows[0]?.key).toBe('sheet.clients');

    expect(() =>
      db
        .insert(schema.tutorialProgress)
        .values({ key: 'sheet.clients', seenAt: '2026-05-11T11:00:00.000Z' })
        .run(),
    ).toThrow(/UNIQUE/);
  });
});
