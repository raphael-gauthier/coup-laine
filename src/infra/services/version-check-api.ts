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
