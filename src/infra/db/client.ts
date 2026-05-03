import { drizzle } from 'drizzle-orm/expo-sqlite';
import type { BaseSQLiteDatabase } from 'drizzle-orm/sqlite-core';
import { openDatabaseSync } from 'expo-sqlite';

const sqlite = openDatabaseSync('coupe-laine.db');

export const db = drizzle(sqlite);

/**
 * Abstract Drizzle SQLite database type. Both `drizzle-orm/expo-sqlite` (prod)
 * and `drizzle-orm/better-sqlite3` (tests) produce instances assignable to it.
 */
export type Db = BaseSQLiteDatabase<'sync', unknown>;

export type Database = typeof db;
