import { eq } from 'drizzle-orm';
import { settings } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';

export class SettingsRepository {
  constructor(private readonly db: Db) {}

  async get(key: string): Promise<string | null> {
    const rows = await this.db.select().from(settings).where(eq(settings.key, key));
    return rows[0]?.value ?? null;
  }

  async set(key: string, value: string): Promise<void> {
    await this.db
      .insert(settings)
      .values({ key, value })
      .onConflictDoUpdate({ target: settings.key, set: { value } });
  }

  async remove(key: string): Promise<void> {
    await this.db.delete(settings).where(eq(settings.key, key));
  }

  async getAll(): Promise<Record<string, string>> {
    const rows = await this.db.select().from(settings);
    const out: Record<string, string> = {};
    for (const r of rows) out[r.key] = r.value;
    return out;
  }
}
