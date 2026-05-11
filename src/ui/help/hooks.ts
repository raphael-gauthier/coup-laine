import { useCallback, useEffect, useState } from 'react';
import type { TutorialKey } from '@/domain/tutorial/keys';
import { isEssentialCoachmark } from '@/domain/tutorial/keys';
import {
  useIsTutorialSeen,
  useMarkTutorialSeen,
} from '@/state/queries/tutorial';
import {
  hasDiscoveryFiredThisSession,
  markDiscoveryFired,
} from '@/ui/help/session-store';

export interface HelpSheetController {
  isOpen: boolean;
  open: () => void;
  close: () => void;
  hasBeenSeen: boolean;
}

export function useHelpSheet(key: TutorialKey): HelpSheetController {
  const [isOpen, setIsOpen] = useState(false);
  const hasBeenSeen = useIsTutorialSeen(key);
  const markSeen = useMarkTutorialSeen();

  const open = useCallback(() => {
    setIsOpen(true);
    if (!hasBeenSeen) markSeen.mutate(key);
  }, [hasBeenSeen, key, markSeen]);

  const close = useCallback(() => {
    setIsOpen(false);
  }, []);

  return { isOpen, open, close, hasBeenSeen };
}

export interface CoachMarkController {
  isVisible: boolean;
  dismiss: () => void;
}

export function useCoachMark(
  key: TutorialKey,
  shouldShow: boolean,
): CoachMarkController {
  const [locallyDismissed, setLocallyDismissed] = useState(false);
  const hasBeenSeen = useIsTutorialSeen(key);
  const markSeen = useMarkTutorialSeen();

  const isEssential = isEssentialCoachmark(key);
  const sessionGate = isEssential || !hasDiscoveryFiredThisSession();

  const dismiss = useCallback(() => {
    setLocallyDismissed(true);
    if (!hasBeenSeen) markSeen.mutate(key);
  }, [hasBeenSeen, key, markSeen]);

  const isVisible = shouldShow && !hasBeenSeen && !locallyDismissed && sessionGate;

  // Side-effect: when a discovery coach-mark first becomes visible this
  // session, burn the session token so no other discovery coach-mark fires
  // until the next cold start.
  useEffect(() => {
    if (isVisible && !isEssential) {
      markDiscoveryFired();
    }
  }, [isVisible, isEssential]);

  return { isVisible, dismiss };
}
