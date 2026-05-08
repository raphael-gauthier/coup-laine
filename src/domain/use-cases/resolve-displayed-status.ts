import type { Status, SystemStatusKey } from '@/domain/models/status';

export interface StatusRegistryLookup {
  bySystemKey(key: SystemStatusKey): Status | null;
  byId(id: string): Status | null;
}

export function resolveDisplayedStatus(
  client: { manualStatusId: string | null },
  derivedKey: SystemStatusKey,
  registry: StatusRegistryLookup,
): Status {
  if (client.manualStatusId) {
    const manual = registry.byId(client.manualStatusId);
    if (manual && manual.kind === 'manual') return manual;
  }
  const sys = registry.bySystemKey(derivedKey);
  if (!sys) {
    throw new Error(`System status row missing for key: ${derivedKey}`);
  }
  return sys;
}
