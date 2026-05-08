import { and, eq, isNotNull, isNull, or } from 'drizzle-orm';
import { clients, tourStops, manualHistoryEntries, distanceMatrix } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { Client } from '@/domain/models/client';
import { planAnonymization } from '@/domain/use-cases/anonymize-client';

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
    manualStatusId: c.manualStatusId,
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
  manualStatusId: string | null;
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
    manualStatusId: r.manualStatusId,
  });
}

export class ClientRepository {
  constructor(private readonly db: Db) {}

  async byId(id: string): Promise<Client | null> {
    const rows = await this.db.select().from(clients).where(eq(clients.id, id));
    return rows[0] ? fromRow(rows[0] as ClientRow) : null;
  }

  async listAll(): Promise<Client[]> {
    const rows = await this.db.select().from(clients).where(isNull(clients.anonymizedAt));
    return rows.map((r) => fromRow(r as ClientRow));
  }

  async listWaiting(): Promise<Client[]> {
    const rows = await this.db
      .select()
      .from(clients)
      .where(and(eq(clients.isWaiting, 1), isNull(clients.anonymizedAt)));
    return rows.map((r) => fromRow(r as ClientRow));
  }

  async listWithRecomputePending(): Promise<Client[]> {
    const rows = await this.db
      .select()
      .from(clients)
      .where(and(eq(clients.needsDistanceRecompute, 1), isNull(clients.anonymizedAt)));
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

  async setManualStatus(id: string, statusId: string | null, updatedAt: string): Promise<void> {
    await this.db
      .update(clients)
      .set({ manualStatusId: statusId, updatedAt })
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

  async anonymize(id: string, now: string): Promise<void> {
    // Operations are NOT wrapped in a transaction: drizzle's transaction() expects
    // a sync callback with the better-sqlite3 driver, but our updates are awaited
    // reads + writes. Crash-resilience instead relies on operation order: related
    // rows are scrubbed first, then the client UPDATE stamps anonymizedAt last.
    // On retry, the use case returns a no-op plan if anonymizedAt is already set,
    // so re-running anonymize() is safe regardless of where a previous call crashed.
    const clientRows = await this.db.select().from(clients).where(eq(clients.id, id));
    if (!clientRows[0]) return;
    const client = fromRow(clientRows[0] as ClientRow);

    const stopRows = await this.db.select().from(tourStops).where(eq(tourStops.clientId, id));
    const entryRows = await this.db.select().from(manualHistoryEntries).where(eq(manualHistoryEntries.clientId, id));
    const dmRows = await this.db.select().from(distanceMatrix)
      .where(or(eq(distanceMatrix.fromId, id), eq(distanceMatrix.toId, id)));

    const stops = stopRows.map((r) => ({ id: r.id, clientId: r.clientId }));
    const entries = entryRows.map((r) => ({ id: r.id, clientId: r.clientId }));
    const dm = dmRows.map((r) => ({ fromId: r.fromId, toId: r.toId }));

    const plan = planAnonymization(client, stops, entries, dm, now);

    for (const upd of plan.tourStopUpdates) {
      await this.db.update(tourStops)
        .set({ clientNameSnapshot: upd.clientNameSnapshot, notes: upd.notes })
        .where(eq(tourStops.id, upd.id));
    }
    for (const upd of plan.manualEntryUpdates) {
      await this.db.update(manualHistoryEntries)
        .set({ notes: upd.notes })
        .where(eq(manualHistoryEntries.id, upd.id));
    }
    for (const del of plan.distanceMatrixDeletes) {
      await this.db.delete(distanceMatrix)
        .where(and(eq(distanceMatrix.fromId, del.fromId), eq(distanceMatrix.toId, del.toId)));
    }

    if (Object.keys(plan.client.updates).length > 0) {
      const u = plan.client.updates;
      const updates: Record<string, unknown> = {};
      if (u.displayName !== undefined) updates.displayName = u.displayName;
      if (u.phones !== undefined) updates.phones = JSON.stringify(u.phones);
      if (u.addressLabel !== undefined) updates.addressLabel = u.addressLabel;
      if (u.addressCity !== undefined) updates.addressCity = u.addressCity;
      if (u.addressPostcode !== undefined) updates.addressPostcode = u.addressPostcode;
      if (u.latitude !== undefined) updates.latitude = u.latitude;
      if (u.longitude !== undefined) updates.longitude = u.longitude;
      if (u.animalCounts !== undefined) updates.animalCounts = JSON.stringify(u.animalCounts);
      if (u.isWaiting !== undefined) updates.isWaiting = u.isWaiting ? 1 : 0;
      if (u.isBanned !== undefined) updates.isBanned = u.isBanned ? 1 : 0;
      if (u.needsDistanceRecompute !== undefined) updates.needsDistanceRecompute = u.needsDistanceRecompute ? 1 : 0;
      if (u.anonymizedAt !== undefined) updates.anonymizedAt = u.anonymizedAt;
      if (u.manualStatusId !== undefined) updates.manualStatusId = u.manualStatusId;
      updates.updatedAt = now;
      await this.db.update(clients).set(updates).where(eq(clients.id, id));
    }
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
