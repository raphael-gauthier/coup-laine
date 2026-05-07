# Version Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Detect outdated app installs, soft-prompt the user to update, and (when needed for security) hard-block them behind a non-dismissable screen — driven by a public Supabase edge function.

**Architecture:** Three layers strictly separated. (1) **Backend**: a `app_versions` table + a public `version-check` edge function. (2) **App pure logic** (`domain/`) computes a tri-state decision from `(installedVersion, remoteConfig)`. (3) **App side-effects** (`infra/data/state/ui`) fetch + cache + render the gate, mounted in `app/_layout.tsx` before the router stack so it can block even pre-login.

**Tech Stack:** Expo SDK 54, RN 0.81, TypeScript strict, Supabase (Deno edge functions), `expo-application`, `expo-secure-store`, `@tanstack/react-query`, `i18next`, vitest (domain tests) + jest (infra/data tests).

**Spec:** [`docs/superpowers/specs/2026-05-07-version-gate-design.md`](../specs/2026-05-07-version-gate-design.md)

---

## Conventions for this plan

- **English-only identifiers, paths, comments.** French only inside `src/i18n/locales/fr.json` values. (CLAUDE.md §6.)
- **TDD where it adds value.** All domain + infra + data tasks: red → green → refactor. UI tasks: no automated tests (no Detox in repo); manual device verification in Task 19.
- **One commit per task** unless a task is trivially small. Use Conventional Commits (`feat:`, `chore:`, `test:`, `fix:`, `docs:`).
- **No `pnpm db:bundle`** is needed — this feature touches Supabase only, not the local Drizzle SQLite migrations (CLAUDE.md §6 trap doesn't apply).
- After each task, run `pnpm typecheck` and the relevant test command. Do not move on if either fails.

---

## File map

**Created:**
- `supabase/sql/app-versions.sql` — schema + RLS, applied manually via dashboard
- `supabase/functions/version-check/index.ts` — Deno edge function
- `src/domain/use-cases/compare-semver.ts`
- `src/domain/models/version-status.ts`
- `src/domain/use-cases/evaluate-version-status.ts`
- `src/infra/services/version-check-api.ts`
- `src/data/repositories/version-config-repository.ts`
- `src/state/hooks/use-soft-update-snooze.ts`
- `src/state/queries/version-status.ts`
- `src/state/hooks/use-version-gate.ts`
- `src/ui/version-gate/version-gate-provider.tsx`
- `src/ui/version-gate/force-update-screen.tsx`
- `src/ui/version-gate/soft-update-modal.tsx`
- `tests/domain/compare-semver.test.ts`
- `tests/domain/evaluate-version-status.test.ts`
- `tests/infra/version-check-api.test.ts`
- `tests/data/version-config-repository.test.ts`

**Modified:**
- `package.json` — add `expo-application`
- `app.json` — add `expo-application` plugin (auto via `expo install`)
- `app/_layout.tsx` — mount `<VersionGateProvider>` around `<Stack>`
- `src/i18n/locales/fr.json` — add `versionGate.*` keys

---

## Task 1: Add `expo-application` dependency

**Files:**
- Modify: `package.json`
- Modify: `app.json` (auto)

`expo-application` provides `nativeApplicationVersion` (the semver from `app.json`'s `version`) and `nativeBuildVersion` (the buildNumber/versionCode). We only use `nativeApplicationVersion`.

- [ ] **Step 1: Install via expo CLI (autopins to SDK 54)**

Run: `pnpm dlx expo install expo-application`
Expected: package added at a version compatible with SDK 54 (`~7.0.x` at the time of writing). `app.json` may receive an auto-config plugin entry — leave it as the CLI sets it.

- [ ] **Step 2: Sanity check**

Run: `pnpm typecheck`
Expected: PASS (no type errors).

- [ ] **Step 3: Commit**

```bash
git add package.json pnpm-lock.yaml app.json
git commit -m "chore: add expo-application for version gate"
```

---

## Task 2: Create Supabase SQL for `app_versions` (checked-in reference)

**Files:**
- Create: `supabase/sql/app-versions.sql`

The repo doesn't have a migration directory under `supabase/` — schema changes are applied via the dashboard. We commit the SQL as documentation so anyone can replay it on a fresh project.

- [ ] **Step 1: Create the SQL file**

```sql
-- supabase/sql/app-versions.sql
-- Apply via Supabase dashboard SQL editor on each environment.
-- Idempotent: safe to re-run.

create table if not exists app_versions (
  platform              text primary key check (platform in ('ios','android')),
  latest_version        text not null,
  min_supported_version text not null,
  security_flag         boolean not null default false,
  release_notes_fr      text,
  store_url             text not null,
  updated_at            timestamptz not null default now()
);

alter table app_versions enable row level security;

drop policy if exists "public read" on app_versions;
create policy "public read"
  on app_versions for select
  to anon, authenticated
  using (true);

-- INSERT/UPDATE/DELETE intentionally not granted to anon/authenticated.
-- Edits happen via the dashboard (service_role).
```

- [ ] **Step 2: Apply on dev / staging Supabase project**

Manual: open Supabase dashboard → SQL editor → paste the file content → Run. Verify the table exists in the Table editor.

- [ ] **Step 3: Seed both platforms with the current production version**

Manual SQL in the dashboard, replacing `<LATEST>` with the current `version` from `app.json` (today: `0.10.1`) and `<APP_STORE_URL>` / `<PLAY_STORE_URL>` with the real store URLs (use the published listing URLs; if not yet published, use a temporary placeholder like `https://couplaine.fr/`):

```sql
insert into app_versions (platform, latest_version, min_supported_version, security_flag, release_notes_fr, store_url) values
  ('ios',     '<LATEST>', '<LATEST>', false, null, '<APP_STORE_URL>'),
  ('android', '<LATEST>', '<LATEST>', false, null, '<PLAY_STORE_URL>')
on conflict (platform) do update set
  latest_version        = excluded.latest_version,
  min_supported_version = excluded.min_supported_version,
  security_flag         = excluded.security_flag,
  release_notes_fr      = excluded.release_notes_fr,
  store_url             = excluded.store_url,
  updated_at            = now();
```

Setting `min_supported_version === latest_version` keeps the gate inactive (every install is `ok`) until a newer version is published — exactly the safe seed described in the spec §11.

- [ ] **Step 4: Commit**

```bash
git add supabase/sql/app-versions.sql
git commit -m "feat(version-gate): add app_versions table SQL"
```

---

## Task 3: Edge function `version-check`

**Files:**
- Create: `supabase/functions/version-check/index.ts`

Public (no JWT required), GET-only, returns the row for a given platform, mirrors the CORS pattern of `delete-account`/`ors-proxy`.

- [ ] **Step 1: Write the function**

```ts
// supabase/functions/version-check/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SECRET_KEYS_RAW = Deno.env.get('SUPABASE_SECRET_KEYS');

let SECRET_KEY: string | undefined;
if (SECRET_KEYS_RAW) {
  try {
    const parsed = JSON.parse(SECRET_KEYS_RAW) as Record<string, string>;
    SECRET_KEY = parsed['default'];
  } catch {
    SECRET_KEY = undefined;
  }
}
if (!SECRET_KEY) {
  SECRET_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
}

const corsHeaders: HeadersInit = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
};

function jsonResponse(body: unknown, status = 200, extraHeaders: HeadersInit = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
      ...extraHeaders,
    },
  });
}

const ALLOWED_PLATFORMS = new Set(['ios', 'android']);

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== 'GET') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }
  if (!SUPABASE_URL || !SECRET_KEY) {
    return jsonResponse({ error: 'Server not configured' }, 500);
  }

  const url = new URL(req.url);
  const platform = url.searchParams.get('platform');
  if (!platform) {
    return jsonResponse({ error: 'Missing platform query param' }, 400);
  }
  if (!ALLOWED_PLATFORMS.has(platform)) {
    return jsonResponse({ error: 'Invalid platform' }, 400);
  }

  const admin = createClient(SUPABASE_URL, SECRET_KEY, {
    auth: { persistSession: false },
  });

  const { data, error } = await admin
    .from('app_versions')
    .select('platform, latest_version, min_supported_version, security_flag, release_notes_fr, store_url')
    .eq('platform', platform)
    .maybeSingle();

  if (error) {
    return jsonResponse({ error: `Lookup failed: ${error.message}` }, 500);
  }
  if (!data) {
    return jsonResponse({ error: 'Platform not configured' }, 404);
  }

  return jsonResponse(
    {
      platform: data.platform,
      latestVersion: data.latest_version,
      minSupportedVersion: data.min_supported_version,
      securityFlag: data.security_flag,
      releaseNotesFr: data.release_notes_fr,
      storeUrl: data.store_url,
    },
    200,
    { 'Cache-Control': 'public, max-age=300' },
  );
});
```

Why service-role despite RLS allowing public SELECT? Consistency with the other edge functions and resilience if RLS is ever tightened. The function never echoes any input back nor accepts a body, so it cannot be used as a privilege-escalation vector.

- [ ] **Step 2: Deploy on dev / staging**

Manual: `pnpm dlx supabase functions deploy version-check` (assumes `supabase` CLI is logged in).

- [ ] **Step 3: Smoke test**

Manual:

```bash
curl -i "https://<PROJECT-REF>.supabase.co/functions/v1/version-check?platform=ios"
```

Expected: `200 OK`, `Cache-Control: public, max-age=300`, JSON body with `latestVersion`, `minSupportedVersion`, etc.

```bash
curl -i "https://<PROJECT-REF>.supabase.co/functions/v1/version-check?platform=foo"
```

Expected: `400 Bad Request`, `{"error":"Invalid platform"}`.

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/version-check/index.ts
git commit -m "feat(version-gate): add version-check edge function"
```

---

## Task 4: Domain — `compareSemver` (TDD)

**Files:**
- Create: `src/domain/use-cases/compare-semver.ts`
- Create: `tests/domain/compare-semver.test.ts`

Pure function. No `semver` dependency. Vitest.

- [ ] **Step 1: Write the failing tests**

```ts
// tests/domain/compare-semver.test.ts
import { describe, it, expect } from 'vitest';
import { compareSemver } from '@/domain/use-cases/compare-semver';

describe('compareSemver', () => {
  const cases: Array<[string, string, -1 | 0 | 1]> = [
    ['0.10.0', '0.10.0', 0],
    ['0.10.0', '0.10.1', -1],
    ['0.10.1', '0.10.0', 1],
    ['0.9.99', '0.10.0', -1],
    ['1.0.0', '0.99.99', 1],
    ['0.10', '0.10.0', 0], // missing patch defaults to 0
    ['0.10.0-beta.1', '0.10.0', 0], // prerelease treated as stable
    ['0.10.0', '0.10.0-beta.1', 0],
    ['', '0.10.0', 0], // malformed → fail-open: equality
    ['lol', '0.10.0', 0], // malformed → equality
  ];

  it.each(cases)('compareSemver(%s, %s) === %s', (a, b, expected) => {
    expect(compareSemver(a, b)).toBe(expected);
  });
});
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `pnpm test:domain -- compare-semver`
Expected: tests fail with import error or `compareSemver is not a function`.

- [ ] **Step 3: Implement**

```ts
// src/domain/use-cases/compare-semver.ts
function parsePart(part: string | undefined): number {
  if (part === undefined) return 0;
  const cleaned = part.split('-')[0] ?? '0';
  const n = Number.parseInt(cleaned, 10);
  return Number.isFinite(n) ? n : NaN;
}

function parseSemver(v: string): [number, number, number] | null {
  const [head] = v.split('-');
  const parts = (head ?? '').split('.');
  if (parts.length === 0 || parts[0] === '') return null;
  const major = parsePart(parts[0]);
  const minor = parsePart(parts[1]);
  const patch = parsePart(parts[2]);
  if (Number.isNaN(major) || Number.isNaN(minor) || Number.isNaN(patch)) return null;
  return [major, minor, patch];
}

export function compareSemver(a: string, b: string): -1 | 0 | 1 {
  const pa = parseSemver(a);
  const pb = parseSemver(b);
  // Either side malformed → fail-open: pretend equal so the caller treats as 'ok'.
  if (!pa || !pb) return 0;
  for (let i = 0; i < 3; i++) {
    const ai = pa[i] ?? 0;
    const bi = pb[i] ?? 0;
    if (ai < bi) return -1;
    if (ai > bi) return 1;
  }
  return 0;
}
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `pnpm test:domain -- compare-semver`
Expected: all 10 cases PASS.

- [ ] **Step 5: Commit**

```bash
git add src/domain/use-cases/compare-semver.ts tests/domain/compare-semver.test.ts
git commit -m "feat(version-gate): add compareSemver"
```

---

## Task 5: Domain — types & `evaluateVersionStatus` (TDD)

**Files:**
- Create: `src/domain/models/version-status.ts`
- Create: `src/domain/use-cases/evaluate-version-status.ts`
- Create: `tests/domain/evaluate-version-status.test.ts`

- [ ] **Step 1: Define types**

```ts
// src/domain/models/version-status.ts
export type Platform = 'ios' | 'android';

export type VersionConfig = {
  platform: Platform;
  latestVersion: string;
  minSupportedVersion: string;
  securityFlag: boolean;
  releaseNotesFr: string | null;
  storeUrl: string;
};

export type VersionDecision =
  | { kind: 'ok' }
  | {
      kind: 'soft-update';
      latest: string;
      releaseNotesFr: string | null;
      security: boolean;
      storeUrl: string;
    }
  | { kind: 'force-update'; minSupported: string; storeUrl: string };
```

- [ ] **Step 2: Write the failing tests**

```ts
// tests/domain/evaluate-version-status.test.ts
import { describe, it, expect } from 'vitest';
import { evaluateVersionStatus } from '@/domain/use-cases/evaluate-version-status';
import type { VersionConfig } from '@/domain/models/version-status';

const baseConfig: VersionConfig = {
  platform: 'ios',
  latestVersion: '0.11.0',
  minSupportedVersion: '0.10.0',
  securityFlag: false,
  releaseNotesFr: '- Some notes',
  storeUrl: 'https://apps.apple.com/app/id123',
};

describe('evaluateVersionStatus', () => {
  it('returns ok when installed === latest', () => {
    expect(evaluateVersionStatus('0.11.0', baseConfig)).toEqual({ kind: 'ok' });
  });

  it('returns ok when installed > latest (dev/internal build)', () => {
    expect(evaluateVersionStatus('0.99.0', baseConfig)).toEqual({ kind: 'ok' });
  });

  it('returns soft-update when min_supported <= installed < latest', () => {
    expect(evaluateVersionStatus('0.10.5', baseConfig)).toEqual({
      kind: 'soft-update',
      latest: '0.11.0',
      releaseNotesFr: '- Some notes',
      security: false,
      storeUrl: 'https://apps.apple.com/app/id123',
    });
  });

  it('propagates security flag on soft-update', () => {
    const decision = evaluateVersionStatus('0.10.5', { ...baseConfig, securityFlag: true });
    expect(decision).toMatchObject({ kind: 'soft-update', security: true });
  });

  it('returns force-update when installed < min_supported', () => {
    expect(evaluateVersionStatus('0.9.0', baseConfig)).toEqual({
      kind: 'force-update',
      minSupported: '0.10.0',
      storeUrl: 'https://apps.apple.com/app/id123',
    });
  });

  it('treats malformed installed version as ok (fail-open)', () => {
    expect(evaluateVersionStatus('lol', baseConfig)).toEqual({ kind: 'ok' });
    expect(evaluateVersionStatus('', baseConfig)).toEqual({ kind: 'ok' });
  });

  it('treats prerelease as the corresponding stable version', () => {
    // 0.10.0-beta.1 == 0.10.0 → equal to min_supported → soft-update (since < latest)
    expect(evaluateVersionStatus('0.10.0-beta.1', baseConfig)).toMatchObject({
      kind: 'soft-update',
    });
  });
});
```

- [ ] **Step 3: Run tests, verify they fail**

Run: `pnpm test:domain -- evaluate-version-status`
Expected: import error / function undefined.

- [ ] **Step 4: Implement**

```ts
// src/domain/use-cases/evaluate-version-status.ts
import { compareSemver } from './compare-semver';
import type { VersionConfig, VersionDecision } from '@/domain/models/version-status';

export function evaluateVersionStatus(
  installed: string,
  config: VersionConfig,
): VersionDecision {
  if (compareSemver(installed, config.minSupportedVersion) < 0) {
    return {
      kind: 'force-update',
      minSupported: config.minSupportedVersion,
      storeUrl: config.storeUrl,
    };
  }
  if (compareSemver(installed, config.latestVersion) < 0) {
    return {
      kind: 'soft-update',
      latest: config.latestVersion,
      releaseNotesFr: config.releaseNotesFr,
      security: config.securityFlag,
      storeUrl: config.storeUrl,
    };
  }
  return { kind: 'ok' };
}
```

- [ ] **Step 5: Run tests, verify they pass**

Run: `pnpm test:domain -- evaluate-version-status`
Expected: all 7 cases PASS.

- [ ] **Step 6: Commit**

```bash
git add src/domain/models/version-status.ts src/domain/use-cases/evaluate-version-status.ts tests/domain/evaluate-version-status.test.ts
git commit -m "feat(version-gate): add evaluateVersionStatus domain use case"
```

---

## Task 6: Infra — `version-check-api` (TDD)

**Files:**
- Create: `src/infra/services/version-check-api.ts`
- Create: `tests/infra/version-check-api.test.ts`

Plain `fetch` against the edge function. No Zod (consistent with `ors-routing.ts`); just shape-validate with explicit checks. Returns `null` on `404` (platform not configured); throws on network/5xx so the repository can decide cache fallback.

- [ ] **Step 1: Add an env entry for the version-check URL**

Edit `src/infra/config/env.ts`:

```ts
function required(name: string, value: string | undefined): string {
  if (!value || value.length === 0) {
    throw new Error(`Missing env var: ${name}`);
  }
  return value;
}

export const env = {
  supabaseUrl: required('EXPO_PUBLIC_SUPABASE_URL', process.env.EXPO_PUBLIC_SUPABASE_URL),
  supabaseAnonKey: required('EXPO_PUBLIC_SUPABASE_ANON_KEY', process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY),
  maptilerApiKey: required('EXPO_PUBLIC_MAPTILER_API_KEY', process.env.EXPO_PUBLIC_MAPTILER_API_KEY),
  orsBaseUrl: required('EXPO_PUBLIC_ORS_BASE_URL', process.env.EXPO_PUBLIC_ORS_BASE_URL),
  versionCheckUrl: required('EXPO_PUBLIC_VERSION_CHECK_URL', process.env.EXPO_PUBLIC_VERSION_CHECK_URL),
};
```

Then add `EXPO_PUBLIC_VERSION_CHECK_URL=https://<PROJECT-REF>.supabase.co/functions/v1/version-check` to your local `.env` (and document it for staging/prod).

- [ ] **Step 2: Write the failing tests**

```ts
// tests/infra/version-check-api.test.ts
import { fetchVersionConfig } from '@/infra/services/version-check-api';

jest.mock('@/infra/config/env', () => ({
  env: {
    supabaseUrl: 'https://test.supabase.co',
    supabaseAnonKey: 'anon-key',
    maptilerApiKey: 'maptiler-key',
    orsBaseUrl: 'https://test.supabase.co/functions/v1/ors-proxy',
    versionCheckUrl: 'https://test.supabase.co/functions/v1/version-check',
  },
}));

describe('fetchVersionConfig', () => {
  afterEach(() => jest.restoreAllMocks());

  it('passes platform query param and parses 200 payload', async () => {
    const fetchSpy = jest.spyOn(global, 'fetch').mockImplementation(
      async () =>
        new Response(
          JSON.stringify({
            platform: 'ios',
            latestVersion: '0.11.0',
            minSupportedVersion: '0.10.0',
            securityFlag: false,
            releaseNotesFr: '- Notes',
            storeUrl: 'https://apps.apple.com/app/id123',
          }),
          { status: 200, headers: { 'Content-Type': 'application/json' } },
        ),
    );

    const result = await fetchVersionConfig('ios');
    expect(result).toEqual({
      platform: 'ios',
      latestVersion: '0.11.0',
      minSupportedVersion: '0.10.0',
      securityFlag: false,
      releaseNotesFr: '- Notes',
      storeUrl: 'https://apps.apple.com/app/id123',
    });

    const calledUrl = fetchSpy.mock.calls[0]?.[0];
    expect(String(calledUrl)).toBe(
      'https://test.supabase.co/functions/v1/version-check?platform=ios',
    );
  });

  it('returns null on 404', async () => {
    jest.spyOn(global, 'fetch').mockImplementation(
      async () => new Response(JSON.stringify({ error: 'Platform not configured' }), { status: 404 }),
    );
    expect(await fetchVersionConfig('android')).toBeNull();
  });

  it('throws on 500', async () => {
    jest.spyOn(global, 'fetch').mockImplementation(
      async () => new Response('boom', { status: 500 }),
    );
    await expect(fetchVersionConfig('ios')).rejects.toThrow(/500/);
  });

  it('throws when JSON shape is invalid', async () => {
    jest.spyOn(global, 'fetch').mockImplementation(
      async () => new Response(JSON.stringify({ hello: 'world' }), { status: 200 }),
    );
    await expect(fetchVersionConfig('ios')).rejects.toThrow(/invalid/i);
  });
});
```

- [ ] **Step 3: Run tests, verify they fail**

Run: `pnpm test:integration -- version-check-api`
Expected: import error.

- [ ] **Step 4: Implement**

```ts
// src/infra/services/version-check-api.ts
import { env } from '@/infra/config/env';
import type { Platform, VersionConfig } from '@/domain/models/version-status';

const TIMEOUT_MS = 3000;

function isVersionConfig(x: unknown): x is VersionConfig {
  if (!x || typeof x !== 'object') return false;
  const o = x as Record<string, unknown>;
  return (
    (o.platform === 'ios' || o.platform === 'android') &&
    typeof o.latestVersion === 'string' &&
    typeof o.minSupportedVersion === 'string' &&
    typeof o.securityFlag === 'boolean' &&
    (o.releaseNotesFr === null || typeof o.releaseNotesFr === 'string') &&
    typeof o.storeUrl === 'string'
  );
}

/**
 * Fetches the remote version config for one platform.
 * - 200 → parsed VersionConfig
 * - 404 → null (platform not configured server-side)
 * - other (network, timeout, 4xx/5xx, malformed body) → throws
 */
export async function fetchVersionConfig(
  platform: Platform,
  options: { signal?: AbortSignal } = {},
): Promise<VersionConfig | null> {
  const url = `${env.versionCheckUrl}?platform=${platform}`;

  const internalCtrl = new AbortController();
  const timeoutId = setTimeout(() => internalCtrl.abort(), TIMEOUT_MS);
  options.signal?.addEventListener('abort', () => internalCtrl.abort(), { once: true });

  let response: Response;
  try {
    response = await fetch(url, { method: 'GET', signal: internalCtrl.signal });
  } finally {
    clearTimeout(timeoutId);
  }

  if (response.status === 404) return null;
  if (!response.ok) {
    throw new Error(`version-check error: ${response.status}`);
  }

  const json = (await response.json()) as unknown;
  if (!isVersionConfig(json)) {
    throw new Error('version-check invalid payload shape');
  }
  return json;
}
```

- [ ] **Step 5: Run tests, verify they pass**

Run: `pnpm test:integration -- version-check-api`
Expected: 4 cases PASS.

- [ ] **Step 6: Run typecheck**

Run: `pnpm typecheck`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/infra/services/version-check-api.ts src/infra/config/env.ts tests/infra/version-check-api.test.ts
git commit -m "feat(version-gate): add version-check API client"
```

---

## Task 7: Data — `versionConfigRepository` (TDD)

**Files:**
- Create: `src/data/repositories/version-config-repository.ts`
- Create: `tests/data/version-config-repository.test.ts`

Wraps `fetchVersionConfig` with a SecureStore cache. Returns `'fresh' | 'stale' | 'unavailable'` per the spec §6.1.

- [ ] **Step 1: Write the failing tests**

```ts
// tests/data/version-config-repository.test.ts
import * as SecureStore from 'expo-secure-store';
import { getVersionConfig, __resetForTests } from '@/data/repositories/version-config-repository';
import * as api from '@/infra/services/version-check-api';

jest.mock('expo-secure-store');

const FRESH_CONFIG = {
  platform: 'ios' as const,
  latestVersion: '0.11.0',
  minSupportedVersion: '0.10.0',
  securityFlag: false,
  releaseNotesFr: null,
  storeUrl: 'https://apps.apple.com/app/id123',
};

describe('versionConfigRepository', () => {
  let store: Record<string, string> = {};

  beforeEach(() => {
    store = {};
    (SecureStore.getItemAsync as jest.Mock).mockImplementation(async (k: string) => store[k] ?? null);
    (SecureStore.setItemAsync as jest.Mock).mockImplementation(async (k: string, v: string) => {
      store[k] = v;
    });
    (SecureStore.deleteItemAsync as jest.Mock).mockImplementation(async (k: string) => {
      delete store[k];
    });
    __resetForTests();
  });

  afterEach(() => jest.restoreAllMocks());

  it('fetch 200 → status fresh, cache written', async () => {
    jest.spyOn(api, 'fetchVersionConfig').mockResolvedValue(FRESH_CONFIG);
    const result = await getVersionConfig('ios');
    expect(result.status).toBe('fresh');
    expect(result.config).toEqual(FRESH_CONFIG);
    expect(store['version-gate.cache.ios']).toBeDefined();
  });

  it('fetch fails + cache exists → status stale', async () => {
    store['version-gate.cache.ios'] = JSON.stringify({ config: FRESH_CONFIG, fetchedAt: Date.now() });
    jest.spyOn(api, 'fetchVersionConfig').mockRejectedValue(new Error('boom'));
    const result = await getVersionConfig('ios');
    expect(result.status).toBe('stale');
    expect(result.config).toEqual(FRESH_CONFIG);
  });

  it('fetch fails + no cache → status unavailable', async () => {
    jest.spyOn(api, 'fetchVersionConfig').mockRejectedValue(new Error('boom'));
    const result = await getVersionConfig('ios');
    expect(result.status).toBe('unavailable');
    expect(result.config).toBeNull();
  });

  it('cache JSON corrupt → ignored, refetch tried', async () => {
    store['version-gate.cache.ios'] = '{not json';
    const apiSpy = jest.spyOn(api, 'fetchVersionConfig').mockResolvedValue(FRESH_CONFIG);
    const result = await getVersionConfig('ios');
    expect(apiSpy).toHaveBeenCalled();
    expect(result.status).toBe('fresh');
  });

  it('cache older than 24h + fetch ok → cache overwritten, status fresh', async () => {
    const stale = Date.now() - 25 * 3600 * 1000;
    store['version-gate.cache.ios'] = JSON.stringify({ config: FRESH_CONFIG, fetchedAt: stale });
    jest.spyOn(api, 'fetchVersionConfig').mockResolvedValue({ ...FRESH_CONFIG, latestVersion: '0.12.0' });
    const result = await getVersionConfig('ios');
    expect(result.status).toBe('fresh');
    expect(result.config?.latestVersion).toBe('0.12.0');
  });

  it('platform 404 → returns the cache if any, else unavailable', async () => {
    jest.spyOn(api, 'fetchVersionConfig').mockResolvedValue(null);
    const result = await getVersionConfig('ios');
    expect(result.status).toBe('unavailable');
    expect(result.config).toBeNull();
  });
});
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `pnpm test:integration -- version-config-repository`
Expected: import error.

- [ ] **Step 3: Implement**

```ts
// src/data/repositories/version-config-repository.ts
import * as SecureStore from 'expo-secure-store';
import type { Platform, VersionConfig } from '@/domain/models/version-status';
import { fetchVersionConfig } from '@/infra/services/version-check-api';

const CACHE_KEY = (p: Platform) => `version-gate.cache.${p}`;

type CacheEntry = { config: VersionConfig; fetchedAt: number };

export type RepoResult =
  | { status: 'fresh'; config: VersionConfig }
  | { status: 'stale'; config: VersionConfig }
  | { status: 'unavailable'; config: null };

async function readCache(platform: Platform): Promise<CacheEntry | null> {
  const raw = await SecureStore.getItemAsync(CACHE_KEY(platform));
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as CacheEntry;
    if (!parsed?.config || typeof parsed.fetchedAt !== 'number') return null;
    return parsed;
  } catch {
    return null;
  }
}

async function writeCache(platform: Platform, config: VersionConfig): Promise<void> {
  const entry: CacheEntry = { config, fetchedAt: Date.now() };
  await SecureStore.setItemAsync(CACHE_KEY(platform), JSON.stringify(entry));
}

/**
 * For tests only. Cache resets are otherwise unnecessary because the
 * mocked SecureStore is reset by the test harness.
 */
export function __resetForTests(): void {
  // No in-memory state to reset for now — placeholder for future memoization.
}

export async function getVersionConfig(platform: Platform): Promise<RepoResult> {
  const cache = await readCache(platform);
  try {
    const fetched = await fetchVersionConfig(platform);
    if (fetched) {
      await writeCache(platform, fetched);
      return { status: 'fresh', config: fetched };
    }
    // 404 from API — platform not configured server-side. Honor cache if any.
    if (cache) return { status: 'stale', config: cache.config };
    return { status: 'unavailable', config: null };
  } catch {
    if (cache) return { status: 'stale', config: cache.config };
    return { status: 'unavailable', config: null };
  }
}
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `pnpm test:integration -- version-config-repository`
Expected: 6 cases PASS.

- [ ] **Step 5: Commit**

```bash
git add src/data/repositories/version-config-repository.ts tests/data/version-config-repository.test.ts
git commit -m "feat(version-gate): add version config repository with cache"
```

---

## Task 8: State — soft-update snooze hook

**Files:**
- Create: `src/state/hooks/use-soft-update-snooze.ts`

Reads/writes the snooze record in SecureStore. Pure I/O — no React Query because we don't need refetch / invalidation; snooze is local-only.

- [ ] **Step 1: Implement**

```ts
// src/state/hooks/use-soft-update-snooze.ts
import { useCallback, useEffect, useState } from 'react';
import * as SecureStore from 'expo-secure-store';

const KEY = 'version-gate.snoozed';
const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

type Snooze = { version: string; until: number };

async function readSnooze(): Promise<Snooze | null> {
  const raw = await SecureStore.getItemAsync(KEY);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as Snooze;
    if (typeof parsed?.version !== 'string' || typeof parsed?.until !== 'number') return null;
    return parsed;
  } catch {
    return null;
  }
}

export function useSoftUpdateSnooze() {
  const [snooze, setSnoozeState] = useState<Snooze | null>(null);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    void readSnooze().then((s) => {
      setSnoozeState(s);
      setLoaded(true);
    });
  }, []);

  const snoozeFor = useCallback(async (latestVersion: string) => {
    const next: Snooze = { version: latestVersion, until: Date.now() + SEVEN_DAYS_MS };
    await SecureStore.setItemAsync(KEY, JSON.stringify(next));
    setSnoozeState(next);
  }, []);

  const isSnoozed = useCallback(
    (latestVersion: string) => {
      if (!snooze) return false;
      if (snooze.version !== latestVersion) return false;
      return Date.now() < snooze.until;
    },
    [snooze],
  );

  return { loaded, isSnoozed, snoozeFor };
}
```

- [ ] **Step 2: Typecheck**

Run: `pnpm typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add src/state/hooks/use-soft-update-snooze.ts
git commit -m "feat(version-gate): add soft-update snooze hook"
```

---

## Task 9: State — `useVersionStatusQuery` & `useVersionGate`

**Files:**
- Create: `src/state/queries/version-status.ts`
- Create: `src/state/hooks/use-version-gate.ts`

`useVersionStatusQuery` wraps the repo in TanStack Query for retry/cache. `useVersionGate` combines that query with `Application.nativeApplicationVersion`, the AppState listener, and the `evaluateVersionStatus` use case to produce the final decision.

- [ ] **Step 1: Add the query**

```ts
// src/state/queries/version-status.ts
import { useQuery } from '@tanstack/react-query';
import * as Sentry from '@sentry/react-native';
import { getVersionConfig, type RepoResult } from '@/data/repositories/version-config-repository';
import type { Platform } from '@/domain/models/version-status';

