interface ClientPoint {
  id: string;
  latitude: number | null;
  longitude: number | null;
}

interface Input {
  clients: ClientPoint[];
  /** Set of `${fromId}-${toId}` pairs present in the matrix. */
  matrixPairs: Set<string>;
}

/**
 * Returns the list of client IDs that have coordinates but lack a BASE↔client
 * matrix entry. The caller flips `clients.needsDistanceRecompute = true` for
 * each, which surfaces the recompute banner.
 */
export function findClientsNeedingRecompute({ clients, matrixPairs }: Input): string[] {
  return clients
    .filter((c) => c.latitude != null && c.longitude != null)
    .filter((c) => !matrixPairs.has(`BASE-${c.id}`) || !matrixPairs.has(`${c.id}-BASE`))
    .map((c) => c.id);
}
