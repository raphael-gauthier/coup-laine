import { eq } from 'drizzle-orm';
import { clients } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { Client } from '@/domain/models/client';

function toRow(c: Client) {
  return {
    id: c.id,
    displayName: c.displayName,
    firstName: c.firstName,
    lastName: c.lastName,
    phones: JSON.stringify(c.phones),
    email: c.email,
    addressLabel: c.addressLabel,
    addressCity: c.addressCity,
    addressPostcode: c.addressPostcode,
    latitude: c.latitude,
    longitude: c.longitude,
    isWaiting: c.isWaiting ? 1 : 0,
    notes: c.notes,
    lastShearingDate: c.lastShearingDate,
    animalCounts: JSON.stringify(c.animalCounts),
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
  };
}

interface ClientRow {
  id: string;
  displayName: string;
  firstName: string | null;
  lastName: string | null;
  phones: string;
  email: string | null;
  addressLabel: string | null;
  addressCity: string | null;
  addressPostcode: string | null;
  latitude: number | null;
  longitude: number | null;
  isWaiting: number;
  notes: string | null;
  lastShearingDate: string | null;
  animalCounts: string;
  createdAt: string;
  updatedAt: string;
}

function fromRow(r: ClientRow): Client {
  return Client.parse({
    ...r,
    phones: JSON.parse(r.phones),
    isWaiting: r.isWaiting === 1,
    animalCounts: JSON.parse(r.animalCounts),
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

  async delete(id: string): Promise<void> {
    await this.db.delete(clients).where(eq(clients.id, id));
  }
}