export const versionStatusKeys = {
  config: (platform: Platform) => ['version-status', platform] as const,
};

const SIX_HOURS_MS = 6 * 60 * 60 * 1000;
const TWENTY_FOUR_HOURS_MS = 24 * 60 * 60 * 1000;

export function useVersionStatusQuery(platform: Platform | null) {
  return useQuery<RepoResult>({
    queryKey: platform ? versionStatusKeys.config(platform) : ['version-status', 'noop'],
    enabled: platform !== null,
    queryFn: async () => {
      try {
        return await getVersionConfig(platform!);
      } catch (e) {
        Sentry.addBreadcrumb({
          category: 'version-gate',
          level: 'warning',
          message: 'version-gate.check.failure',
          data: { platform, errorKind: classifyError(e) },
        });
        throw e;
      }
    },
    staleTime: SIX_HOURS_MS,
    gcTime: TWENTY_FOUR_HOURS_MS,
    retry: 1,
  });
}

function classifyError(err: unknown): string {
  const msg = err instanceof Error ? err.message : String(err);
  if (msg.includes('aborted') || msg.toLowerCase().includes('timeout')) return 'timeout';
  if (/\b5\d{2}\b/.test(msg)) return 'http_5xx';
  if (/\b4\d{2}\b/.test(msg)) return 'http_4xx';
  if (msg.toLowerCase().includes('invalid')) return 'parse';
  return 'network';
}
```

- [ ] **Step 2: Add the gate hook**

```ts
// src/state/hooks/use-version-gate.ts
import { useEffect, useMemo } from 'react';
import { AppState, Platform as RNPlatform } from 'react-native';
import * as Application from 'expo-application';
import * as Sentry from '@sentry/react-native';
import { useVersionStatusQuery } from '@/state/queries/version-status';
import { evaluateVersionStatus } from '@/domain/use-cases/evaluate-version-status';
import type { Platform, VersionDecision } from '@/domain/models/version-status';

