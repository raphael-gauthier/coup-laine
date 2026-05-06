import type { TourStopService } from '@/domain/models/tour-stop-service';

interface InterventionItem {
  date: string;
  services: TourStopService[];
  travelFeeCents: number | null;
}

interface Input {
  tourStops: InterventionItem[];
  manualEntries: InterventionItem[];
  today: string;
}

export interface ClientKpis {
  interventionsCount: number;
  totalRevenueCents: number;
  firstInterventionDate: string | null;
  lastInterventionDate: string | null;
  yearsSinceFirst: number;
}

export function computeClientKpis({ tourStops, manualEntries, today }: Input): ClientKpis {
  const all = [...tourStops, ...manualEntries];
  if (all.length === 0) {
    return {
      interventionsCount: 0,
      totalRevenueCents: 0,
      firstInterventionDate: null,
      lastInterventionDate: null,
      yearsSinceFirst: 0,
    };
  }
  const totalRevenueCents = all.reduce(
    (sum, item) =>
      sum +
      item.services.reduce((s, p) => s + p.qty * p.priceCentsSnapshot, 0) +
      (item.travelFeeCents ?? 0),
    0
  );
  const sortedDates = all.map((i) => i.date).sort();
  const firstDate = sortedDates[0]!;
  const lastDate = sortedDates[sortedDates.length - 1]!;

  const firstYear = parseInt(firstDate.slice(0, 4), 10);
  const todayYear = parseInt(today.slice(0, 4), 10);
  const fullYears = (() => {
    const diff = todayYear - firstYear;
    if (today.slice(5) < firstDate.slice(5)) return Math.max(0, diff - 1);
    return diff;
  })();

  return {
    interventionsCount: all.length,
    totalRevenueCents,
    firstInterventionDate: firstDate,
    lastInterventionDate: lastDate,
    yearsSinceFirst: fullYears,
  };
}
