export const TUTORIAL_KEYS = {
  // Phase 1 — sheets
  sheetClients:        'sheet.clients',
  sheetTours:          'sheet.tours',
  sheetCompletion:     'sheet.completion',
  // Phase 1 — coach-marks
  coachmarkFirstClient: 'coachmark.first_client',
  coachmarkFirstTour:   'coachmark.first_tour',
} as const;

export type TutorialKey = typeof TUTORIAL_KEYS[keyof typeof TUTORIAL_KEYS];

const KNOWN_KEYS = new Set<string>(Object.values(TUTORIAL_KEYS));

export function validateTutorialKey(key: string): boolean {
  return KNOWN_KEYS.has(key);
}
