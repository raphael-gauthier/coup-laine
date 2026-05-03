import { describe, it, expect } from 'vitest';
import { computeTourKpis } from '@/domain/use-cases/compute-tour-kpis';
import type { TourStopPrestation } from '@/domain/models/tour-stop-prestation';

const ps = (over: Partial<TourStopPrestation>): TourStopPrestation => ({
  prestationId: 'shearing', qty: 1,
  nameSnapshot: 'Tonte', priceCentsSnapshot: 0, minutesSnapshot: 0,
  categoryIdSnapshot: null, categoryNameSnapshot: null, speciesNameSnapshot: null,
  ...over,
});

describe('computeTourKpis', () => {
  it('zeros for an empty tour', () => {
    expect(
      computeTourKpis({
        stops: [],
        totalDistanceKm: 0,
        totalDriveSeconds: 0,
        totalTravelFeeCents: 0,
        animalCountsByClient: new Map(),
      })
    ).toEqual({
      stopCount: 0,
      animalsTotal: 0,
      revenueCents: 0,
      durationMinutes: 0,
      driveMinutes: 0,
      travelFeeCents: 0,
      distanceKm: 0,
      prestationAggregates: [],
    });
  });

  it('aggregates across stops', () => {
    const r = computeTourKpis({
      stops: [
        { clientId: 'c1', plannedPrestations: [ps({ qty: 5, priceCentsSnapshot: 800, minutesSnapshot: 20 })] },
        { clientId: 'c2', plannedPrestations: [ps({ qty: 3, priceCentsSnapshot: 800, minutesSnapshot: 20 })] },
      ],
      totalDistanceKm: 25,
      totalDriveSeconds: 1800,
      totalTravelFeeCents: 4000,
      animalCountsByClient: new Map([
        ['c1', 5],
        ['c2', 3],
      ]),
    });
    expect(r.stopCount).toBe(2);
    expect(r.animalsTotal).toBe(8);
    expect(r.revenueCents).toBe(8 * 800);
    expect(r.distanceKm).toBe(25);
    expect(r.driveMinutes).toBe(30);
    expect(r.travelFeeCents).toBe(4000);
    expect(r.durationMinutes).toBe(30 + 8 * 20); // drive + service
    expect(r.prestationAggregates).toHaveLength(1);
    expect(r.prestationAggregates[0]?.totalQty).toBe(8);
  });
});
