import { describe, it, expect, vi } from 'vitest';
import { proposeOptimizedTour } from '@/domain/use-cases/propose-optimized-tour';
import type { MatrixCoord } from '@/infra/services/ors-routing';

function makeMatrix(entries: Array<[string, string, number]>) {
  const m = new Map<string, { distanceKm: number; durationMinutes: number; isEstimate: boolean }>();
  for (const [from, to, km] of entries) {
    m.set(`${from}-${to}`, { distanceKm: km, durationMinutes: km, isEstimate: false });
  }
  return m;
}

describe('proposeOptimizedTour', () => {
  const baseCoord = { lat: 48.0, lon: 2.0 };
  const candidates = [
    { id: 'A', lat: 48.1, lon: 2.0 },
    { id: 'B', lat: 48.2, lon: 2.0 },
  ];

  it('passes BASE as the first coord to resolveMatrix', async () => {
    const resolveMatrix = vi.fn(async (_coords: MatrixCoord[]) => ({
      matrix: makeMatrix([
        ['BASE', 'A', 1], ['BASE', 'B', 2],
        ['A', 'BASE', 1], ['A', 'B', 1],
        ['B', 'BASE', 2], ['B', 'A', 1],
      ]),
      source: 'cache' as const,
    }));

    await proposeOptimizedTour({ baseCoord, candidates, resolveMatrix });

    const [coordsArg] = resolveMatrix.mock.calls[0]!;
    expect(coordsArg[0]).toEqual({ id: 'BASE', lat: 48.0, lon: 2.0 });
    expect(coordsArg.slice(1)).toEqual([
      { id: 'A', lat: 48.1, lon: 2.0 },
      { id: 'B', lat: 48.2, lon: 2.0 },
    ]);
  });

  it('returns an ordered list of candidate ids', async () => {
    const resolveMatrix = vi.fn(async () => ({
      matrix: makeMatrix([
        ['BASE', 'A', 1], ['BASE', 'B', 5],
        ['A', 'BASE', 1], ['A', 'B', 4],
        ['B', 'BASE', 5], ['B', 'A', 4],
      ]),
      source: 'cache' as const,
    }));

    const { orderedIds } = await proposeOptimizedTour({ baseCoord, candidates, resolveMatrix });

    // Greedy starting at BASE picks A first (1 km < 5 km), then B.
    expect(orderedIds).toEqual(['A', 'B']);
  });

  it('propagates errors from resolveMatrix', async () => {
    const resolveMatrix = vi.fn(async () => {
      throw new Error('boom');
    });

    await expect(
      proposeOptimizedTour({ baseCoord, candidates, resolveMatrix }),
    ).rejects.toThrow('boom');
  });

  it('does not crash when matrix is missing some pairs', async () => {
    const resolveMatrix = vi.fn(async () => ({
      matrix: makeMatrix([['BASE', 'A', 1]]), // intentionally incomplete
      source: 'haversine' as const,
    }));

    const { orderedIds } = await proposeOptimizedTour({ baseCoord, candidates, resolveMatrix });
    // Missing pairs default to 0 — optimizer still returns both ids in some order.
    expect(orderedIds).toHaveLength(2);
    expect(new Set(orderedIds)).toEqual(new Set(['A', 'B']));
  });
});
