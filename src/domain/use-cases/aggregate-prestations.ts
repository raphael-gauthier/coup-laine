import type { TourStopPrestation } from '@/domain/models/tour-stop-prestation';

export interface PrestationAggregate {
  prestationId: string;
  name: string;
  totalQty: number;
  totalRevenueCents: number;
  totalMinutes: number;
}

/**
 * Groups prestations across multiple stops by prestationId, accumulating qty,
 * revenue (qty × priceCentsSnapshot) and minutes (qty × minutesSnapshot).
 * Order: insertion order across the input arrays.
 */
export function aggregatePrestations(stops: TourStopPrestation[][]): PrestationAggregate[] {
  const order: string[] = [];
  const map = new Map<string, PrestationAggregate>();
  for (const stop of stops) {
    for (const p of stop) {
      let agg = map.get(p.prestationId);
      if (!agg) {
        agg = {
          prestationId: p.prestationId,
          name: p.nameSnapshot,
          totalQty: 0,
          totalRevenueCents: 0,
          totalMinutes: 0,
        };
        map.set(p.prestationId, agg);
        order.push(p.prestationId);
      }
      agg.totalQty += p.qty;
      agg.totalRevenueCents += p.qty * p.priceCentsSnapshot;
      agg.totalMinutes += p.qty * p.minutesSnapshot;
    }
  }
  return order.map((id) => map.get(id)!);
}
