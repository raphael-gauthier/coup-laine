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
      security: false,
      storeUrl: 'https://apps.apple.com/app/id123',
    });
  });

  it('propagates security flag on force-update', () => {
    const decision = evaluateVersionStatus('0.9.0', { ...baseConfig, securityFlag: true });
    expect(decision).toMatchObject({ kind: 'force-update', security: true });
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
