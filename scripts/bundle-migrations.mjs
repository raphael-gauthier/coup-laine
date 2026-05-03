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
