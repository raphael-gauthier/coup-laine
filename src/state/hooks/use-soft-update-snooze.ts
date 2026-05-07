import { useCallback, useEffect, useState } from 'react';
import * as SecureStore from 'expo-secure-store';

const KEY = 'version-gate.snoozed';
const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

type Snooze = { version: string; until: number };

async function readSnooze(): Promise<Snooze | null> {
  const raw = await SecureStore.getItemAsync(KEY);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as Snooze;
    if (typeof parsed?.version !== 'string' || typeof parsed?.until !== 'number') return null;
    return parsed;
  } catch {
    return null;
  }
}

export function useSoftUpdateSnooze() {
  const [snooze, setSnoozeState] = useState<Snooze | null>(null);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    void readSnooze().then((s) => {
      setSnoozeState(s);
      setLoaded(true);
    });
  }, []);

  const snoozeFor = useCallback(async (latestVersion: string) => {
    const next: Snooze = { version: latestVersion, until: Date.now() + SEVEN_DAYS_MS };
    await SecureStore.setItemAsync(KEY, JSON.stringify(next));
    setSnoozeState(next);
  }, []);

  const isSnoozed = useCallback(
    (latestVersion: string) => {
      if (!snooze) return false;
      if (snooze.version !== latestVersion) return false;
      return Date.now() < snooze.until;
    },
    [snooze],
  );

  return { loaded, isSnoozed, snoozeFor };
}
