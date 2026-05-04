import type { TourStopService } from '@/domain/models/tour-stop-service';

export interface ServiceAggregate {
  serviceId: string;
  name: string;
  totalQty: number;
  totalRevenueCents: number;
  totalMinutes: number;
}

/**
 * Groups services across multiple stops by serviceId, accumulating qty,
 * revenue (qty × priceCentsSnapshot) and minutes (qty × minutesSnapshot).
 * Order: insertion order across the input arrays.
 */
export function aggregateServices(stops: TourStopService[][]): ServiceAggregate[] {
  const order: string[] = [];
  const map = new Map<string, ServiceAggregate>();
  for (const stop of stops) {
    for (const p of stop) {
      let agg = map.get(p.serviceId);
      if (!agg) {
        agg = {
          serviceId: p.serviceId,
          name: p.nameSnapshot,
          totalQty: 0,
          totalRevenueCents: 0,
          totalMinutes: 0,
        };
        map.set(p.serviceId, agg);
        order.push(p.serviceId);
      }
      agg.totalQty += p.qty;
      agg.totalRevenueCents += p.qty * p.priceCentsSnapshot;
      agg.totalMinutes += p.qty * p.minutesSnapshot;
    }
  }
  return order.map((id) => map.get(id)!);
}
