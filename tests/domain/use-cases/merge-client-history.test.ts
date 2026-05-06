import { describe, it, expect } from 'vitest';
import { mergeClientHistory } from '@/domain/use-cases/merge-client-history';

describe('mergeClientHistory', () => {
  it('returns empty when no inputs', () => {
    expect(mergeClientHistory({ tourStopsWithDate: [], manualEntries: [] })).toEqual([]);
  });

  it('merges and sorts by date descending', () => {
    const r = mergeClientHistory({
      tourStopsWithDate: [
        { tourId: 't1', stopId: 's1', date: '2026-03-10', services: [], notes: null, travelFeeCents: null },
      ],
      manualEntries: [
        { id: 'h1', date: '2026-04-01', services: [], notes: 'manual', travelFeeCents: null },
        { id: 'h2', date: '2025-12-15', services: [], notes: null, travelFeeCents: null },
      ],
    });
    expect(r.map((i) => i.date)).toEqual(['2026-04-01', '2026-03-10', '2025-12-15']);
    expect(r[0]?.source).toBe('manual');
    expect(r[1]?.source).toBe('tour');
  });

  it('preserves tour metadata in tourId/tourStopId', () => {
    const r = mergeClientHistory({
      tourStopsWithDate: [
        { tourId: 't1', stopId: 's1', date: '2026-03-10', services: [], notes: 'tour-note', travelFeeCents: null },
      ],
      manualEntries: [],
    });
    expect(r[0]?.tourId).toBe('t1');
    expect(r[0]?.tourStopId).toBe('s1');
    expect(r[0]?.manualEntryId).toBeNull();
    expect(r[0]?.notes).toBe('tour-note');
  });

  it('carries travelFeeCents from both sources', () => {
    const result = mergeClientHistory({
      tourStopsWithDate: [
        { tourId: 't1', stopId: 's1', date: '2026-01-01', services: [], notes: null, travelFeeCents: 1500 },
      ],
      manualEntries: [
        { id: 'm1', date: '2026-02-01', services: [], notes: null, travelFeeCents: 800 },
      ],
    });
    expect(result.find((i) => i.source === 'tour')!.travelFeeCents).toBe(1500);
    expect(result.find((i) => i.source === 'manual')!.travelFeeCents).toBe(800);
  });
});
