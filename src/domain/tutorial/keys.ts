export const TUTORIAL_KEYS = {
  // Phase 1 — sheets
  sheetClients:        'sheet.clients',
  sheetTours:          'sheet.tours',
  sheetCompletion:     'sheet.completion',
  // Phase 1 — coach-marks (essential)
  coachmarkFirstClient: 'coachmark.first_client',
  coachmarkFirstTour:   'coachmark.first_tour',

  // Phase 2 — sheets
  sheetMap:                'sheet.map',
  sheetClientDetail:       'sheet.client_detail',
  sheetTourDetail:         'sheet.tour_detail',
  sheetServicesCatalog:    'sheet.services_catalog',
  sheetStatuses:           'sheet.statuses',
  sheetCloud:              'sheet.cloud',
  sheetSettings:           'sheet.settings',
  // Phase 2 — coach-marks (discovery)
  coachmarkCloudBackup:           'coachmark.cloud_backup',
  coachmarkDiscoverCatalog:       'coachmark.discover_catalog',
  coachmarkManualStatuses:        'coachmark.manual_statuses',
  coachmarkProximitySuggestions:  'coachmark.proximity_suggestions',
  coachmarkPaymentMethods:        'coachmark.payment_methods',
} as const;

export type TutorialKey = typeof TUTORIAL_KEYS[keyof typeof TUTORIAL_KEYS];

const KNOWN_KEYS = new Set<string>(Object.values(TUTORIAL_KEYS));

export function validateTutorialKey(key: string): boolean {
  return KNOWN_KEYS.has(key);
}

const ESSENTIAL_COACHMARKS = new Set<TutorialKey>([
  TUTORIAL_KEYS.coachmarkFirstClient,
  TUTORIAL_KEYS.coachmarkFirstTour,
]);

export function isEssentialCoachmark(key: TutorialKey): boolean {
  return ESSENTIAL_COACHMARKS.has(key);
}
