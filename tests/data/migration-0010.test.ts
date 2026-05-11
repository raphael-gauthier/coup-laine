import Database from 'better-sqlite3';
import { drizzle } from 'drizzle-orm/better-sqlite3';
import path from 'node:path';
import fs from 'node:fs';
import { describe, it, expect } from '@jest/globals';
import * as schema from '@/infra/db/schema';

const MIGRATIONS_FOLDER = path.resolve(__dirname, '../../src/infra/db/migrations');

describe('migration 0010 — tutorial_progress', () => {
  it('creates an empty tutorial_progress table on a fresh DB', async () => {
    const sqlite = new Database(':memory:');
    sqlite.pragma('journal_mode = WAL');
    const journal = JSON.parse(
      fs.readFileSync(path.join(MIGRATIONS_FOLDER, 'meta/_journal.json'), 'utf-8'),
    );
    // Run migrations 0000..0010
    for (const entry of journal.entries) {
      if (entry.tag === '0010_tutorial_progress') {
        const sql = fs.readFileSync(path.join(MIGRATIONS_FOLDER, `${entry.tag}.sql`), 'utf-8');
        for (const stmt of sql.split('--> statement-breakpoint')) {
          const trimmed = stmt.trim();
          if (trimmed) sqlite.exec(trimmed);
        }
        break;
      }
      const sql = fs.readFileSync(path.join(MIGRATIONS_FOLDER, `${entry.tag}.sql`), 'utf-8');
      for (const stmt of sql.split('--> statement-breakpoint')) {
        const trimmed = stmt.trim();
        if (trimmed) sqlite.exec(trimmed);
      }
    }
    const db = drizzle(sqlite, { schema });
    const rows = await db.select().from(schema.tutorialProgress);
    expect(rows).toEqual([]);
  });

  it('accepts INSERT and enforces PK uniqueness', async () => {
    const sqlite = new Database(':memory:');
    sqlite.pragma('journal_mode = WAL');
    const journal = JSON.parse(
      fs.readFileSync(path.join(MIGRATIONS_FOLDER, 'meta/_journal.json'), 'utf-8'),
    );
    // Run migrations 0000..0010
    for (const entry of journal.entries) {
      if (entry.tag === '0010_tutorial_progress') {
        const sql = fs.readFileSync(path.join(MIGRATIONS_FOLDER, `${entry.tag}.sql`), 'utf-8');
        for (const stmt of sql.split('--> statement-breakpoint')) {
          const trimmed = stmt.trim();
          if (trimmed) sqlite.exec(trimmed);
        }
        break;
      }
      const sql = fs.readFileSync(path.join(MIGRATIONS_FOLDER, `${entry.tag}.sql`), 'utf-8');
      for (const stmt of sql.split('--> statement-breakpoint')) {
        const trimmed = stmt.trim();
        if (trimmed) sqlite.exec(trimmed);
      }
    }
    const db = drizzle(sqlite, { schema });
    await db.insert(schema.tutorialProgress).values({
      key: 'sheet.clients',
      seenAt: '2026-05-11T10:00:00.000Z',
    });
    const rows = await db.select().from(schema.tutorialProgress);
    expect(rows).toHaveLength(1);
    expect(rows[0]?.key).toBe('sheet.clients');

    await expect(
      db.insert(schema.tutorialProgress).values({
        key: 'sheet.clients',
        seenAt: '2026-05-11T11:00:00.000Z',
      }),
    ).rejects.toThrow();
  });
});
