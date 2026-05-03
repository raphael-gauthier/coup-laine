import type { Db } from '@/infra/db/client';
import { ClientRepository } from '@/data/repositories/client-repository';
import { DistanceMatrixRepository } from '@/data/repositories/distance-matrix-repository';
import { SettingsRepository } from '@/data/repositories/settings-repository';
import { fetchPairFromBase } from '@/infra/services/ors-routing';

export class DistanceMatrixSync {
  private clients: ClientRepository;
  private matrix: DistanceMatrixRepository;
  private settings: SettingsRepository;

  constructor(db: Db) {
    this.clients = new ClientRepository(db);
    this.matrix = new DistanceMatrixRepository(db);
    this.settings = new SettingsRepository(db);
  }

  /**
   * Recompute the BASE↔client pair for a single client.
   * Marks the client as recompute-pending if the fetch fails;
   * clears the flag and writes both rows on success.
   */
  async recomputeForClient(clientId: string): Promise<{ ok: boolean; reason?: string }> {
    const client = await this.clients.byId(clientId);
    if (!client) return { ok: false, reason: 'client not found' };
    if (client.latitude == null || client.longitude == null) {
      return { ok: false, reason: 'client has no coordinates' };
    }
    const baseLat = await this.settings.get('base_lat');
    const baseLng = await this.settings.get('base_lng');
    if (!baseLat || !baseLng) return { ok: false, reason: 'no base configured' };
    const base = { lat: parseFloat(baseLat), lon: parseFloat(baseLng) };
    const now = new Date().toISOString();

    try {
      const { forward, reverse } = await fetchPairFromBase(base, {
        lat: client.latitude,
        lon: client.longitude,
      });
      await this.matrix.upsert({
        fromId: 'BASE',
        toId: clientId,
        distanceKm: forward.distanceKm,
        durationMinutes: forward.durationMinutes,
        fetchedAt: now,
        failed: false,
      });
      await this.matrix.upsert({
        fromId: clientId,
        toId: 'BASE',
        distanceKm: reverse.distanceKm,
        durationMinutes: reverse.durationMinutes,
        fetchedAt: now,
        failed: false,
      });
      await this.clients.setRecomputePending(clientId, false, now);
      return { ok: true };
    } catch (err) {
      await this.matrix.markFailed('BASE', clientId, now);
      await this.matrix.markFailed(clientId, 'BASE', now);
      // Keep flag set so the banner stays
      await this.clients.setRecomputePending(clientId, true, now);
      return { ok: false, reason: err instanceof Error ? err.message : 'unknown' };
    }
  }

  /**
   * Recompute BASE↔client pairs for ALL geocoded clients.
   * Used after the base address changes.
   * Returns counts; doesn't throw on individual failures.
   */
  async recomputeAllForBase(): Promise<{ ok: number; failed: number; skipped: number }> {
    const allClients = await this.clients.listAll();
    let ok = 0;
    let failed = 0;
    let skipped = 0;
    for (const c of allClients) {
      if (c.latitude == null || c.longitude == null) {
        skipped++;
        continue;
      }
      const result = await this.recomputeForClient(c.id);
      if (result.ok) ok++;
      else failed++;
    }
    return { ok, failed, skipped };
  }

  /**
   * Mark every geocoded client as recompute-pending without fetching.
   * Used when the base changes — the user can then trigger the recompute
   * from the banner CTA, avoiding a long blocking call.
   */
  async markAllPending(): Promise<number> {
    const allClients = await this.clients.listAll();
    const now = new Date().toISOString();
    let count = 0;
    for (const c of allClients) {
      if (c.latitude == null || c.longitude == null) continue;
      await this.clients.setRecomputePending(c.id, true, now);
      count++;
    }
    return count;
  }
}
