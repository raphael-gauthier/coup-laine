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
  | {
      kind: 'force-update';
      minSupported: string;
      security: boolean;
      storeUrl: string;
    };
