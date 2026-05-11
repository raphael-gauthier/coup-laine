import { eq } from 'drizzle-orm';
import { tutorialProgress } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import type { TutorialKey } from '@/domain/tutorial/keys';
import {
  TutorialProgressRowSchema,
  type TutorialProgressRow,
} from '@/domain/models/tutorial-progress';

export class TutorialProgressRepository {
  constructor(private readonly db: Db) {}

  async list(): Promise<TutorialProgressRow[]> {
    const rows = await this.db.select().from(tutorialProgress);
    return rows.map((r) => TutorialProgressRowSchema.parse(r));
  }

  async isSeen(key: TutorialKey): Promise<boolean> {
    const rows = await this.db
      .select({ key: tutorialProgress.key })
      .from(tutorialProgress)
      .where(eq(tutorialProgress.key, key));
    return rows.length > 0;
  }

  async markSeen(key: TutorialKey, now: string): Promise<void> {
    // INSERT OR IGNORE — idempotent, second call leaves seenAt untouched.
    await this.db
      .insert(tutorialProgress)
      .values({ key, seenAt: now })
      .onConflictDoNothing();
  }

  async resetAll(): Promise<void> {
    await this.db.delete(tutorialProgress);
  }
}
