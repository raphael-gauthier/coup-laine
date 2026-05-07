// scripts/bundle-migrations.mjs
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const migrationsDir = join(__dirname, '..', 'src', 'infra', 'db', 'migrations');

const files = readdirSync(migrationsDir)
  .filter((f) => f.endsWith('.sql'))
  .sort();

const journal = JSON.parse(
  readFileSync(join(migrationsDir, 'meta', '_journal.json'), 'utf8')
);

// The drizzle expo-sqlite migrator picks lastDbMigration = max(created_at) in
// __drizzle_migrations, then runs every entry whose `when` is > that. So a
// hand-written migration with `when` <= max(previous when) is silently skipped
// at runtime — surfacing only as "no such column" errors days later. Catch it
// here. See node_modules/drizzle-orm/sqlite-core/dialect.js (migrate()).
//
// Historical violations that already shipped to user DBs cannot be bumped
// retroactively (it would force re-execution and corrupt their data). List
// them here so the guard ignores them; new migrations must obey the rule.
const KNOWN_HISTORICAL_VIOLATIONS = new Set([
  '0001_r1_flutter_parity',  // when=2025-05-02 < 0000.when=2026-04-09 (drizzle-kit regenerated 0000 after the fact)
  '0002_rename_prestations_to_services', // same root cause as 0001
]);
const orderedEntries = [...journal.entries].sort((a, b) => a.idx - b.idx);
let maxPreviousWhen = -Infinity;
for (const entry of orderedEntries) {
  if (entry.when <= maxPreviousWhen && !KNOWN_HISTORICAL_VIOLATIONS.has(entry.tag)) {
    throw new Error(
      `Migration "${entry.tag}" has when=${entry.when}, which is <= max ` +
        `previous when=${maxPreviousWhen}. The drizzle-orm/expo-sqlite ` +
        `migrator would skip it silently on already-migrated DBs. Bump ` +
        `"${entry.tag}".when in src/infra/db/migrations/meta/_journal.json ` +
        `to at least ${maxPreviousWhen + 1} and re-run pnpm db:bundle.`
    );
  }
  if (entry.when > maxPreviousWhen) maxPreviousWhen = entry.when;
}

// Keys must match what drizzle-orm/expo-sqlite/migrator expects:
// migrations[`m${idx.toString().padStart(4, '0')}`]
const entries = journal.entries.map((entry) => {
  const file = files.find((f) => f.startsWith(entry.idx.toString().padStart(4, '0') + '_'));
  if (!file) throw new Error(`No SQL file found for migration idx ${entry.idx} (tag: ${entry.tag})`);
  const sql = readFileSync(join(migrationsDir, file), 'utf8');
  const key = `m${entry.idx.toString().padStart(4, '0')}`;
  return `  ${key}: ${JSON.stringify(sql)}`;
});

const output = `// AUTO-GENERATED. Do not edit. Run \`pnpm db:bundle\` after \`pnpm db:generate\`.
export default {
  journal: ${JSON.stringify(journal, null, 2)},
  migrations: {
${entries.join(',\n')}
  },
};
`;

writeFileSync(join(migrationsDir, 'migrations.js'), output);
console.log(`Bundled ${files.length} migrations.`);
