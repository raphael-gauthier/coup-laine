import { drizzle } from 'drizzle-orm/expo-sqlite';
import type { BaseSQLiteDatabase } from 'drizzle-orm/sqlite-core';
import { openDatabaseSync } from 'expo-sqlite';

// Note (security): the SQLite file is NOT encrypted at rest. The threat model
// assumes iOS file protection + Android app sandbox are sufficient against
// "lost or stolen phone" — i.e. an attacker without root/jailbreak access
// cannot read this file. PII (client names, phones, addresses) live here.
// If we ever raise the assurance bar, switch to op-sqlite + SQLCipher with
// the key in expo-secure-store.
const sqlite = openDatabaseSync('coupe-laine.db');

export const db = drizzle(sqlite);

/**
 * Abstract Drizzle SQLite database type. Both `drizzle-orm/expo-sqlite` (prod)
 * and `drizzle-orm/better-sqlite3` (tests) produce instances assignable to it.
 */
export type Db = BaseSQLiteDatabase<'sync', unknown>;

export type Database = typeof db;
