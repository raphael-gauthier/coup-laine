import Database from 'better-sqlite3';
import { drizzle } from 'drizzle-orm/better-sqlite3';
import { migrate } from 'drizzle-orm/better-sqlite3/migrator';
import path from 'node:path';
import fs from 'node:fs';
import { describe, it, expect } from '@jest/globals';
import * as schema from '@/infra/db/schema';

const MIGRATIONS_FOLDER = path.resolve(__dirname, '../../src/infra/db/migrations');

function freshDb() {
  const sqlite = new Database(':memory:');
  sqlite.pragma('journal_mode = WAL');
  return drizzle(sqlite, { schema });
}

describe('migration 0009 — statuses', () => {
  it('creates 6 system status rows on a fresh DB', async () => {
    const db = freshDb();
    migrate(db, { migrationsFolder: MIGRATIONS_FOLDER });
    const rows = await db.select().from(schema.statuses);
    expect(rows.map((r) => r.systemKey).sort()).toEqual([
      'banned',
      'default',
      'done',
      'noAnimals',
      'scheduled',
      'waiting',
    ]);
    const def = rows.find((r) => r.systemKey === 'default')!;
    expect(def.colorLight).toBe('#94A3B8');
    expect(def.colorDark).toBe('#64748B');
    expect(def.kind).toBe('system');
  });

  it('carries over marker_*_color into both colorLight and colorDark and strips the keys', async () => {
    // To exercise carry-over, we must INSERT a marker_*_color row BEFORE migration 0009 runs.
    // Run migrations 0000..0008 first via raw SQL, insert the legacy row, then run 0009.
    const sqlite = new Database(':memory:');
    sqlite.pragma('journal_mode = WAL');
    const journal = JSON.parse(
      fs.readFileSync(path.join(MIGRATIONS_FOLDER, 'meta/_journal.json'), 'utf-8'),
    );
    for (const entry of journal.entries) {
      if (entry.tag === '0009_statuses') break;
      const sql = fs.readFileSync(path.join(MIGRATIONS_FOLDER, `${entry.tag}.sql`), 'utf-8');
      for (const stmt of sql.split('--> statement-breakpoint')) {
        const trimmed = stmt.trim();
        if (trimmed) sqlite.exec(trimmed);
      }
    }
    sqlite
      .prepare('INSERT INTO settings (key, value) VALUES (?, ?)')
      .run('marker_waiting_color', '#FF00FF');

    const sql0009 = fs.readFileSync(
      path.join(MIGRATIONS_FOLDER, '0009_statuses.sql'),
      'utf-8',
    );
    for (const stmt of sql0009.split('--> statement-breakpoint')) {
      const trimmed = stmt.trim();
      if (trimmed) sqlite.exec(trimmed);
    }

    const waiting = sqlite
      .prepare("SELECT * FROM statuses WHERE system_key = 'waiting'")
      .get() as { color_light: string; color_dark: string };
    expect(waiting.color_light).toBe('#FF00FF');
    expect(waiting.color_dark).toBe('#FF00FF');
    const remaining = sqlite
      .prepare("SELECT count(*) as n FROM settings WHERE key LIKE 'marker_%_color'")
      .get() as { n: number };
    expect(remaining.n).toBe(0);
  });
});
