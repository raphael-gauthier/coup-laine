import type { Intervention } from '@/domain/models/intervention';
import type { TourStopService } from '@/domain/models/tour-stop-service';

interface TourStopHistoryItem {
  tourId: string;
  stopId: string;
  date: string;
  services: TourStopService[];
  notes: string | null;
  travelFeeCents: number | null;
}

interface ManualHistoryItem {
  id: string;
  date: string;
  services: TourStopService[];
  notes: string | null;
  travelFeeCents: number | null;
}

interface Input {
  tourStopsWithDate: TourStopHistoryItem[];
  manualEntries: ManualHistoryItem[];
}

export function mergeClientHistory({ tourStopsWithDate, manualEntries }: Input): Intervention[] {
  const fromTours: Intervention[] = tourStopsWithDate.map((t) => ({
    source: 'tour',
    date: t.date,
    services: t.services,
    travelFeeCents: t.travelFeeCents,
    notes: t.notes,
    tourId: t.tourId,
    tourStopId: t.stopId,
    manualEntryId: null,
  }));
  const fromManual: Intervention[] = manualEntries.map((m) => ({
    source: 'manual',
    date: m.date,
    services: m.services,
    travelFeeCents: m.travelFeeCents,
    notes: m.notes,
    tourId: null,
    tourStopId: null,
    manualEntryId: m.id,
  }));
  return [...fromTours, ...fromManual].sort((a, b) => b.date.localeCompare(a.date));
}
