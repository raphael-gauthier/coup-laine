export type ClientStatus = 'default' | 'waiting' | 'scheduled' | 'done' | 'noAnimals' | 'banned';

interface Input {
  isBanned: boolean;
  isWaiting: boolean;
  animalsTotal: number;
  /** ISO date 'YYYY-MM-DD' — start of the current shearing season. */
  seasonStartedAt: string;
  /** All `completedAt` dates of stops where this client was a stop, ISO 'YYYY-MM-DD' (or any string ≥-comparable). */
  completedTourDates: string[];
  /** All scheduled dates of planned tours containing this client, ISO 'YYYY-MM-DD'. */
  plannedTourDates: string[];
}

export function computeClientStatus(input: Input): ClientStatus {
  const { isBanned, isWaiting, animalsTotal, seasonStartedAt, completedTourDates, plannedTourDates } = input;
  if (isBanned) return 'banned';
  if (animalsTotal === 0) return 'noAnimals';
  if (completedTourDates.some((d) => d >= seasonStartedAt)) return 'done';
  if (plannedTourDates.some((d) => d >= seasonStartedAt)) return 'scheduled';
  if (isWaiting) return 'waiting';
  return 'default';
}
