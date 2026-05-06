import { describe, it, expect } from 'vitest';
import { computeTourKpis } from '@/domain/use-cases/compute-tour-kpis';
import type { TourStopService } from '@/domain/models/tour-stop-service';

const ps = (over: Partial<TourStopService>): TourStopService => ({
  serviceId: 'shearing', qty: 1,
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
      serviceAggregates: [],
    });
  });

  it('aggregates services + per-stop travel fees, includes fees in revenue', () => {
    const r = computeTourKpis({
      stops: [
        { clientId: 'c1', plannedServices: [ps({ qty: 5, priceCentsSnapshot: 800, minutesSnapshot: 20 })], travelFeeCents: 1500 },
        { clientId: 'c2', plannedServices: [ps({ qty: 3, priceCentsSnapshot: 800, minutesSnapshot: 20 })], travelFeeCents: null },
      ],
      totalDistanceKm: 25,
      totalDriveSeconds: 1800,
      animalCountsByClient: new Map([
        ['c1', 5],
        ['c2', 3],
      ]),
    });
    expect(r.stopCount).toBe(2);
    expect(r.animalsTotal).toBe(8);
    // services: 8 * 800 = 6400 ; fees: 1500 ; revenue includes both => 7900
    expect(r.revenueCents).toBe(7900);
    expect(r.travelFeeCents).toBe(1500);
    expect(r.distanceKm).toBe(25);
    expect(r.driveMinutes).toBe(30);
    expect(r.durationMinutes).toBe(30 + 8 * 20);
    expect(r.serviceAggregates).toHaveLength(1);
    expect(r.serviceAggregates[0]?.totalQty).toBe(8);
  });
});
