import { haptics } from '@/ui/motion/haptics';
import { useToastStore } from '@/ui/components/toast';

/**
 * Show a transient error toast at the top of the screen.
 * Auto-dismisses after a few seconds; tap to dismiss earlier.
 * Always pairs with a haptic error pulse.
 */
export function errorToast(title: string, message?: string): void {
  void haptics.error();
  useToastStore.getState().push({ title, message, variant: 'error' });
}

/**
 * Show a transient success toast at the top of the screen.
 * Auto-dismisses after a few seconds; tap to dismiss earlier.
 * Always pairs with a haptic success pulse.
 */
export function successToast(title: string, message?: string): void {
  void haptics.success();
  useToastStore.getState().push({ title, message, variant: 'success' });
}
