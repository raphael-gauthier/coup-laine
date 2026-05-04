import type { Service } from '@/domain/models/service';
import type { TourStopService } from '@/domain/models/tour-stop-service';

interface InterventionItem {
  date: string;
  services: TourStopService[];
}

interface Input {
  services: Service[];
  thisMonthInterventions: InterventionItem[];
  today: string;
}

export interface ServiceKpis {
  activeCount: number;
  archivedCount: number;
  monthRevenueCents: number;
}

export function computeServiceKpis({ services, thisMonthInterventions, today }: Input): ServiceKpis {
  const activeCount = services.filter((p) => p.archivedAt == null).length;
  const archivedCount = services.filter((p) => p.archivedAt != null).length;

  const yyyymm = today.slice(0, 7);
  const monthRevenueCents = thisMonthInterventions
    .filter((i) => i.date.slice(0, 7) === yyyymm)
    .reduce(
      (sum, i) => sum + i.services.reduce((s, p) => s + p.qty * p.priceCentsSnapshot, 0),
      0
    );

  return { activeCount, archivedCount, monthRevenueCents };
}
