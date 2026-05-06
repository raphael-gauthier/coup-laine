import { BackupSnapshotV2Schema, migrateV2ToV3 } from '@/infra/cloud/backup-schema';

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
