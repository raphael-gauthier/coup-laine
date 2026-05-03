import { describe, it, expect } from 'vitest';
import { computeClientStatus } from '@/domain/use-cases/client-status';

const SEASON = '2026-05-01';

describe('computeClientStatus (6-status)', () => {
  it('returns "banned" when isBanned is true (overrides everything)', () => {
    expect(
      computeClientStatus({
        isBanned: true,
        isWaiting: true,
        animalsTotal: 12,
        seasonStartedAt: SEASON,
        completedTourDates: ['2026-05-15'],
        plannedTourDates: ['2026-06-01'],
      })
    ).toBe('banned');
  });

  it('returns "noAnimals" when animalsTotal is 0 (and not banned)', () => {
    expect(
      computeClientStatus({
        isBanned: false,
        isWaiting: false,
        animalsTotal: 0,
        seasonStartedAt: SEASON,
        completedTourDates: [],
        plannedTourDates: [],
      })
    ).toBe('noAnimals');
  });

  it('returns "done" if any completed tour date ≥ seasonStartedAt', () => {
    expect(
      computeClientStatus({
        isBanned: false,
        isWaiting: true, // overridden by done
        animalsTotal: 12,
        seasonStartedAt: SEASON,
        completedTourDates: ['2026-05-15'],
        plannedTourDates: [],
      })
    ).toBe('done');
  });

  it('does not return "done" for completed tours before seasonStartedAt', () => {
    expect(
      computeClientStatus({
        isBanned: false,
        isWaiting: true,
        animalsTotal: 12,
        seasonStartedAt: SEASON,
        completedTourDates: ['2025-04-15'], // last season
        plannedTourDates: [],
      })
    ).toBe('waiting'); // not done; isWaiting wins
  });

  it('returns "scheduled" if a planned tour for this season exists and not done', () => {
    expect(
      computeClientStatus({
        isBanned: false,
        isWaiting: false,
        animalsTotal: 12,
        seasonStartedAt: SEASON,
        completedTourDates: [],
        plannedTourDates: ['2026-06-01'],
      })
    ).toBe('scheduled');
  });

  it('returns "waiting" when isWaiting and no scheduled/done', () => {
    expect(
      computeClientStatus({
        isBanned: false,
        isWaiting: true,
        animalsTotal: 12,
        seasonStartedAt: SEASON,
        completedTourDates: [],
        plannedTourDates: [],
      })
    ).toBe('waiting');
  });

  it('returns "default" when no other condition applies', () => {
    expect(
      computeClientStatus({
        isBanned: false,
        isWaiting: false,
        animalsTotal: 12,
        seasonStartedAt: SEASON,
        completedTourDates: [],
        plannedTourDates: [],
      })
    ).toBe('default');
  });
});
