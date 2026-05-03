import type { Intervention } from '@/domain/models/intervention';
import type { TourStopPrestation } from '@/domain/models/tour-stop-prestation';

interface TourStopHistoryItem {
  tourId: string;
  stopId: string;
  date: string;
  prestations: TourStopPrestation[];
  notes: string | null;
}

interface ManualHistoryItem {
  id: string;
  date: string;
  prestations: TourStopPrestation[];
  notes: string | null;
}

interface Input {
  tourStopsWithDate: TourStopHistoryItem[];
  manualEntries: ManualHistoryItem[];
}

export function mergeClientHistory({ tourStopsWithDate, manualEntries }: Input): Intervention[] {
  const fromTours: Intervention[] = tourStopsWithDate.map((t) => ({
    source: 'tour',
    date: t.date,
    prestations: t.prestations,
    notes: t.notes,
    tourId: t.tourId,
    tourStopId: t.stopId,
    manualEntryId: null,
  }));
  const fromManual: Intervention[] = manualEntries.map((m) => ({
    source: 'manual',
    date: m.date,
    prestations: m.prestations,
    notes: m.notes,
    tourId: null,
    tourStopId: null,
    manualEntryId: m.id,
  }));
  return [...fromTours, ...fromManual].sort((a, b) => b.date.localeCompare(a.date));
}
