import { useEffect, useRef } from 'react';
import { AppState, type AppStateStatus } from 'react-native';
import { useQueryClient } from '@tanstack/react-query';
import { createBackup, listBackups, type BackupFile } from '@/infra/cloud/backups';
import { backupsKeys } from '@/state/queries/backups';
import { authKeys } from '@/state/queries/auth';
import type { Session } from '@supabase/supabase-js';

const TWENTY_FOUR_HOURS_MS = 24 * 60 * 60 * 1000;

export function shouldRunAutoBackup(params: {
  now: Date;
  signedIn: boolean;
  lastBackupAt: Date | null;
}): boolean {
  if (!params.signedIn) return false;
  if (!params.lastBackupAt) return true;
  return params.now.getTime() - params.lastBackupAt.getTime() >= TWENTY_FOUR_HOURS_MS;
}

/**
 * Mirrors the Flutter BackupScheduler: when the app comes to foreground,
 * run an automatic backup if the user has linked their account (non-anonymous)
 * and the last backup is older than 24h. Best-effort: failures are swallowed.
 */
export function useAutoBackup(): void {
  const qc = useQueryClient();
  const inFlight = useRef(false);

  useEffect(() => {
    const tick = async () => {
      if (inFlight.current) return;
      inFlight.current = true;
      try {
        const session = qc.getQueryData<Session | null>(authKeys.session);
        const signedIn = !!session && !session.user.is_anonymous;
        if (!signedIn) return;

        const cached = qc.getQueryData<BackupFile[]>(backupsKeys.list);
        const list = cached ?? (await listBackups());
        const lastIso = list[0]?.createdAt;
        const lastBackupAt = lastIso ? new Date(lastIso) : null;

        if (!shouldRunAutoBackup({ now: new Date(), signedIn, lastBackupAt })) return;

        await createBackup();
        await qc.invalidateQueries({ queryKey: backupsKeys.list });
      } catch {
        /* best-effort */
      } finally {
        inFlight.current = false;
      }
    };

    void tick();

    const sub = AppState.addEventListener('change', (state: AppStateStatus) => {
      if (state === 'active') void tick();
    });
    return () => sub.remove();
  }, [qc]);
}
