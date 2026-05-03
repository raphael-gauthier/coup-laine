import { Alert } from 'react-native';
import { haptics } from '@/ui/motion/haptics';

/**
 * Show a transient error to the user. For now wraps `Alert.alert` for
 * zero-fuss reliability; a designed toast/snackbar primitive can replace
 * this in J12 polish without changing call sites.
 *
 * Always pair with a haptic error pulse so the feedback is multi-modal.
 */
export function errorToast(title: string, message?: string): void {
  void haptics.error();
  Alert.alert(title, message);
}
