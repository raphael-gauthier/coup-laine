import { asc, eq } from 'drizzle-orm';
import { tours, tourStops } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { Tour, type TourStatus } from '@/domain/models/tour';
import { TourStop } from '@/domain/models/tour-stop';

interface TourRow {
  id: string;
  scheduledDate: string;
  departureTime: string;
  baseLat: number;
  baseLng: number;
  status: string;
  totalDistanceKm: number | null;
  totalMinutes: number | null;
  createdAt: string;
  updatedAt: string;
}

interface TourStopRow {
  id: string;
  tourId: string;
  clientId: string;
  ordering: number;
  arrivalTime: string | null;
  estimatedMinutes: number | null;
  prestations: string;
  notes: string | null;
  completedAt: string | null;
}

function tourFromRow(r: TourRow): Tour {
  return Tour.parse(r);
}

function stopToRow(s: TourStop) {
  return { ...s, prestations: JSON.stringify(s.prestations) };
}
function stopFromRow(r: TourStopRow): TourStop {
  return TourStop.parse({ ...r, prestations: JSON.parse(r.prestations) });
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
    const tRows = await this.db.select().from(tours).where(eq(tours.status, status));
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
}
