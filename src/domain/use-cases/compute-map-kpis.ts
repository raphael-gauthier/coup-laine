import type { Status } from '@/domain/models/status';

interface Input {
  statusByClientId: Map<string, Status>;
}

export type MapKpis = Map<string, number>;

export function computeMapKpis({ statusByClientId }: Input): MapKpis {
  const out = new Map<string, number>();
  for (const status of statusByClientId.values()) {
    out.set(status.id, (out.get(status.id) ?? 0) + 1);
  }
  return out;
}
