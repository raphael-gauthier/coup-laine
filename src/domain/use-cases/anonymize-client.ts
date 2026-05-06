import type { Client } from '@/domain/models/client';

export const ANONYMIZED_DISPLAY_NAME = 'Client supprimé';

export interface AnonymizableStop {
  id: string;
  clientId: string;
}

export interface AnonymizableEntry {
  id: string;
  clientId: string;
}

export interface AnonymizableDmEntry {
  fromId: string;
  toId: string;
}

export interface AnonymizationPlan {
  client: { id: string; updates: Partial<Client> };
  tourStopUpdates: { id: string; clientNameSnapshot: string; notes: null }[];
  manualEntryUpdates: { id: string; notes: null }[];
  distanceMatrixDeletes: { fromId: string; toId: string }[];
}

export function planAnonymization(
  client: Client,
  tourStops: AnonymizableStop[],
  manualEntries: AnonymizableEntry[],
  distanceMatrix: AnonymizableDmEntry[],
  now: string,
): AnonymizationPlan {
  if (client.anonymizedAt != null) {
    return {
      client: { id: client.id, updates: {} },
      tourStopUpdates: [],
      manualEntryUpdates: [],
      distanceMatrixDeletes: [],
    };
  }

  return {
    client: {
      id: client.id,
      updates: {
        displayName: ANONYMIZED_DISPLAY_NAME,
        phones: [],
        addressLabel: null,
        addressCity: null,
        addressPostcode: null,
        latitude: null,
        longitude: null,
        animalCounts: [],
        isWaiting: false,
        isBanned: false,
        needsDistanceRecompute: false,
        anonymizedAt: now,
      },
    },
    tourStopUpdates: tourStops
      .filter((s) => s.clientId === client.id)
      .map((s) => ({ id: s.id, clientNameSnapshot: ANONYMIZED_DISPLAY_NAME, notes: null })),
    manualEntryUpdates: manualEntries
      .filter((e) => e.clientId === client.id)
      .map((e) => ({ id: e.id, notes: null })),
    distanceMatrixDeletes: distanceMatrix
      .filter((d) => d.fromId === client.id || d.toId === client.id)
      .map((d) => ({ fromId: d.fromId, toId: d.toId })),
  };
}
