import { and, eq, isNotNull } from 'drizzle-orm';
import { clients, tourStops, manualHistoryEntries } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { Client } from '@/domain/models/client';

function toRow(c: Client) {
  return {
    id: c.id,
    displayName: c.displayName,
    phones: JSON.stringify(c.phones),
    addressLabel: c.addressLabel,
    addressCity: c.addressCity,
    addressPostcode: c.addressPostcode,
    latitude: c.latitude,
    longitude: c.longitude,
    isWaiting: c.isWaiting ? 1 : 0,
    isBanned: c.isBanned ? 1 : 0,
    needsDistanceRecompute: c.needsDistanceRecompute ? 1 : 0,
    lastShearingDate: c.lastShearingDate,
    animalCounts: JSON.stringify(c.animalCounts),
    markerColorHex: c.markerColorHex,
    anonymizedAt: c.anonymizedAt,
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
  };
}

interface ClientRow {
  id: string;
  displayName: string;
  phones: string;
  addressLabel: string | null;
  addressCity: string | null;
  addressPostcode: string | null;
  latitude: number | null;
  longitude: number | null;
  isWaiting: number;
  isBanned: number;
  needsDistanceRecompute: number;
  lastShearingDate: string | null;
  animalCounts: string;
  markerColorHex: string | null;
  anonymizedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

function fromRow(r: ClientRow): Client {
  return Client.parse({
    ...r,
    phones: JSON.parse(r.phones),
    isWaiting: r.isWaiting === 1,
    isBanned: r.isBanned === 1,
    needsDistanceRecompute: r.needsDistanceRecompute === 1,
    animalCounts: JSON.parse(r.animalCounts),
    anonymizedAt: r.anonymizedAt,
  });
}

export class ClientRepository {
  constructor(private readonly db: Db) {}

  async byId(id: string): Promise<Client | null> {
    const rows = await this.db.select().from(clients).where(eq(clients.id, id));
    return rows[0] ? fromRow(rows[0] as ClientRow) : null;
  }

  async listAll(): Promise<Client[]> {
    const rows = await this.db.select().from(clients);
    return rows.map((r) => fromRow(r as ClientRow));
  }

  async listWaiting(): Promise<Client[]> {
    const rows = await this.db.select().from(clients).where(eq(clients.isWaiting, 1));
    return rows.map((r) => fromRow(r as ClientRow));
  }

  async listWithRecomputePending(): Promise<Client[]> {
    const rows = await this.db
      .select()
      .from(clients)
      .where(eq(clients.needsDistanceRecompute, 1));
    return rows.map((r) => fromRow(r as ClientRow));
  }

  async upsert(c: Client): Promise<void> {
    const row = toRow(c);
    await this.db
      .insert(clients)
      .values(row)
      .onConflictDoUpdate({ target: clients.id, set: row });
  }

  async setWaiting(id: string, isWaiting: boolean, updatedAt: string): Promise<void> {
    await this.db
      .update(clients)
      .set({ isWaiting: isWaiting ? 1 : 0, updatedAt })
      .where(eq(clients.id, id));
  }

  async setBanned(id: string, isBanned: boolean, updatedAt: string): Promise<void> {
    await this.db
      .update(clients)
      .set({ isBanned: isBanned ? 1 : 0, updatedAt })
      .where(eq(clients.id, id));
  }

  async setRecomputePending(id: string, value: boolean, updatedAt: string): Promise<void> {
    await this.db
      .update(clients)
      .set({ needsDistanceRecompute: value ? 1 : 0, updatedAt })
      .where(eq(clients.id, id));
  }

  async delete(id: string): Promise<void> {
    await this.db.delete(clients).where(eq(clients.id, id));
  }

  async listClientIdsWithOutstanding(): Promise<Set<string>> {
    const stopRows = await this.db
      .selectDistinct({ clientId: tourStops.clientId })
      .from(tourStops)
      .where(and(eq(tourStops.isPaid, 0), isNotNull(tourStops.completedAt)));
    const entryRows = await this.db
      .selectDistinct({ clientId: manualHistoryEntries.clientId })
      .from(manualHistoryEntries)
      .where(eq(manualHistoryEntries.isPaid, 0));
    const out = new Set<string>();
    for (const r of stopRows) out.add(r.clientId);
    for (const r of entryRows) out.add(r.clientId);
    return out;
  }
}
