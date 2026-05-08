import { asc, desc, eq } from 'drizzle-orm';
import { tours, tourStops } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { Tour, type TourStatus } from '@/domain/models/tour';
import { TourStop } from '@/domain/models/tour-stop';
import { Payment } from '@/domain/models/payment';

interface TourRow {
  id: string;
  scheduledDate: string | null;
  departureTime: string | null;
  title: string | null;
  baseLat: number;
  baseLng: number;
  status: string;
  totalDistanceKm: number | null;
  totalDriveSeconds: number | null;
  totalMinutes: number | null;
  totalRevenueCents: number | null;
  totalAnimalsCount: number | null;
  routeGeometry: string | null;
  notes: string | null;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

interface TourStopRow {
  id: string;
  tourId: string;
  clientId: string;
  clientNameSnapshot: string | null;
  ordering: number;
  arrivalMinutes: number | null;
  departureMinutes: number | null;
  estimatedMinutes: number | null;
  travelFeeCents: number | null;
  plannedServices: string;
  actualServices: string | null;
  notes: string | null;
  completedAt: string | null;
  paymentMethodId: string | null;
  paymentMethodLabelSnapshot: string | null;
  isPaid: number;
  paidAt: string | null;
}

function tourFromRow(r: TourRow): Tour {
  return Tour.parse(r);
}

function stopToRow(s: TourStop) {
  return {
    id: s.id,
    tourId: s.tourId,
    clientId: s.clientId,
    clientNameSnapshot: s.clientNameSnapshot,
    ordering: s.ordering,
    arrivalMinutes: s.arrivalMinutes,
    departureMinutes: s.departureMinutes,
    estimatedMinutes: s.estimatedMinutes,
    travelFeeCents: s.travelFeeCents,
    plannedServices: JSON.stringify(s.plannedServices),
    actualServices: s.actualServices === null ? null : JSON.stringify(s.actualServices),
    notes: s.notes,
    completedAt: s.completedAt,
    paymentMethodId: s.payment.methodId,
    paymentMethodLabelSnapshot: s.payment.methodLabelSnapshot,
    isPaid: s.payment.isPaid ? 1 : 0,
    paidAt: s.payment.paidAt,
  };
}

function stopFromRow(r: TourStopRow): TourStop {
  return TourStop.parse({
    id: r.id,
    tourId: r.tourId,
    clientId: r.clientId,
    clientNameSnapshot: r.clientNameSnapshot,
    ordering: r.ordering,
    arrivalMinutes: r.arrivalMinutes,
    departureMinutes: r.departureMinutes,
    estimatedMinutes: r.estimatedMinutes,
    travelFeeCents: r.travelFeeCents,
    plannedServices: JSON.parse(r.plannedServices),
    actualServices: r.actualServices === null ? null : JSON.parse(r.actualServices),
    notes: r.notes,
    completedAt: r.completedAt,
    payment: {
      methodId: r.paymentMethodId,
      methodLabelSnapshot: r.paymentMethodLabelSnapshot,
      isPaid: r.isPaid === 1,
      paidAt: r.paidAt,
    },
  });
}

export interface TourWithStops {
  tour: Tour;
  stops: TourStop[];
}

export class TourRepository {
  constructor(private readonly db: Db) {}

  async byId(id: string): Promise<TourWithStops | null> {
    const tRows = await this.db.select().from(tours).where(eq(tours.id, id));
    if (!tRows[0]) return null;
    const sRows = await this.db
      .select()
      .from(tourStops)
      .where(eq(tourStops.tourId, id))
      .orderBy(asc(tourStops.ordering));
    return {
      tour: tourFromRow(tRows[0] as TourRow),
      stops: sRows.map((r) => stopFromRow(r as TourStopRow)),
    };
  }

  async listAll(): Promise<TourWithStops[]> {
    const tRows = await this.db.select().from(tours);
    const result: TourWithStops[] = [];
    for (const tr of tRows) {
      const sRows = await this.db
        .select()
        .from(tourStops)
        .where(eq(tourStops.tourId, (tr as TourRow).id))
        .orderBy(asc(tourStops.ordering));
      result.push({
        tour: tourFromRow(tr as TourRow),
        stops: sRows.map((r) => stopFromRow(r as TourStopRow)),
      });
    }
    return result;
  }

  async listByStatus(status: TourStatus): Promise<TourWithStops[]> {
    const orderColumn = (() => {
      switch (status) {
        case 'draft':     return desc(tours.updatedAt);
        case 'planned':   return asc(tours.scheduledDate);
        case 'completed': return desc(tours.scheduledDate);
      }
    })();
    const tRows = await this.db
      .select()
      .from(tours)
      .where(eq(tours.status, status))
      .orderBy(orderColumn);

    const result: TourWithStops[] = [];
    for (const tr of tRows) {
      const sRows = await this.db
        .select()
        .from(tourStops)
        .where(eq(tourStops.tourId, (tr as TourRow).id))
        .orderBy(asc(tourStops.ordering));
      result.push({
        tour: tourFromRow(tr as TourRow),
        stops: sRows.map((r) => stopFromRow(r as TourStopRow)),
      });
    }
    return result;
  }

  async upsertTour(t: Tour, stops: TourStop[]): Promise<void> {
    await this.db.insert(tours).values(t).onConflictDoUpdate({ target: tours.id, set: t });
    await this.db.delete(tourStops).where(eq(tourStops.tourId, t.id));
    for (const s of stops) {
      await this.db.insert(tourStops).values(stopToRow(s));
    }
  }

  async deleteTour(id: string): Promise<void> {
    await this.db.delete(tours).where(eq(tours.id, id));
  }

  async markStopCompleted(stopId: string, completedAt: string): Promise<void> {
    await this.db.update(tourStops).set({ completedAt }).where(eq(tourStops.id, stopId));
  }

  async markStopPayment(stopId: string, payment: Payment): Promise<void> {
    await this.db.update(tourStops).set({
      paymentMethodId: payment.methodId,
      paymentMethodLabelSnapshot: payment.methodLabelSnapshot,
      isPaid: payment.isPaid ? 1 : 0,
      paidAt: payment.paidAt,
    }).where(eq(tourStops.id, stopId));
  }

  async completeWithBilan(
    tourId: string,
    perStopActuals: Map<string, import('@/domain/models/tour-stop-service').TourStopService[]>,
    perStopNotes: Map<string, string | null>,
    perStopPayments: Map<string, Payment>,
    perStopTravelFees: Map<string, number>,
    completedAt: string
  ): Promise<void> {
    const result = await this.byId(tourId);
    if (!result) throw new Error('Tour introuvable');
    const { tour, stops } = result;

    const updatedStops = stops.map((s) => ({
      ...s,
      actualServices: perStopActuals.get(s.id) ?? s.plannedServices,
      notes: perStopNotes.has(s.id) ? perStopNotes.get(s.id) ?? null : s.notes,
      payment: perStopPayments.get(s.id) ?? s.payment,
      travelFeeCents: perStopTravelFees.has(s.id) ? perStopTravelFees.get(s.id)! : s.travelFeeCents,
      completedAt,
    }));

    await this.upsertTour(
      { ...tour, status: 'completed', completedAt, updatedAt: completedAt },
      updatedStops
    );
  }
}
