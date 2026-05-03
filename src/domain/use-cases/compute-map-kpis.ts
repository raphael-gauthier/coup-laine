import type { ClientStatus } from './client-status';

interface Input {
  statusByClientId: Map<string, ClientStatus>;
}

export interface MapKpis {
  total: number;
  default: number;
  waiting: number;
  scheduled: number;
  done: number;
  noAnimals: number;
  banned: number;
}

export function computeMapKpis({ statusByClientId }: Input): MapKpis {
  const result: MapKpis = {
    total: statusByClientId.size,
    default: 0, waiting: 0, scheduled: 0, done: 0, noAnimals: 0, banned: 0,
  };
  for (const status of statusByClientId.values()) {
    result[status]++;
  }
  return result;
}
