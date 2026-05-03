import type { Prestation } from '@/domain/models/prestation';
import type { TourStopPrestation } from '@/domain/models/tour-stop-prestation';

interface InterventionItem {
  date: string;
  prestations: TourStopPrestation[];
}

interface Input {
  prestations: Prestation[];
  thisMonthInterventions: InterventionItem[];
  today: string;
}

export interface PrestationKpis {
  activeCount: number;
  archivedCount: number;
  monthRevenueCents: number;
}

export function computePrestationKpis({ prestations, thisMonthInterventions, today }: Input): PrestationKpis {
  const activeCount = prestations.filter((p) => p.archivedAt == null).length;
  const archivedCount = prestations.filter((p) => p.archivedAt != null).length;

  const yyyymm = today.slice(0, 7);
  const monthRevenueCents = thisMonthInterventions
    .filter((i) => i.date.slice(0, 7) === yyyymm)
    .reduce(
      (sum, i) => sum + i.prestations.reduce((s, p) => s + p.qty * p.priceCentsSnapshot, 0),
      0
    );

  return { activeCount, archivedCount, monthRevenueCents };
}
