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
}

function fromRow(r: DistanceMatrixRow): DistanceMatrixEntry {
  return DistanceMatrixEntry.parse(r);
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
    await this.db
      .insert(distanceMatrix)
      .values(entry)
      .onConflictDoUpdate({
        target: [distanceMatrix.fromId, distanceMatrix.toId],
        set: entry,
      });
  }

  async upsertMany(entries: DistanceMatrixEntry[]): Promise<void> {
    for (const e of entries) {
      await this.upsert(e);
    }
  }

  async deleteOlderThan(isoDate: string): Promise<void> {
    await this.db.delete(distanceMatrix).where(lt(distanceMatrix.fetchedAt, isoDate));
  }

  async listAll(): Promise<DistanceMatrixEntry[]> {
    const rows = await this.db.select().from(distanceMatrix);
    return rows.map((r) => fromRow(r as DistanceMatrixRow));
  }
}
