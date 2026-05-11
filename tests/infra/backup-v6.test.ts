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

describe('round-trip preservation', () => {
  it('parses a v6 snapshot with tutorial_progress rows and preserves them', () => {
    const snapshot = {
      schemaVersion: 6 as const,
      createdAt: '2026-05-11T10:00:00.000Z',
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
        tutorial_progress: [
          { key: 'sheet.clients', seenAt: '2026-05-11T10:00:00.000Z' },
          { key: 'coachmark.first_client', seenAt: '2026-05-11T11:00:00.000Z' },
        ],
      },
    };
    const parsed = BackupSnapshotV6Schema.parse(snapshot);
    expect(parsed.tables.tutorial_progress).toEqual(snapshot.tables.tutorial_progress);
  });
});

describe('unknown-key tolerance at the schema layer', () => {
  it('parses a v6 snapshot containing an unknown tutorial key (the wipeAndRestore loop filters at restore-time)', () => {
    const snapshot = {
      schemaVersion: 6 as const,
      createdAt: '2026-05-11T10:00:00.000Z',
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
        tutorial_progress: [
          { key: 'sheet.from-the-future', seenAt: '2026-05-11T10:00:00.000Z' },
        ],
      },
    };
    // The schema is permissive — validation of known-keys happens via validateTutorialKey
    // in src/infra/cloud/backups.ts at restore time, not in the schema itself.
    const parsed = BackupSnapshotV6Schema.parse(snapshot);
    expect(parsed.tables.tutorial_progress).toHaveLength(1);
    expect(parsed.tables.tutorial_progress[0]?.key).toBe('sheet.from-the-future');
  });
});
