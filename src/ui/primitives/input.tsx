import { TextInput, useColorScheme, type TextInputProps } from 'react-native';
import { cn } from '@/lib/cn';

interface Props extends Omit<TextInputProps, 'accessibilityLabel'> {
  className?: string;
  // Required at the type level so screen readers always announce a meaningful
  // field name, even when a visible <Text> label is rendered alongside.
  accessibilityLabel: string;
}

export function Input({ className, style, ...rest }: Props) {
  const isDark = useColorScheme() === 'dark';
  return (
    <TextInput
      placeholderTextColor={isDark ? '#B4A490' : '#5C4E40'}
      className={cn(
        'rounded-2xl border border-border dark:border-border-dark',
        'bg-input dark:bg-input-dark',
        'px-4 py-3 text-foreground dark:text-foreground-dark',
        className
      )}
      style={[{ fontSize: 16 }, style]}
      {...rest}
    />
  );
}
