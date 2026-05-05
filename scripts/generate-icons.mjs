// Regenerates assets/images/icon.png, splash-icon.png,
// android-icon-foreground.png and favicon.png from
// scripts/assets/sheep-source.png.
//
// Run from the project root: `node scripts/generate-icons.mjs`

import { jimpAsync } from '@expo/image-utils';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..');
const OUT = path.join(ROOT, 'assets/images');
const SRC = path.join(ROOT, 'scripts/assets/sheep-source.png');
const IVORY = '#F8F4ED';

const opts = (output) => ({ input: SRC, originalInput: SRC, output });

async function main() {
  const fgPath = path.join(OUT, 'android-icon-foreground.png');
  await jimpAsync(opts(fgPath), [
    { operation: 'resize', width: 1024, height: 1024, fit: 'contain', background: '#00000000' },
  ]);
  fs.copyFileSync(fgPath, path.join(OUT, 'splash-icon.png'));

  await jimpAsync(opts(path.join(OUT, 'icon.png')), [
    { operation: 'resize', width: 1024, height: 1024, fit: 'contain', background: IVORY },
    { operation: 'flatten', background: IVORY },
  ]);

  await jimpAsync(opts(path.join(OUT, 'favicon.png')), [
    { operation: 'resize', width: 48, height: 48, fit: 'contain', background: IVORY },
    { operation: 'flatten', background: IVORY },
  ]);

  console.log('Generated:');
  for (const f of ['icon.png', 'splash-icon.png', 'android-icon-foreground.png', 'favicon.png']) {
    const p = path.join(OUT, f);
    console.log(`  ${f}: ${fs.statSync(p).size} bytes`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
