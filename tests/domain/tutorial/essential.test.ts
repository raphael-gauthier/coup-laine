import { describe, it, expect } from 'vitest';
import { TUTORIAL_KEYS, isEssentialCoachmark } from '@/domain/tutorial/keys';

describe('isEssentialCoachmark', () => {
  it('returns true for the 2 essential Phase 1 coach-marks', () => {
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkFirstClient)).toBe(true);
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkFirstTour)).toBe(true);
  });

  it('returns false for the 5 Phase 2 discovery coach-marks', () => {
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkCloudBackup)).toBe(false);
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkDiscoverCatalog)).toBe(false);
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkManualStatuses)).toBe(false);
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkProximitySuggestions)).toBe(false);
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkPaymentMethods)).toBe(false);
  });

  it('returns false for sheet keys (sanity — sheets are never coach-marks)', () => {
    expect(isEssentialCoachmark(TUTORIAL_KEYS.sheetClients)).toBe(false);
    expect(isEssentialCoachmark(TUTORIAL_KEYS.sheetMap)).toBe(false);
  });
});
