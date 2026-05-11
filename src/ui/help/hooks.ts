import { useCallback, useState } from 'react';
import type { TutorialKey } from '@/domain/tutorial/keys';
import {
  useIsTutorialSeen,
  useMarkTutorialSeen,
} from '@/state/queries/tutorial';

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

  const dismiss = useCallback(() => {
    setLocallyDismissed(true);
    if (!hasBeenSeen) markSeen.mutate(key);
  }, [hasBeenSeen, key, markSeen]);

  return {
    isVisible: shouldShow && !hasBeenSeen && !locallyDismissed,
    dismiss,
  };
}
