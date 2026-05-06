import type { TourStop } from '@/domain/models/tour-stop';
import type { TourStopService } from '@/domain/models/tour-stop-service';

export interface TourPaymentKpis {
  collectedCents: number;
  outstandingCents: number;
}

function sumServices(services: TourStopService[]): number {
  let total = 0;
  for (const s of services) {
    if (s.qty <= 0) continue;
    total += s.qty * s.priceCentsSnapshot;
  }
  return total;
}

export function computeTourPaymentKpis(args: { stops: TourStop[] }): TourPaymentKpis {
  let collected = 0;
  let outstanding = 0;
  for (const stop of args.stops) {
    const services = stop.actualServices ?? stop.plannedServices;
    const value = sumServices(services) + (stop.travelFeeCents ?? 0);
    if (stop.payment.isPaid) collected += value;
    else outstanding += value;
  }
  return { collectedCents: collected, outstandingCents: outstanding };
}
