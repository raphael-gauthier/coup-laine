import { haptics } from '@/ui/motion/haptics';
import { useToastStore } from '@/ui/components/toast';
import i18n from '@/i18n';

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

/**
 * Standard error toast for failed mutations:
 * - Logs the underlying error to console (debuggable later via Sentry/similar).
 * - Surfaces a user-friendly title and a generic retry hint as message.
 *
 * Pass a custom `message` override when the default retry hint isn't right
 * (e.g. expired OTP, missing config — anything where retrying won't help).
 */
export function mutationErrorToast(title: string, err: unknown, message?: string): void {
  console.error(err);
  errorToast(title, message ?? i18n.t('common.errors.retry_hint'));
}
