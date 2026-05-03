import { db } from '@/infra/db/client';
import { clients } from '@/infra/db/schema';
import { listBackups } from '@/infra/cloud/backups';

async function hasAnyLocalData(): Promise<boolean> {
  const rows = await db.select().from(clients).limit(1);
  return rows.length > 0;
}

export type FirstSignInResult = 'fresh' | 'choice';

export async function resolveFirstSignIn(userId: string): Promise<FirstSignInResult> {
  const localHasData = await hasAnyLocalData();
  if (localHasData) return 'fresh';

  let backups: Awaited<ReturnType<typeof listBackups>>;
  try {
    backups = await listBackups();
  } catch {
    // If listing fails (network, auth), default to fresh start
    return 'fresh';
  }

  if (backups.length === 0) return 'fresh';

  // Local empty + remote backups exist → let user choose
  void userId; // reserved for future per-user logic
  return 'choice';
}
