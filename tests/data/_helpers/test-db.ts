import Database from 'better-sqlite3';
import { drizzle } from 'drizzle-orm/better-sqlite3';
import { migrate } from 'drizzle-orm/better-sqlite3/migrator';
import { resolve } from 'node:path';

const migrationsFolder = resolve(
  __dirname,
  '..',
  '..',
  '..',
  'src',
  'infra',
  'db',
  'migrations'
);

export function createTestDb() {
  const sqlite = new Database(':memory:');
  const db = drizzle(sqlite);
  migrate(db, { migrationsFolder });
  sqlite.pragma('foreign_keys = ON');
  return { db, close: () => sqlite.close() };
}