const SIX_HOURS_MS = 6 * 60 * 60 * 1000;

function resolvePlatform(): Platform | null {
  if (RNPlatform.OS === 'ios') return 'ios';
  if (RNPlatform.OS === 'android') return 'android';
  return null;
}

export type GateState =
  | { kind: 'loading' }
  | { kind: 'decided'; decision: VersionDecision };

export function useVersionGate(): GateState {
  const platform = resolvePlatform();
  const installed = Application.nativeApplicationVersion ?? '0.0.0';
  const query = useVersionStatusQuery(platform);

  // AppState listener: refetch when returning to foreground after staleTime.
  useEffect(() => {
    if (!platform) return;
    const sub = AppState.addEventListener('change', (next) => {
      if (next !== 'active') return;
      const updatedAt = query.dataUpdatedAt;
      if (!updatedAt || Date.now() - updatedAt > SIX_HOURS_MS) {
        void query.refetch();
      }
    });
    return () => sub.remove();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [platform, query.dataUpdatedAt]);

  return useMemo<GateState>(() => {
    // Web build or other non-mobile target → never gate.
    if (!platform) return { kind: 'decided', decision: { kind: 'ok' } };

    if (query.isPending) return { kind: 'loading' };

    const result = query.data;
    if (!result || result.status === 'unavailable' || result.config === null) {
      // Fail open.
      Sentry.addBreadcrumb({
        category: 'version-gate',
        level: 'info',
        message: 'version-gate.check.success',
        data: { platform, installed, decision: 'ok-fail-open', fromCache: false },
      });
      return { kind: 'decided', decision: { kind: 'ok' } };
    }

    const decision = evaluateVersionStatus(installed, result.config);
    Sentry.addBreadcrumb({
      category: 'version-gate',
      level: 'info',
      message: 'version-gate.check.success',
      data: {
        platform,
        installed,
        latest: result.config.latestVersion,
        decision: decision.kind,
        fromCache: result.status === 'stale',
      },
    });
    return { kind: 'decided', decision };
  }, [platform, installed, query.isPending, query.data]);
}
```

- [ ] **Step 3: Typecheck**

Run: `pnpm typecheck`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add src/state/queries/version-status.ts src/state/hooks/use-version-gate.ts
git commit -m "feat(version-gate): add version status query and gate hook"
```

---

## Task 10: i18n — `versionGate.*` keys

**Files:**
- Modify: `src/i18n/locales/fr.json`

- [ ] **Step 1: Add the block**

Insert (before the final closing brace, alongside `cloud`/`auth` siblings — the JSON file is one big object):

```json
"versionGate": {
  "force": {
    "title": "Mise à jour requise",
    "subtitle": "Cette version n'est plus prise en charge. Mettez à jour pour continuer.",
    "securityNote": "Cette mise à jour corrige un problème de sécurité.",
    "cta": {
      "update": "Mettre à jour",
      "export": "Exporter mes données",
      "deleteAccount": "Supprimer mon compte",
      "signInToManageData": "Connectez-vous pour gérer vos données."
    },
    "yourData": "Vos données"
  },
  "soft": {
    "title": "Une mise à jour est disponible",
    "securityNote": "⚠️ Mise à jour de sécurité recommandée.",
    "fallbackNotes": "Quelques améliorations et correctifs.",
    "cta": {
      "update": "Mettre à jour",
      "later": "Plus tard"
    }
  }
}
```

- [ ] **Step 2: Verify JSON parses**

Run: `node -e "require('./src/i18n/locales/fr.json')"`
Expected: no output, exit code 0.

- [ ] **Step 3: Commit**

```bash
git add src/i18n/locales/fr.json
git commit -m "feat(version-gate): add fr i18n keys"
```

---

## Task 11: UI — `<ForceUpdateScreen />`

**Files:**
- Create: `src/ui/version-gate/force-update-screen.tsx`

Plain screen, no router push (it lives outside the Stack). Reuses `Surface`, `Button`, `Text`, `useSession`, `useExportData`, `useDeleteAccount`, `confirm` (typed-confirm dialog) — all already in the repo.

- [ ] **Step 1: Implement**

```tsx
// src/ui/version-gate/force-update-screen.tsx
import { useState } from 'react';
import { Linking, ScrollView, View } from 'react-native';
import * as Sentry from '@sentry/react-native';
import { useTranslation } from 'react-i18next';
import { AlertTriangle } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ConfirmTypedDialog } from '@/ui/components/confirm-dialog';
import { useSession, useDeleteAccount } from '@/state/queries/auth';
import { useExportData } from '@/state/queries/backups';
import { successToast } from '@/ui/components/error-toast';

interface Props {
  storeUrl: string;
  security: boolean;
}

export function ForceUpdateScreen({ storeUrl, security }: Props) {
  const { t } = useTranslation();
  const { data: session } = useSession();
  const exportData = useExportData();
  const deleteAccount = useDeleteAccount();
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);

  const isLoggedIn = !!session && !session.user.is_anonymous;

  const handleUpdate = () => {
    Sentry.addBreadcrumb({
      category: 'version-gate',
      message: 'version-gate.action',
      data: { kind: 'open-store' },
    });
    void Linking.openURL(storeUrl);
  };

  const handleExport = () => {
    Sentry.addBreadcrumb({
      category: 'version-gate',
      message: 'version-gate.action',
      data: { kind: 'export-data' },
    });
    exportData.mutate();
  };

  const handleDeleteConfirmed = () => {
    Sentry.addBreadcrumb({
      category: 'version-gate',
      message: 'version-gate.action',
      data: { kind: 'delete-account' },
    });
    setDeleteDialogOpen(false);
    deleteAccount.mutate(undefined, {
      onSuccess: () => {
        successToast(t('cloud.delete_account.success_toast'));
      },
    });
  };

  return (
    <Surface className="flex-1">
      <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', padding: 24 }}>
        <View className="items-center gap-6">
          {security && (
            <View className="flex-row items-center gap-2">
              <AlertTriangle size={20} />
              <Text variant="muted">{t('versionGate.force.securityNote')}</Text>
            </View>
          )}
          <Text className="text-2xl font-bold text-center">
            {t('versionGate.force.title')}
          </Text>
          <Text variant="muted" className="text-center">
            {t('versionGate.force.subtitle')}
          </Text>

          <Button onPress={handleUpdate} className="w-full">
            {t('versionGate.force.cta.update')}
          </Button>

          <View className="w-full gap-3 mt-8">
            <Text variant="muted" className="text-sm uppercase tracking-wide">
              {t('versionGate.force.yourData')}
            </Text>

            {isLoggedIn ? (
              <>
                <Button
                  variant="secondary"
                  onPress={handleExport}
                  loading={exportData.isPending}
                >
                  {t('versionGate.force.cta.export')}
                </Button>
                <Button
                  variant="ghost"
                  onPress={() => setDeleteDialogOpen(true)}
                  loading={deleteAccount.isPending}
                >
                  {t('versionGate.force.cta.deleteAccount')}
                </Button>
              </>
            ) : (
              <Text variant="muted" className="text-sm">
                {t('versionGate.force.cta.signInToManageData')}
              </Text>
            )}
          </View>
        </View>
      </ScrollView>

      <ConfirmTypedDialog
        visible={deleteDialogOpen}
        title={t('cloud.delete_account.confirm_title')}
        message={t('cloud.delete_account.confirm_message')}
        typedConfirmation={t('cloud.delete_account.typed_word')}
        confirmLabel={t('cloud.delete_account.cta_confirm')}
        cancelLabel={t('common.cancel')}
        onConfirm={handleDeleteConfirmed}
        onCancel={() => setDeleteDialogOpen(false)}
      />
    </Surface>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `pnpm typecheck`
Expected: PASS. If `<Text variant="muted">` or some prop typing complains, inspect `src/ui/primitives/text.tsx` and adjust to the actual variant names — the file structure should already exist; do **not** invent variants.

- [ ] **Step 3: Commit**

```bash
git add src/ui/version-gate/force-update-screen.tsx
git commit -m "feat(version-gate): add ForceUpdateScreen with RGPD escape hatch"
```

---

## Task 12: UI — `<SoftUpdateModal />`

**Files:**
- Create: `src/ui/version-gate/soft-update-modal.tsx`

A native `<Modal>` is fine. Spec calls for "modal centrée, dismissable" with snooze + open-store CTAs.

- [ ] **Step 1: Implement**

```tsx
// src/ui/version-gate/soft-update-modal.tsx
import { Linking, Modal, View } from 'react-native';
import * as Sentry from '@sentry/react-native';
import { useTranslation } from 'react-i18next';
import { AlertTriangle } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';

interface Props {
  visible: boolean;
  latestVersion: string;
  releaseNotesFr: string | null;
  security: boolean;
  storeUrl: string;
  onSnooze: () => void;
}

export function SoftUpdateModal({
  visible,
  latestVersion,
  releaseNotesFr,
  security,
  storeUrl,
  onSnooze,
}: Props) {
  const { t } = useTranslation();

  const handleUpdate = () => {
    Sentry.addBreadcrumb({
      category: 'version-gate',
      message: 'version-gate.action',
      data: { kind: 'open-store', latestVersion },
    });
    void Linking.openURL(storeUrl);
  };

  const handleSnooze = () => {
    Sentry.addBreadcrumb({
      category: 'version-gate',
      message: 'version-gate.action',
      data: { kind: 'snooze', latestVersion },
    });
    onSnooze();
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={handleSnooze}
    >
      <View className="flex-1 items-center justify-center bg-black/40 px-6">
        <Surface className="w-full rounded-2xl p-6 gap-4">
          <Text className="text-xl font-bold">{t('versionGate.soft.title')}</Text>

          {security && (
            <View className="flex-row items-center gap-2">
              <AlertTriangle size={16} />
              <Text variant="muted" className="text-sm">
                {t('versionGate.soft.securityNote')}
              </Text>
            </View>
          )}

          <Text variant="muted">
            {releaseNotesFr ?? t('versionGate.soft.fallbackNotes')}
          </Text>

          <View className="flex-row gap-3 justify-end mt-2">
            <Button variant="ghost" onPress={handleSnooze}>
              {t('versionGate.soft.cta.later')}
            </Button>
            <Button onPress={handleUpdate}>{t('versionGate.soft.cta.update')}</Button>
          </View>
        </Surface>
      </View>
    </Modal>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `pnpm typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add src/ui/version-gate/soft-update-modal.tsx
git commit -m "feat(version-gate): add SoftUpdateModal"
```

---

## Task 13: UI — `<VersionGateProvider />`

**Files:**
- Create: `src/ui/version-gate/version-gate-provider.tsx`

Wires together `useVersionGate`, the snooze hook, and the two screens.

- [ ] **Step 1: Implement**

```tsx
// src/ui/version-gate/version-gate-provider.tsx
import type { ReactNode } from 'react';
import { useVersionGate } from '@/state/hooks/use-version-gate';
import { useSoftUpdateSnooze } from '@/state/hooks/use-soft-update-snooze';
import { ForceUpdateScreen } from './force-update-screen';
import { SoftUpdateModal } from './soft-update-modal';

export function VersionGateProvider({ children }: { children: ReactNode }) {
  const gate = useVersionGate();
  const { loaded: snoozeLoaded, isSnoozed, snoozeFor } = useSoftUpdateSnooze();

  // While the gate query is in-flight or the snooze record is loading, render
  // nothing. The Expo splash screen is still visible, so the user sees a
  // single static splash instead of a flash of UI.
  if (gate.kind === 'loading' || !snoozeLoaded) return null;

  const decision = gate.decision;

  if (decision.kind === 'force-update') {
    return (
      <ForceUpdateScreen storeUrl={decision.storeUrl} security={false} />
    );
  }

  if (decision.kind === 'soft-update' && !isSnoozed(decision.latest)) {
    return (
      <>
        {children}
        <SoftUpdateModal
          visible
          latestVersion={decision.latest}
          releaseNotesFr={decision.releaseNotesFr}
          security={decision.security}
          storeUrl={decision.storeUrl}
          onSnooze={() => void snoozeFor(decision.latest)}
        />
      </>
    );
  }

  return <>{children}</>;
}
```

Note: `ForceUpdateScreen` receives `security={false}` because the spec defines `security_flag` as a hint relevant to **soft** updates only — when force-update is triggered, the screen is already maximally insistent. If you want a security badge on the force screen too, plumb `security` through `VersionDecision.force-update` (currently absent — leave it out per YAGNI, the spec already concluded this).

- [ ] **Step 2: Typecheck**

Run: `pnpm typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add src/ui/version-gate/version-gate-provider.tsx
git commit -m "feat(version-gate): add VersionGateProvider"
```

---

## Task 14: Mount the gate in `app/_layout.tsx`

**Files:**
- Modify: `app/_layout.tsx`

Wrap `<Stack>` so the gate runs even pre-login. Place it inside `<NavThemeProvider>` so the screens can read the resolved theme, but **outside** `<Stack>` so a force-update never mounts the router.

- [ ] **Step 1: Edit `app/_layout.tsx`**

Add the import near the other `@/ui/...` imports:

```tsx
import { VersionGateProvider } from '@/ui/version-gate/version-gate-provider';
```

Then wrap the existing `<Stack>` (and the keep-it-with-stack `<ToastContainer/>` only if you want toasts visible behind the soft modal — leave `<ToastContainer/>` outside since RGPD actions on the force screen also need toasts). Replace this block in `App()`:

```tsx
        <Stack screenOptions={{ headerShown: false }}>
          <Stack.Screen name="index" />
          <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
          <Stack.Screen name="onboarding" options={{ headerShown: false, animation: 'fade' }} />
          <Stack.Screen name="auth" options={{ headerShown: false, presentation: 'modal' }} />
        </Stack>
        <ToastContainer />
```

with:

```tsx
        <VersionGateProvider>
          <Stack screenOptions={{ headerShown: false }}>
            <Stack.Screen name="index" />
            <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
            <Stack.Screen name="onboarding" options={{ headerShown: false, animation: 'fade' }} />
            <Stack.Screen name="auth" options={{ headerShown: false, presentation: 'modal' }} />
          </Stack>
        </VersionGateProvider>
        <ToastContainer />
```

- [ ] **Step 2: Typecheck**

Run: `pnpm typecheck`
Expected: PASS.

- [ ] **Step 3: Lint**

Run: `pnpm lint`
Expected: PASS.

- [ ] **Step 4: Run the full test suite**

Run: `pnpm test`
Expected: vitest + jest both PASS.

- [ ] **Step 5: Commit**

```bash
git add app/_layout.tsx
git commit -m "feat(version-gate): mount gate provider in root layout"
```

---

## Task 15: Manual device verification

Not committed to git — it's a runbook to follow on device.

Pre-conditions:
- Edge function deployed (Task 3 step 2).
- Table seeded with the current installed version on both platforms (Task 2 step 3).
- `EXPO_PUBLIC_VERSION_CHECK_URL` set in `.env`.

- [ ] **A. OK path** — installed version === seeded version.

Run: `pnpm start`. Open on a device. Expected: app boots into the normal first screen, no modal, no blocker. Sentry breadcrumb `version-gate.check.success` with `decision: 'ok'` appears in Sentry → Issues → any captured event's breadcrumbs.

- [ ] **B. Soft path** — bump `latest_version` in Supabase to a value greater than installed (e.g. `0.99.0`), keep `min_supported_version` ≤ installed.

Re-launch the app. Expected: `<SoftUpdateModal />` over the home screen, dismissable via "Plus tard". Tap "Mettre à jour" → store URL opens. Tap "Plus tard" → modal closes; close-and-reopen the app → modal does **not** reappear (snooze active for 7 days for that `latestVersion`).

- [ ] **C. Force path** — bump `min_supported_version` above installed (e.g. `0.99.0`).

Cold-launch the app. Expected: `<ForceUpdateScreen />` covers the screen. The Stack is not mounted (you cannot navigate). Verify:
- Tap "Mettre à jour" → store URL opens.
- If signed in: "Exporter mes données" triggers the share sheet. "Supprimer mon compte" opens the typed-confirmation dialog.
- If not signed in (anonymous session only): only the help text "Connectez-vous pour gérer vos données." is shown; no destructive buttons.

- [ ] **D. Offline path** — turn off airplane mode for the first launch (cache primes), then restart with airplane mode ON.

Expected: the previous decision (`ok`, `soft`, or `force`) is honored from the SecureStore cache. A force-update seen previously stays applied offline.

- [ ] **E. Reset table** — restore `min_supported_version === latest_version === <installed>` so that a release of the gate to prod is invisible to existing users.

---

## Self-review

I checked the plan against the spec section-by-section.

**Spec coverage:**
- §3 architecture → Tasks 13–14 mount the provider; matches diagram.
- §4.1 table → Task 2.
- §4.2 edge function → Task 3.
- §5 `evaluateVersionStatus` + types → Tasks 4–5.
- §6.1 `versionConfigRepository` → Task 7 (covers fresh/stale/unavailable, 24h freshness, corrupt cache).
- §6.2 `useVersionGate` → Task 9 (Application.nativeApplicationVersion, AppState debounce 6h, web → ok, unavailable → ok).
- §6.3 `<VersionGateProvider>` → Task 13 (loading hides, force replaces, soft overlays).
- §6.4 `<ForceUpdateScreen />` → Task 11 (3 actions, RGPD escape, signed-in branch).
- §6.5 `<SoftUpdateModal />` → Task 12.
- §6.6 snooze logic → Task 8 (7-day TTL, version-keyed re-prompt).
- §6.7 i18n FR keys → Task 10.
- §7 tests → Tasks 4, 5, 6, 7 — all `tests/domain` (vitest) and `tests/data`/`tests/infra` (jest) cases listed in the spec are mapped.
- §8 Sentry breadcrumbs → wired in Tasks 9 (`check.success`/`check.failure`), 11 + 12 (`action`).
- §9 RGPD → enforced by Task 11 design.
- §10 dep → Task 1.
- §11 plan d'ordre → respected (backend → domain → infra → data → state → UI → mount → verify).

**Placeholder scan:** `<PROJECT-REF>`, `<LATEST>`, `<APP_STORE_URL>`, `<PLAY_STORE_URL>` are deliberate runtime substitutions (the engineer pastes the real values when applying), explicitly described inline. No "TBD"/"TODO". Code blocks are complete in every step.

**Type consistency:** `Platform` is consistently `'ios' | 'android'` (domain type, distinct from `react-native`'s `Platform` which is renamed `RNPlatform` in `use-version-gate.ts`). `VersionConfig`/`VersionDecision`/`RepoResult` field names match between spec, tests, and impls. `getVersionConfig` (data) ≠ `fetchVersionConfig` (infra) — distinct names by design.

No issues found requiring inline fixes.
