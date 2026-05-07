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
