import { and, eq, lt } from 'drizzle-orm';
import { distanceMatrix } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { DistanceMatrixEntry } from '@/domain/models/distance-matrix-entry';

interface DistanceMatrixRow {
  fromId: string;
  toId: string;
  distanceKm: number;
  durationMinutes: number;
  fetchedAt: string;
  failed: number;
}

function toRow(e: DistanceMatrixEntry) {
  return {
    fromId: e.fromId,
    toId: e.toId,
    distanceKm: e.distanceKm,
    durationMinutes: e.durationMinutes,
    fetchedAt: e.fetchedAt,
    failed: e.failed ? 1 : 0,
  };
}

function fromRow(r: DistanceMatrixRow): DistanceMatrixEntry {
  return DistanceMatrixEntry.parse({ ...r, failed: r.failed === 1 });
}

export class DistanceMatrixRepository {
  constructor(private readonly db: Db) {}

  async byPair(fromId: string, toId: string): Promise<DistanceMatrixEntry | null> {
    const rows = await this.db
      .select()
      .from(distanceMatrix)
      .where(and(eq(distanceMatrix.fromId, fromId), eq(distanceMatrix.toId, toId)));
    return rows[0] ? fromRow(rows[0] as DistanceMatrixRow) : null;
  }

  async upsert(entry: DistanceMatrixEntry): Promise<void> {
    const row = toRow(entry);
    await this.db
      .insert(distanceMatrix)
      .values(row)
      .onConflictDoUpdate({
        target: [distanceMatrix.fromId, distanceMatrix.toId],
        set: row,
      });
  }

  async upsertMany(entries: DistanceMatrixEntry[]): Promise<void> {
    for (const e of entries) {
      await this.upsert(e);
    }
  }

  async markFailed(fromId: string, toId: string, fetchedAt: string): Promise<void> {
    await this.upsert({
      fromId,
      toId,
      distanceKm: 0,
      durationMinutes: 0,
      fetchedAt,
      failed: true,
    });
  }

  async listFailed(): Promise<DistanceMatrixEntry[]> {
    const rows = await this.db
      .select()
      .from(distanceMatrix)
      .where(eq(distanceMatrix.failed, 1));
    return rows.map((r) => fromRow(r as DistanceMatrixRow));
  }

  async deleteOlderThan(isoDate: string): Promise<void> {
    await this.db.delete(distanceMatrix).where(lt(distanceMatrix.fetchedAt, isoDate));
  }

  async listAll(): Promise<DistanceMatrixEntry[]> {
    const rows = await this.db.select().from(distanceMatrix);
    return rows.map((r) => fromRow(r as DistanceMatrixRow));
  }
}
