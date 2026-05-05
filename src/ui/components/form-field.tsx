import type { ReactNode } from 'react';
import { View } from 'react-native';
import { Text } from '@/ui/primitives/text';

interface Props {
  label: string;
  error?: string;
  /**
   * Optional muted helper text rendered between the control and the error
   * message. Useful for usage hints (e.g. "in km").
   */
  hint?: string;
  children: ReactNode;
}

/**
 * Visual wrapper for a labelled form field. Pairs a `<Text>` label with an
 * input control and renders an inline error message when validation fails.
 * An optional `hint` is rendered as muted text between the control and the
 * error. Use with `react-hook-form`'s `<Controller>` (or `RHFTextField`
 * shortcut).
 */
export function FormField({ label, error, hint, children }: Props) {
  return (
    <View className="gap-2">
      <Text className="text-sm font-medium">{label}</Text>
      {children}
      {hint ? (
        <Text variant="muted" className="text-xs">{hint}</Text>
      ) : null}
      {error ? (
        <Text className="text-sm text-danger dark:text-danger-dark">{error}</Text>
      ) : null}
    </View>
  );
}
