import { describe, it, expect } from 'vitest';
import { assertTourInvariants } from '@/domain/use-cases/assert-tour-invariants';
import type { Tour } from '@/domain/models/tour';

const baseTour: Tour = {
  id: 't1',
  scheduledDate: null,
  departureTime: null,
  title: null,
  baseLat: 48,
  baseLng: -3,
  status: 'draft',
  totalDistanceKm: null,
  totalDriveSeconds: null,
  totalMinutes: null,
  totalRevenueCents: null,
  totalAnimalsCount: null,
  routeGeometry: null,
  notes: null,
  completedAt: null,
  createdAt: '2026-05-08T12:00:00.000Z',
  updatedAt: '2026-05-08T12:00:00.000Z',
};

describe('assertTourInvariants', () => {
  it('accepts a draft with both date and time null', () => {
    expect(() => assertTourInvariants(baseTour)).not.toThrow();
  });

  it('accepts a planned with both date and time set', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'planned',
        scheduledDate: '2026-05-10',
        departureTime: '08:00',
      }),
    ).not.toThrow();
  });

  it('accepts a completed with both date and time set', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'completed',
        scheduledDate: '2026-05-10',
        departureTime: '08:00',
        completedAt: '2026-05-10T17:00:00.000Z',
      }),
    ).not.toThrow();
  });

  it('throws when planned has scheduledDate null', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'planned',
        scheduledDate: null,
        departureTime: '08:00',
      }),
    ).toThrow(/requires scheduledDate and departureTime/);
  });

  it('throws when planned has departureTime null', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'planned',
        scheduledDate: '2026-05-10',
        departureTime: null,
      }),
    ).toThrow(/requires scheduledDate and departureTime/);
  });

  it('throws when completed has scheduledDate null', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'completed',
        scheduledDate: null,
        departureTime: '08:00',
      }),
    ).toThrow(/requires scheduledDate and departureTime/);
  });

  it('throws when draft has scheduledDate set', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'draft',
        scheduledDate: '2026-05-10',
      }),
    ).toThrow(/draft must not carry scheduledDate or departureTime/);
  });

  it('throws when draft has departureTime set', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'draft',
        departureTime: '08:00',
      }),
    ).toThrow(/draft must not carry scheduledDate or departureTime/);
  });
});
