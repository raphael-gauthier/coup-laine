export type ClientStatus = 'waiting' | 'shorn-recent' | 'shorn-old' | 'never';

interface Input {
  isWaiting: boolean;
  lastShearingDate: string | null;
  today: string;
  recentDays?: number;
}

export function computeClientStatus({
  isWaiting,
  lastShearingDate,
  today,
  recentDays = 60,
}: Input): ClientStatus {
  if (isWaiting) return 'waiting';
  if (!lastShearingDate) return 'never';

  const last = Date.parse(lastShearingDate);
  const now = Date.parse(today);
  const daysAgo = (now - last) / (1000 * 60 * 60 * 24);
  return daysAgo <= recentDays ? 'shorn-recent' : 'shorn-old';
}
