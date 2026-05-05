import type { TourStop } from '@/domain/models/tour-stop';
import type { ManualHistoryEntry } from '@/domain/models/manual-history-entry';
import type { TourStopService } from '@/domain/models/tour-stop-service';

export interface ClientOutstanding {
  unpaidCents: number;
  unpaidCount: number;
}

function sumServices(services: TourStopService[]): number {
  let total = 0;
  for (const s of services) {
    if (s.qty <= 0) continue;
    total += s.qty * s.priceCentsSnapshot;
  }
  return total;
}

export function computeClientOutstanding(args: {
  completedStops: TourStop[];
  manualEntries: ManualHistoryEntry[];
}): ClientOutstanding {
  let cents = 0;
  let count = 0;
  for (const stop of args.completedStops) {
    if (stop.payment.isPaid) continue;
    const services = stop.actualServices ?? stop.plannedServices;
    cents += sumServices(services);
    count += 1;
  }
  for (const entry of args.manualEntries) {
    if (entry.payment.isPaid) continue;
    cents += sumServices(entry.services);
    count += 1;
  }
  return { unpaidCents: cents, unpaidCount: count };
}
