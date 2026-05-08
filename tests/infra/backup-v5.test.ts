import { describe, it, expect } from '@jest/globals';
import { migrateV4ToV5 } from '@/infra/cloud/backup-schema';
import type { ValidatedBackupSnapshotV4 } from '@/infra/cloud/backup-schema';

const baseV4: ValidatedBackupSnapshotV4 = {
  schemaVersion: 4,
  createdAt: '2026-05-08T00:00:00.000Z',
  tables: {
    clients: [],
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

describe('migrateV4ToV5', () => {
  it('seeds 6 system statuses without overrides', () => {
    const v5 = migrateV4ToV5(baseV4);
    expect(v5.schemaVersion).toBe(5);
    expect(v5.tables.statuses).toHaveLength(6);
    const def = v5.tables.statuses.find((s) => s.systemKey === 'default')!;
    expect(def.colorLight).toBe('#94A3B8');
    expect(def.colorDark).toBe('#64748B');
  });

  it('carries marker_*_color into both light and dark and strips the legacy keys', () => {
    const v4: ValidatedBackupSnapshotV4 = {
      ...baseV4,
      tables: {
        ...baseV4.tables,
        settings: [
          { key: 'marker_waiting_color', value: '#FF00FF' },
          { key: 'season_started_at', value: '2025-05-01' },
        ],
      },
    };
    const v5 = migrateV4ToV5(v4);
    const waiting = v5.tables.statuses.find((s) => s.systemKey === 'waiting')!;
    expect(waiting.colorLight).toBe('#FF00FF');
    expect(waiting.colorDark).toBe('#FF00FF');
    expect(v5.tables.settings.find((s) => s.key === 'marker_waiting_color')).toBeUndefined();
    expect(v5.tables.settings.find((s) => s.key === 'season_started_at')).toBeDefined();
  });

  it('sets manualStatusId to null on every restored client', () => {
    const v4: ValidatedBackupSnapshotV4 = {
      ...baseV4,
      tables: {
        ...baseV4.tables,
        clients: [{
          id: 'c1', displayName: 'A', phones: '[]',
          addressLabel: null, addressCity: null, addressPostcode: null,
          latitude: null, longitude: null,
          isWaiting: 0, isBanned: 0, needsDistanceRecompute: 0,
          lastShearingDate: null, animalCounts: '[]',
          markerColorHex: null, anonymizedAt: null,
          createdAt: '2026-05-08T00:00:00.000Z', updatedAt: '2026-05-08T00:00:00.000Z',
        }],
      },
    };
    const v5 = migrateV4ToV5(v4);
    expect(v5.tables.clients[0].manualStatusId).toBeNull();
  });
});
