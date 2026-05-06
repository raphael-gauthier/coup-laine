import { BackupSnapshotV2Schema, migrateV2ToV3, BackupSnapshotV3Schema, migrateV3ToV4 } from '@/infra/cloud/backup-schema';

describe('migrateV2ToV3', () => {
  const v2Snapshot = {
    schemaVersion: 2 as const,
    createdAt: '2026-04-01T10:00:00Z',
    tables: {
      clients: [],
      species: [],
      animal_categories: [],
      services: [],
      tours: [
        {
          id: 't1',
          scheduledDate: '2026-03-15',
          departureTime: '08:00',
          baseLat: 48.0,
          baseLng: 2.0,
          status: 'completed',
          totalDistanceKm: 25,
          totalDriveSeconds: 1800,
          totalMinutes: 120,
          totalRevenueCents: 4000,
          totalAnimalsCount: 8,
          totalTravelFeeCents: 4000,
          routeGeometry: null,
          notes: null,
          completedAt: '2026-03-15T11:00:00Z',
          createdAt: '2026-03-15T08:00:00Z',
          updatedAt: '2026-03-15T11:00:00Z',
        },
      ],
      tour_stops: [
        {
          id: 's1',
          tourId: 't1',
          clientId: 'c1',
          clientNameSnapshot: 'Test',
          ordering: 0,
          arrivalMinutes: 30,
          departureMinutes: 60,
          estimatedMinutes: 30,
          feeShareCents: 2000,
          plannedServices: '[]',
          actualServices: null,
          notes: null,
          completedAt: '2026-03-15T09:00:00Z',
        },
        {
          id: 's2',
          tourId: 't1',
          clientId: 'c2',
          clientNameSnapshot: null,
          ordering: 1,
          arrivalMinutes: null,
          departureMinutes: null,
          estimatedMinutes: null,
          feeShareCents: null,
          plannedServices: '[]',
          actualServices: null,
          notes: null,
          completedAt: null,
        },
      ],
      manual_history_entries: [
        {
          id: 'e1',
          clientId: 'c1',
          date: '2025-08-10',
          notes: 'old entry',
          services: '[]',
        },
      ],
      distance_matrix: [],
      settings: [],
    },
  };

  it('parses a v2 snapshot', () => {
    const result = BackupSnapshotV2Schema.safeParse(v2Snapshot);
    expect(result.success).toBe(true);
  });

  it('migrates v2 → v3, preserving feeShareCents into travelFeeCents', () => {
    const parsed = BackupSnapshotV2Schema.parse(v2Snapshot);
    const v3 = migrateV2ToV3(parsed);

    expect(v3.schemaVersion).toBe(3);
    expect(v3.createdAt).toBe('2026-04-01T10:00:00Z');

    // tours: totalTravelFeeCents is dropped
    expect(v3.tables.tours[0]).not.toHaveProperty('totalTravelFeeCents');

    // tour_stops: feeShareCents → travelFeeCents
    expect(v3.tables.tour_stops[0]).not.toHaveProperty('feeShareCents');
    expect(v3.tables.tour_stops[0]?.travelFeeCents).toBe(2000);
    expect(v3.tables.tour_stops[1]?.travelFeeCents).toBeNull();

    // manual_history_entries: travelFeeCents added (null)
    expect(v3.tables.manual_history_entries[0]?.travelFeeCents).toBeNull();
  });
});

describe('migrateV3ToV4', () => {
  const v3Snapshot = {
    schemaVersion: 3 as const,
    createdAt: '2026-05-01T10:00:00Z',
    tables: {
      clients: [
        {
          id: 'c1',
          displayName: 'Test',
          phones: '[]',
          addressLabel: null,
          addressCity: null,
          addressPostcode: null,
          latitude: null,
          longitude: null,
          isWaiting: 0,
          isBanned: 0,
          needsDistanceRecompute: 0,
          lastShearingDate: null,
          animalCounts: '[]',
          markerColorHex: null,
          createdAt: '2025-01-01T00:00:00Z',
          updatedAt: '2025-01-01T00:00:00Z',
        },
      ],
      species: [],
      animal_categories: [],
      services: [],
      tours: [],
      tour_stops: [],
      manual_history_entries: [],
      distance_matrix: [],
      settings: [],
    },
  };

  it('parses a v3 snapshot', () => {
    const result = BackupSnapshotV3Schema.safeParse(v3Snapshot);
    expect(result.success).toBe(true);
  });

  it('migrates v3 → v4 by adding anonymizedAt: null to every client', () => {
    const parsed = BackupSnapshotV3Schema.parse(v3Snapshot);
    const v4 = migrateV3ToV4(parsed);

    expect(v4.schemaVersion).toBe(4);
    expect(v4.createdAt).toBe('2026-05-01T10:00:00Z');
    expect(v4.tables.clients[0]?.anonymizedAt).toBeNull();
  });

  it('preserves all other client fields untouched', () => {
    const parsed = BackupSnapshotV3Schema.parse(v3Snapshot);
    const v4 = migrateV3ToV4(parsed);
    const client = v4.tables.clients[0];
    expect(client?.id).toBe('c1');
    expect(client?.displayName).toBe('Test');
    expect(client?.markerColorHex).toBeNull();
    expect(client?.createdAt).toBe('2025-01-01T00:00:00Z');
  });
});
