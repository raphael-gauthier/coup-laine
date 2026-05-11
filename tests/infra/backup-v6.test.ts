import { describe, it, expect } from '@jest/globals';
import {
  migrateV5ToV6,
  BackupSnapshotV6Schema,
  type ValidatedBackupSnapshotV5,
} from '@/infra/cloud/backup-schema';

const baseV5: ValidatedBackupSnapshotV5 = {
  schemaVersion: 5,
  createdAt: '2026-05-11T00:00:00.000Z',
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
    statuses: [],
  },
};

describe('migrateV5ToV6', () => {
  it('initialises tutorial_progress to an empty array', () => {
    const v6 = migrateV5ToV6(baseV5);
    expect(v6.schemaVersion).toBe(6);
    expect(v6.tables.tutorial_progress).toEqual([]);
  });

  it('preserves all other tables verbatim', () => {
    const v6 = migrateV5ToV6(baseV5);
    expect(v6.tables.statuses).toBe(baseV5.tables.statuses);
    expect(v6.createdAt).toBe(baseV5.createdAt);
  });
});

describe('BackupSnapshotV6Schema', () => {
  it('parses a well-formed v6 snapshot with tutorial_progress entries', () => {
    const parsed = BackupSnapshotV6Schema.parse({
      ...baseV5,
      schemaVersion: 6,
      tables: {
        ...baseV5.tables,
        tutorial_progress: [
          { key: 'sheet.clients', seenAt: '2026-05-11T10:00:00.000Z' },
        ],
      },
    });
    expect(parsed.tables.tutorial_progress).toHaveLength(1);
  });
});
